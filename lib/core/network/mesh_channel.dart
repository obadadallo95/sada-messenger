import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/log_service.dart';

/// نموذج بيانات لجهاز WiFi P2P
class MeshPeer {
  final String deviceName;
  final String deviceAddress;
  final int status;
  final bool isServiceDiscoveryCapable;

  MeshPeer({
    required this.deviceName,
    required this.deviceAddress,
    required this.status,
    required this.isServiceDiscoveryCapable,
  });

  factory MeshPeer.fromJson(Map<String, dynamic> json) {
    return MeshPeer(
      deviceName: json['deviceName'] as String? ?? 'Unknown',
      deviceAddress: json['deviceAddress'] as String,
      status: json['status'] as int? ?? 0,
      isServiceDiscoveryCapable: json['isServiceDiscoveryCapable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'deviceAddress': deviceAddress,
      'status': status,
      'isServiceDiscoveryCapable': isServiceDiscoveryCapable,
    };
  }
}

/// نموذج بيانات لمعلومات الاتصال
class ConnectionInfo {
  final bool isConnected;
  final bool groupFormed;
  final bool isGroupOwner;
  final String? groupOwnerAddress;

  ConnectionInfo({
    required this.isConnected,
    required this.groupFormed,
    required this.isGroupOwner,
    this.groupOwnerAddress,
  });

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectionInfo(
      isConnected: json['isConnected'] as bool? ?? false,
      groupFormed: json['groupFormed'] as bool? ?? false,
      isGroupOwner: json['isGroupOwner'] as bool? ?? false,
      groupOwnerAddress: json['groupOwnerAddress'] as String?,
    );
  }
}

/// قناة الاتصال مع Native Android للتحكم في WiFi P2P
class MeshChannel {
  static const MethodChannel _methodChannel = MethodChannel('org.sada.messenger/mesh');
  static const EventChannel _peersEventChannel = EventChannel('org.sada.messenger/peersChanges');
  static const EventChannel _connectionEventChannel = EventChannel('org.sada.messenger/connectionChanges');

  Stream<List<MeshPeer>>? _peersStream;
  Stream<ConnectionInfo>? _connectionStream;

  /// بدء اكتشاف الأجهزة القريبة
  Future<bool> startDiscovery() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('startDiscovery');
      LogService.info('تم بدء اكتشاف WiFi P2P');
      return result ?? false;
    } catch (e) {
      LogService.error('خطأ في بدء اكتشاف WiFi P2P', e);
      return false;
    }
  }

  /// إيقاف اكتشاف الأجهزة
  Future<bool> stopDiscovery() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('stopDiscovery');
      LogService.info('تم إيقاف اكتشاف WiFi P2P');
      return result ?? false;
    } catch (e) {
      LogService.error('خطأ في إيقاف اكتشاف WiFi P2P', e);
      return false;
    }
  }

  /// الحصول على قائمة الأجهزة المكتشفة حالياً
  Future<List<MeshPeer>> getPeers() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('getPeers');
      if (result == null) {
        return [];
      }

      final List<dynamic> peersJson = jsonDecode(result);
      return peersJson
          .map((peerJson) => MeshPeer.fromJson(peerJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LogService.error('خطأ في الحصول على قائمة الأجهزة', e);
      return [];
    }
  }

  /// Stream لتحديثات الأجهزة المكتشفة
  Stream<List<MeshPeer>> get onPeersUpdated {
    _peersStream ??= _peersEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          try {
            if (event == null) return <MeshPeer>[];
            final List<dynamic> peersJson = jsonDecode(event as String);
            return peersJson
                .map((peerJson) => MeshPeer.fromJson(peerJson as Map<String, dynamic>))
                .toList();
          } catch (e) {
            LogService.error('خطأ في معالجة تحديثات الأجهزة', e);
            return <MeshPeer>[];
          }
        })
        .asBroadcastStream();

    return _peersStream!;
  }

  /// Stream لتحديثات معلومات الاتصال
  Stream<ConnectionInfo> get onConnectionInfo {
    _connectionStream ??= _connectionEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          try {
            if (event == null) {
              return ConnectionInfo(
                isConnected: false,
                groupFormed: false,
                isGroupOwner: false,
              );
            }
            final Map<String, dynamic> connectionJson = jsonDecode(event as String);
            return ConnectionInfo.fromJson(connectionJson);
          } catch (e) {
            LogService.error('خطأ في معالجة معلومات الاتصال', e);
            return ConnectionInfo(
              isConnected: false,
              groupFormed: false,
              isGroupOwner: false,
            );
          }
        })
        .asBroadcastStream();

    return _connectionStream!;
  }
}

