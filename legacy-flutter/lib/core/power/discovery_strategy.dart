import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../models/power_mode.dart';
import '../utils/log_service.dart';

/// استراتيجية Discovery مع Battery-Aware Logic
/// تحدد الفترات الديناميكية للاكتشاف بناءً على حالة البطارية و App Lifecycle
class DiscoveryStrategy {
  final MethodChannel _batteryChannel = const MethodChannel('org.sada.messenger/battery');
  
  int _currentInterval = 60; // Default: 60 seconds
  bool _isForeground = true;
  bool _isCharging = false;
  double _batteryLevel = 100.0;
  
  DiscoveryStrategy();

  /// الحصول على فترة Discovery الحالية (بالثواني)
  int get currentInterval => _currentInterval;

  /// تحديث استراتيجية Discovery بناءً على:
  /// - PowerMode (Performance/Balanced/Low Power)
  /// - App Lifecycle (Foreground/Background)
  /// - Battery Level
  /// - Charging Status
  Future<void> updateStrategy({
    PowerMode? powerMode,
    bool? isForeground,
    bool? isCharging,
    double? batteryLevel,
  }) async {
    if (powerMode != null) {
      // تحديث PowerMode
    }
    
    if (isForeground != null) {
      _isForeground = isForeground;
    }
    
    if (isCharging != null) {
      _isCharging = isCharging;
    }
    
    if (batteryLevel != null) {
      _batteryLevel = batteryLevel;
    }

    // حساب الفترة المثلى
    final newInterval = _calculateOptimalInterval(
      powerMode: powerMode,
      isForeground: _isForeground,
      isCharging: _isCharging,
      batteryLevel: _batteryLevel,
    );

    if (newInterval != _currentInterval) {
      _currentInterval = newInterval;
      LogService.info('📊 تم تحديث Discovery Interval: ${_currentInterval}s');
      LogService.info('   - Foreground: $_isForeground');
      LogService.info('   - Charging: $_isCharging');
      LogService.info('   - Battery: ${_batteryLevel.toStringAsFixed(0)}%');
    }
  }

  /// حساب الفترة المثلى للاكتشاف
  int _calculateOptimalInterval({
    PowerMode? powerMode,
    required bool isForeground,
    required bool isCharging,
    required double batteryLevel,
  }) {
    // Performance Mode: 5 seconds (foreground أو charging)
    if (powerMode == PowerMode.highPerformance || 
        (isForeground && isCharging)) {
      return 5;
    }

    // Low Power Mode: 5-10 minutes (battery < 15%)
    if (powerMode == PowerMode.lowPower || batteryLevel < 15) {
      if (batteryLevel < 10) {
        return 600; // 10 minutes
      }
      return 300; // 5 minutes
    }

    // Balanced Mode: 60 seconds (default background)
    if (isForeground) {
      return 30; // Foreground: 30 seconds
    }
    
    return 60; // Background: 60 seconds
  }

  /// تحديث حالة البطارية
  Future<void> updateBatteryStatus() async {
    try {
      // محاولة الحصول على حالة البطارية من Native
      final batteryData = await _batteryChannel.invokeMethod<Map>('getBatteryStatus');
      
      if (batteryData != null) {
        final level = (batteryData['level'] as num?)?.toDouble() ?? 100.0;
        final charging = batteryData['charging'] as bool? ?? false;
        
        await updateStrategy(
          batteryLevel: level,
          isCharging: charging,
        );
      }
    } catch (e) {
      LogService.warning('لا يمكن الحصول على حالة البطارية: $e');
      // استخدام القيم الافتراضية
    }
  }

  /// تحديث App Lifecycle
  void updateAppLifecycle(bool isForeground) {
    updateStrategy(isForeground: isForeground);
  }

  /// تحديث PowerMode
  void updatePowerMode(PowerMode mode) {
    updateStrategy(powerMode: mode);
  }
}

/// Provider لـ DiscoveryStrategy
final discoveryStrategyProvider = Provider<DiscoveryStrategy>((ref) {
  return DiscoveryStrategy();
});

