import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../utils/log_service.dart';

/// Manages storage of voice (and generic binary) files received over the mesh.
///
/// Files are stored under `<appDocDir>/mesh_files/<groupId>.<ext>`.
/// The database stores only the path returned by [saveBlobFile].
class MeshFileProvider {
  static MeshFileProvider? _instance;
  static MeshFileProvider get instance => _instance ??= MeshFileProvider._();
  MeshFileProvider._();

  // ------------------------------------------------------------------
  // Directory helpers
  // ------------------------------------------------------------------

  Future<Directory> _meshFilesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/mesh_files');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _meshTempDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/mesh_temp');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ------------------------------------------------------------------
  // Writing
  // ------------------------------------------------------------------

  /// Saves a fully-reassembled blob to permanent storage.
  ///
  /// Returns the absolute file path, suitable for storing in the DB.
  Future<String> saveBlobFile({
    required String groupId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final ext = _extensionForMime(mimeType);
    final dir = await _meshFilesDir();
    final file = File('${dir.path}/$groupId$ext');
    await file.writeAsBytes(bytes, flush: true);
    LogService.info(
      '💾 MeshFileProvider: saved ${bytes.length}B → ${file.path}',
    );
    return file.path;
  }

  // ------------------------------------------------------------------
  // Reading
  // ------------------------------------------------------------------

  /// Reads a stored blob file as bytes.
  Future<Uint8List?> readBlobFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        LogService.warning('MeshFileProvider: file not found: $filePath');
        return null;
      }
      return await file.readAsBytes();
    } catch (e) {
      LogService.error('MeshFileProvider: read error', e);
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Integrity
  // ------------------------------------------------------------------

  /// Returns a SHA-256 hex string for [bytes].
  static String hashOf(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ------------------------------------------------------------------
  // Cleanup
  // ------------------------------------------------------------------

  /// Deletes a stored file by its absolute path.
  Future<void> deleteBlobFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        LogService.info('🗑️ MeshFileProvider: deleted $filePath');
      }
    } catch (e) {
      LogService.warning('MeshFileProvider: delete error: $e');
    }
  }

  /// Purges all temporary chunk buffers (called when app resumes or daily).
  Future<void> purgeTempFiles() async {
    try {
      final dir = await _meshTempDir();
      await dir.delete(recursive: true);
      LogService.info('🧹 MeshFileProvider: temp dir purged');
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  String _extensionForMime(String mime) {
    switch (mime.toLowerCase()) {
      case 'audio/ogg':
      case 'audio/opus':
        return '.ogg';
      case 'audio/mpeg':
        return '.mp3';
      case 'audio/aac':
        return '.aac';
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      default:
        return '.bin';
    }
  }

  /// JSON reference payload stored in the DB instead of raw bytes.
  static Map<String, dynamic> fileRefJson({
    required String filePath,
    required String mimeType,
    required int sizeBytes,
    String? sha256Hash,
  }) =>
      {
        'type': 'file_ref',
        'path': filePath,
        'mime': mimeType,
        'size': sizeBytes,
        if (sha256Hash case final h?) 'sha256': h,
      };

  /// Checks whether a message [content] is a file reference JSON.
  static bool isFileRef(String content) {
    try {
      final json = jsonDecode(content);
      return json is Map && json['type'] == 'file_ref';
    } catch (_) {
      return false;
    }
  }

  /// Parses a file reference JSON string into the map.
  static Map<String, dynamic>? parseFileRef(String content) {
    try {
      final json = jsonDecode(content);
      if (json is Map<String, dynamic> && json['type'] == 'file_ref') return json;
    } catch (_) {}
    return null;
  }
}
