import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../chat/domain/models/chat_model.dart';
import '../../../core/utils/log_service.dart';

// part 'groups_repository.g.dart'; // TODO: Uncomment after running build_runner

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
      final ownerId = 'user_${_uuid.v4()}'; // TODO: من AuthService

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
        avatarColor: _generateColorFromName(name).value,
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

  /// الحصول على المجموعات القريبة (Mock Implementation)
  Stream<List<ChatModel>> getNearbyGroups() async* {
    // محاكاة اكتشاف المجموعات القريبة
    final mockGroups = _generateMockNearbyGroups();
    
    // إرسال المجموعات تدريجياً (محاكاة الاكتشاف)
    for (var i = 0; i < mockGroups.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield mockGroups.sublist(0, i + 1);
    }
    
    // إرسال تحديثات دورية (محاكاة اكتشاف مستمر)
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield mockGroups;
    }
  }

  /// إنشاء مجموعات تجريبية قريبة
  List<ChatModel> _generateMockNearbyGroups() {
    final now = DateTime.now();
    
    return [
      ChatModel(
        id: 'group_nearby_1',
        name: 'محادثة عامة',
        groupName: 'محادثة عامة',
        groupDescription: 'مجموعة عامة للمناقشة والتفاعل',
        isGroup: true,
        groupOwnerId: 'owner_1',
        isPublic: true,
        time: now.subtract(const Duration(minutes: 10)),
        avatarColor: Colors.blue.value,
        memberCount: 5,
      ),
      ChatModel(
        id: 'group_nearby_2',
        name: 'مراقبة الحي',
        groupName: 'مراقبة الحي',
        groupDescription: 'مجموعة لمراقبة الأمان في الحي',
        isGroup: true,
        groupOwnerId: 'owner_2',
        isPublic: true,
        time: now.subtract(const Duration(minutes: 30)),
        avatarColor: Colors.green.value,
        memberCount: 12,
      ),
      ChatModel(
        id: 'group_nearby_3',
        name: 'فريق الجامعة',
        groupName: 'فريق الجامعة',
        groupDescription: 'مجموعة طلاب الجامعة للتواصل',
        isGroup: true,
        groupOwnerId: 'owner_3',
        isPublic: false,
        time: now.subtract(const Duration(hours: 1)),
        avatarColor: Colors.purple.value,
        memberCount: 8,
      ),
      ChatModel(
        id: 'group_nearby_4',
        name: 'مساعدة الجيران',
        groupName: 'مساعدة الجيران',
        groupDescription: 'مجموعة لمساعدة الجيران في المنطقة',
        isGroup: true,
        groupOwnerId: 'owner_4',
        isPublic: true,
        time: now.subtract(const Duration(hours: 2)),
        avatarColor: Colors.orange.value,
        memberCount: 15,
      ),
    ];
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
      final groupJsonString = groupJson.toString(); // TODO: استخدام jsonEncode
      
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
      // TODO: تحميل المجموعات من SharedPreferences
      // TODO: تحويل JSON strings إلى ChatModel objects
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

