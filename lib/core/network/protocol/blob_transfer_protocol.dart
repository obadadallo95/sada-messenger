import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../utils/log_service.dart';

/// Chunk size: 64 KB — small enough to survive mid-transfer peer disconnects.
const int kBlobChunkSize = 64 * 1024;

/// 1-byte sub-type prefix inside a binary (0x01) frame.
/// 0x10 = chunk data; 0x11 = chunk ACK.
const int kSubTypeChunk = 0x10;
const int kSubTypeChunkAck = 0x11;

/// Represents a single chunk of a larger binary file being relayed over mesh.
class BlobChunk {
  /// Shared identifier for all chunks of the same file transfer.
  final String groupId;

  /// Zero-based index of this chunk.
  final int chunkIndex;

  /// Total expected chunk count for this transfer.
  final int totalChunks;

  /// MIME type hint (e.g. "audio/ogg").
  final String mimeType;

  /// Raw payload bytes for this chunk.
  final Uint8List data;

  const BlobChunk({
    required this.groupId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.mimeType,
    required this.data,
  });

  // ------------------------------------------------------------------
  // Serialisation: [1-byte sub-type][header JSON length 4B][header JSON][data]
  // ------------------------------------------------------------------

  Uint8List toBytes() {
    final header = jsonEncode({
      'gid': groupId,
      'idx': chunkIndex,
      'total': totalChunks,
      'mime': mimeType,
    });
    final headerBytes = utf8.encode(header);
    final buf = ByteData(1 + 4 + headerBytes.length + data.length);
    int offset = 0;

    buf.setUint8(offset, kSubTypeChunk); offset += 1;
    buf.setUint32(offset, headerBytes.length, Endian.big); offset += 4;
    for (int i = 0; i < headerBytes.length; i++) {
      buf.setUint8(offset + i, headerBytes[i]);
    }
    offset += headerBytes.length;
    for (int i = 0; i < data.length; i++) {
      buf.setUint8(offset + i, data[i]);
    }
    return buf.buffer.asUint8List();
  }

  static BlobChunk? fromBytes(Uint8List bytes) {
    try {
      if (bytes.isEmpty || bytes[0] != kSubTypeChunk) return null;
      final bd = ByteData.sublistView(bytes);
      final headerLen = bd.getUint32(1, Endian.big);
      final headerJson = utf8.decode(bytes.sublist(5, 5 + headerLen));
      final hdr = jsonDecode(headerJson) as Map<String, dynamic>;
      final dataStart = 5 + headerLen;
      return BlobChunk(
        groupId: hdr['gid'] as String,
        chunkIndex: hdr['idx'] as int,
        totalChunks: hdr['total'] as int,
        mimeType: hdr['mime'] as String,
        data: bytes.sublist(dataStart),
      );
    } catch (e) {
      LogService.warning('BlobChunk.fromBytes: parse error: $e');
      return null;
    }
  }
}

/// Splits [fileBytes] into a list of [BlobChunk]s ready for mesh transport.
List<BlobChunk> splitIntoChunks({
  required Uint8List fileBytes,
  required String mimeType,
  String? groupId,
}) {
  final gid = groupId ?? const Uuid().v4();
  final total = (fileBytes.length / kBlobChunkSize).ceil();
  final chunks = <BlobChunk>[];

  for (int i = 0; i < total; i++) {
    final start = i * kBlobChunkSize;
    final end = (start + kBlobChunkSize).clamp(0, fileBytes.length);
    chunks.add(BlobChunk(
      groupId: gid,
      chunkIndex: i,
      totalChunks: total,
      mimeType: mimeType,
      data: fileBytes.sublist(start, end),
    ));
  }
  LogService.info('🔪 Split ${fileBytes.length}B into $total chunks (gid=$gid)');
  return chunks;
}

/// Reassembly buffer: collects chunks and returns the complete file once done.
class BlobReassembler {
  final String groupId;
  final int totalChunks;
  final String mimeType;
  final List<BlobChunk?> _slots;
  DateTime lastUpdated;

  BlobReassembler({
    required this.groupId,
    required this.totalChunks,
    required this.mimeType,
  })  : _slots = List.filled(totalChunks, null),
        lastUpdated = DateTime.now();

  bool addChunk(BlobChunk chunk) {
    if (chunk.groupId != groupId) return false;
    _slots[chunk.chunkIndex] = chunk;
    lastUpdated = DateTime.now();
    return true;
  }

  bool get isComplete => _slots.every((s) => s != null);

  int get receivedCount => _slots.where((s) => s != null).length;

  int get currentSizeBytes =>
      _slots.fold<int>(0, (acc, s) => acc + (s?.data.length ?? 0));

  /// Reassembles the complete file from ordered slots.
  Uint8List assemble() {
    assert(isComplete, 'Cannot assemble: missing chunks');
    final totalLen = _slots.fold<int>(0, (acc, s) => acc + s!.data.length);
    final out = Uint8List(totalLen);
    int offset = 0;
    for (final slot in _slots) {
      out.setRange(offset, offset + slot!.data.length, slot.data);
      offset += slot.data.length;
    }
    LogService.info('✅ Reassembled $totalLen bytes from $totalChunks chunks (gid=$groupId)');
    return out;
  }
}

/// Registry of in-progress reassembly sessions.
class BlobReassemblyManager {
  static const int kMaxConcurrentSessions = 5;
  static const int kMaxTotalMemoryBytes = 50 * 1024 * 1024; // 50 MB
  static const Duration kSessionTimeout = Duration(seconds: 30);
  static const int kMaxChunksPerFile = 2000; // ~128MB at 64KB/chunk

  final Map<String, BlobReassembler> _active = {};

  /// Processes an incoming [BlobChunk]. Returns the complete [Uint8List] when
  /// all chunks have arrived; otherwise returns `null`.
  Uint8List? receive(BlobChunk chunk) {
    // 1. Validation to prevent allocation attacks
    if (chunk.totalChunks > kMaxChunksPerFile) {
      LogService.warning(
        'BlobChunk: totalChunks ${chunk.totalChunks} exceeds limit $kMaxChunksPerFile',
      );
      return null;
    }

    // 2. Prune old sessions to free up space
    pruneStale(timeout: kSessionTimeout);

    // 3. Check session limits if this is a new session
    if (!_active.containsKey(chunk.groupId)) {
      if (_active.length >= kMaxConcurrentSessions) {
        LogService.warning(
          'BlobReassemblyManager: Max concurrent sessions reached ($kMaxConcurrentSessions). Dropping chunk.',
        );
        return null;
      }

      // Check total memory usage across all active sessions
      final currentTotal = _totalMemoryUsage();
      if (currentTotal > kMaxTotalMemoryBytes) {
        LogService.warning(
          'BlobReassemblyManager: Max memory usage reached ($currentTotal > $kMaxTotalMemoryBytes). Dropping chunk.',
        );
        return null;
      }
    }

    _active.putIfAbsent(
      chunk.groupId,
      () => BlobReassembler(
        groupId: chunk.groupId,
        totalChunks: chunk.totalChunks,
        mimeType: chunk.mimeType,
      ),
    );
    final buf = _active[chunk.groupId]!;
    buf.addChunk(chunk);
    LogService.info(
      '📦 Chunk ${chunk.chunkIndex + 1}/${chunk.totalChunks} received '
      '(gid=${chunk.groupId}, ${buf.receivedCount} / ${chunk.totalChunks})',
    );
    if (buf.isComplete) {
      final data = buf.assemble();
      _active.remove(chunk.groupId);
      return data;
    }
    return null;
  }

  String? mimeTypeFor(String groupId) => _active[groupId]?.mimeType;

  void prune() => _active.clear();

  void pruneStale({Duration timeout = const Duration(minutes: 5)}) {
    final now = DateTime.now();
    final initialCount = _active.length;
    _active.removeWhere(
      (key, value) => now.difference(value.lastUpdated) > timeout,
    );
    if (_active.length < initialCount) {
      LogService.info(
        '🧹 Pruned ${initialCount - _active.length} stale blob sessions',
      );
    }
  }

  int _totalMemoryUsage() =>
      _active.values.fold(0, (sum, buf) => sum + buf.currentSizeBytes);
}
