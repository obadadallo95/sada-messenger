# قاعدة البيانات - Drift Implementation

## ✅ ما تم إنجازه

1. ✅ إضافة Dependencies (`drift`, `drift_dev`, `sqlite3_flutter_libs`, `path`)
2. ✅ إنشاء Tables:
   - `ContactsTable` - جهات الاتصال
   - `ChatsTable` - المحادثات
   - `MessagesTable` - الرسائل
3. ✅ إنشاء `AppDatabase` class مع Duress Mode support
4. ✅ تحديث `database_provider.dart` لاستخدام Drift

## ⚠️ مشكلة Build Runner

**المشكلة الحالية:** هناك تعارض في الإصدارات بين `analyzer_plugin` و `analyzer` يمنع build_runner من العمل.

**السبب:** `custom_lint_core` و `custom_lint_visitor` (transitive dependencies) يستخدمان `analyzer_plugin 0.12.0` القديم الذي لا يتوافق مع `analyzer 7.6.0`.

## 🔧 الحلول البديلة

### الحل 1: استخدام Drift بدون Code Generation (مؤقت)

يمكن استخدام Drift بدون code generation باستخدام `DriftDatabase` مباشرة. لكن هذا يتطلب تعديل الكود.

### الحل 2: إنشاء app_database.g.dart يدوياً (غير موصى به)

يمكن إنشاء الملف يدوياً، لكنه سيكون معقداً جداً.

### الحل 3: تحديث جميع الإصدارات (موصى به)

```bash
# تحديث جميع packages إلى أحدث إصدارات متوافقة
flutter pub upgrade --major-versions

# ثم تشغيل build_runner
dart run build_runner build --delete-conflicting-outputs
```

### الحل 4: استخدام إصدارات محددة متوافقة

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  drift_dev: ^2.18.0
  freezed: ^2.5.8  # يبقى على هذا الإصدار
```

## 🔧 الخطوات المتبقية (بعد حل مشكلة Build Runner)

### 1. تشغيل Build Runner

بعد حل مشكلة التوافق:

```bash
# خيار 1: تحديث build_runner
flutter pub upgrade build_runner

# خيار 2: استخدام إصدار محدد
flutter pub add --dev build_runner:^2.4.0

# ثم تشغيل
flutter pub run build_runner build --delete-conflicting-outputs
```

أو إذا استمرت المشكلة:

```bash
# حذف .dart_tool و build folder
rm -rf .dart_tool build

# إعادة تثبيت
flutter pub get

# تشغيل build_runner
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. بعد نجاح Build Runner

سيتم إنشاء الملفات التالية:
- `app_database.g.dart` - الكود المولد

### 3. ربط ChatRepository بالـ Database

تحديث `lib/features/chat/data/repositories/chat_repository.dart`:

```dart
@riverpod
class ChatRepository extends _$ChatRepository {
  @override
  Future<List<ChatModel>> build() async {
    final database = await ref.read(appDatabaseProvider.future);
    final chats = await database.getAllChats();
    
    // تحويل Chat (من Drift) إلى ChatModel
    return chats.map((chat) => ChatModel(
      id: chat.id,
      name: chat.name ?? chat.peerId ?? 'Unknown',
      // ... باقي الحقول
    )).toList();
  }
}
```

## 📁 البنية

```
lib/core/database/
├── app_database.dart          # Database class الرئيسي
├── app_database.g.dart        # ⚠️ سيتم إنشاؤه بواسطة build_runner
├── database_provider.dart     # Riverpod providers
├── tables/
│   ├── contacts_table.dart
│   ├── chats_table.dart
│   ├── messages_table.dart
│   └── tables.dart           # Export file
└── README.md                  # هذا الملف
```

## 🔐 Duress Mode

قاعدة البيانات تدعم Duress Mode:

- **Master PIN** → `sada_encrypted.sqlite` (قاعدة بيانات حقيقية)
- **Duress PIN** → `sada_dummy.sqlite` (قاعدة بيانات وهمية مع بيانات وهمية)

عند تسجيل الدخول بـ Duress PIN، يتم ملء قاعدة البيانات تلقائياً ببيانات وهمية:
- جهات اتصال: "Mom", "Football Group"
- محادثات وهمية
- رسائل وهمية

## 📝 ملاحظات

- جميع الجداول تستخدم `TextColumn` للمفاتيح (String IDs)
- Foreign Keys مفعلة بين الجداول
- `LazyDatabase` يستخدم لفتح قاعدة البيانات بشكل غير متزامن
- قاعدة البيانات تُغلق تلقائياً عند إغلاق التطبيق

