import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';

/// Live count of encrypted relay packets carried by this device.
final relayQueueCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final database = await ref.watch(appDatabaseProvider.future);

  yield await database.getRelayStorageSize();

  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    yield await database.getRelayStorageSize();
  }
});
