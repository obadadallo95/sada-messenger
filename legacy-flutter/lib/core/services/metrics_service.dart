import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/log_service.dart';

/// Provider for MetricsService
final metricsServiceProvider = Provider<MetricsService>((ref) {
  return MetricsService();
});

/// Service to track and expose network metrics
class MetricsService {
  // Counters
  int _acksSent = 0;
  int _acksReceived = 0;
  int _messagesReceived = 0;
  int _messagesDelivered = 0; // Confirmed by ACK
  int _duplicatesIgnored = 0;
  
  // Stream controller to broadcast updates
  final _metricsController = StreamController<Map<String, int>>.broadcast();

  MetricsService();

  /// Stream of metrics updates
  Stream<Map<String, int>> get metricsStream => _metricsController.stream;

  /// Get current snapshot
  Map<String, int> get currentMetrics => {
    'acksSent': _acksSent,
    'acksReceived': _acksReceived,
    'messagesReceived': _messagesReceived,
    'messagesDelivered': _messagesDelivered,
    'duplicatesIgnored': _duplicatesIgnored,
  };

  void recordAckSent() {
    _acksSent++;
    _notify();
    LogService.info('📊 Metric: ACK Sent (Total: $_acksSent)');
  }

  void recordAckReceived() {
    _acksReceived++;
    _notify();
    LogService.info('📊 Metric: ACK Received (Total: $_acksReceived)');
  }

  void recordMessageReceived() {
    _messagesReceived++;
    _notify();
  }

  void recordMessageDelivered() {
    _messagesDelivered++;
    _notify();
    LogService.info('📊 Metric: Message Delivered (Total: $_messagesDelivered)');
  }

  void recordDuplicateIgnored() {
    _duplicatesIgnored++;
    _notify();
    LogService.info('📊 Metric: Duplicate Cloud (Total: $_duplicatesIgnored)');
  }

  void _notify() {
    _metricsController.add(currentMetrics);
  }

  void dispose() {
    _metricsController.close();
  }
}
