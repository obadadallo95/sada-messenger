import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../chat/domain/models/chat_model.dart';
import '../../../core/utils/log_service.dart';

// part 'groups_repository.g.dart'; // سيتم تفعيله لاحقاً عند إضافة Riverpod generators

/// Provider لـ Groups Repository
final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository();
});

/// Repository لإدارة المجموعات
class GroupsRepository {
  static const String _groupsKey = 'sada_groups';
  static const String _joinedGroupsKey = 'sada_joined_groups';
  final _uuid = const Uuid();

  /// إنشاء مجموعة جديدة
  Future<ChatModel> createGroup({
    required String name,
    required String description,
    required bool isPublic,
    String? password,
  }) async {
    try {
      // الحصول على معرف المستخدم الحالي (من AuthService)
      // في الوقت الحالي، سنستخدم معرف مؤقت
      final groupId = 'group_${_uuid.v4()}';
      final ownerId = 'user_${_uuid.v4()}'; // سيتم الحصول عليه من AuthService لاحقاً

      final now = DateTime.now();

      final group = ChatModel(
        id: groupId,
        name: name,
        groupName: name,
        groupDescription: description,
        isGroup: true,
        groupOwnerId: ownerId,
        isPublic: isPublic,
        time: now,
        avatarColor: _generateColorFromName(name).toARGB32(),
        memberCount: 1, // المنشئ هو أول عضو
      );

      // حفظ المجموعة في SharedPreferences
      await _saveGroup(group);

      LogService.info('تم إنشاء المجموعة: $name');
      return group;
    } catch (e) {
      LogService.error('خطأ في إنشاء المجموعة', e);
      rethrow;
    }
  }

  /// الحصول على المجموعات القريبة
  /// سيتم تنفيذها عند إضافة منطق اكتشاف Mesh
  Stream<List<ChatModel>> getNearbyGroups() async* {
    // إرجاع قائمة فارغة - سيتم ملؤها من Mesh Network عند إضافة منطق الاكتشاف
    yield [];
  }

  /// الانضمام إلى مجموعة
  Future<void> joinGroup(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final joinedGroups = prefs.getStringList(_joinedGroupsKey) ?? [];
      
      if (!joinedGroups.contains(groupId)) {
        joinedGroups.add(groupId);
        await prefs.setStringList(_joinedGroupsKey, joinedGroups);
        LogService.info('تم الانضمام إلى المجموعة: $groupId');
      }
    } catch (e) {
      LogService.error('خطأ في الانضمام إلى المجموعة', e);
      rethrow;
    }
  }

  /// الحصول على المجموعات التي انضم إليها المستخدم
  Future<List<ChatModel>> getMyGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final joinedGroupIds = prefs.getStringList(_joinedGroupsKey) ?? [];
      
      // تحميل جميع المجموعات المحفوظة
      final allGroups = await _loadAllGroups();
      
      // تصفية المجموعات التي انضم إليها المستخدم
      return allGroups.where((group) => joinedGroupIds.contains(group.id)).toList();
    } catch (e) {
      LogService.error('خطأ في تحميل مجموعاتي', e);
      return [];
    }
  }

  /// حفظ مجموعة في SharedPreferences
  Future<void> _saveGroup(ChatModel group) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = prefs.getStringList(_groupsKey) ?? [];
      
      // تحويل المجموعة إلى JSON
      final groupJson = group.toJson();
      final groupJsonString = groupJson.toString(); // سيتم استخدام jsonEncode لاحقاً
      
      // إضافة المجموعة إذا لم تكن موجودة
      if (!groupsJson.contains(groupJsonString)) {
        groupsJson.add(groupJsonString);
        await prefs.setStringList(_groupsKey, groupsJson);
      }
    } catch (e) {
      LogService.error('خطأ في حفظ المجموعة', e);
    }
  }

  /// تحميل جميع المجموعات المحفوظة
  Future<List<ChatModel>> _loadAllGroups() async {
    try {
      // تحميل المجموعات من SharedPreferences
      // تحويل JSON strings إلى ChatModel objects
      // سيتم تنفيذها لاحقاً عند إكمال منطق الحفظ والتحميل
      // في الوقت الحالي، نعيد قائمة فارغة
      return [];
    } catch (e) {
      LogService.error('خطأ في تحميل المجموعات', e);
      return [];
    }
  }

  /// توليد لون من اسم المجموعة
  Color _generateColorFromName(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
    ];
    
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }
}

