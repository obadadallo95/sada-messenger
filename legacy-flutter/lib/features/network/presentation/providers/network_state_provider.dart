import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkState {
  final int peerCount;
  final String status;
  final bool isScanning;

  const NetworkState({
    required this.peerCount,
    required this.status,
    required this.isScanning,
  });

  const NetworkState.initial()
    : peerCount = 0,
      status = 'Initializing...',
      isScanning = false;

  NetworkState copyWith({int? peerCount, String? status, bool? isScanning}) {
    return NetworkState(
      peerCount: peerCount ?? this.peerCount,
      status: status ?? this.status,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

final networkStateProvider =
    StateNotifierProvider<NetworkStateController, NetworkState>(
      (ref) => NetworkStateController(),
    );

class NetworkStateController extends StateNotifier<NetworkState> {
  final FlutterBackgroundService _service = FlutterBackgroundService();
  StreamSubscription<Map<String, dynamic>?>? _peerSubscription;
  StreamSubscription<Map<String, dynamic>?>? _statusSubscription;

  NetworkStateController() : super(const NetworkState.initial()) {
    _listen();
  }

  void _listen() {
    _peerSubscription = _service.on('updatePeerCount').listen((event) {
      if (event == null) return;
      final dynamic countValue = event['count'];
      final peerCount = countValue is int ? countValue : 0;
      state = state.copyWith(peerCount: peerCount);
    });

    _statusSubscription = _service.on('updateStatus').listen((event) {
      if (event == null) return;
      final statusValue = (event['status'] ?? state.status).toString();
      final dynamic peerCountValue = event['peerCount'];
      final peerCount = peerCountValue is int
          ? peerCountValue
          : state.peerCount;
      state = state.copyWith(
        status: statusValue,
        peerCount: peerCount,
        isScanning: statusValue.contains('Scanning'),
      );
    });
  }

  @override
  void dispose() {
    _peerSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
