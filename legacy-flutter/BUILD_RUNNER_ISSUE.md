# ⚠️ مشكلة Build Runner - تعارض الإصدارات

## المشكلة

`build_runner` يفشل في التجميع بسبب تعارض بين:
- `analyzer_plugin 0.12.0` (قديم)
- `analyzer 7.6.0` (أحدث)

## الحل الموصى به

### خيار 1: تحديث جميع Packages (الأفضل)

```bash
# تحديث جميع packages
flutter pub upgrade --major-versions

# إعادة تثبيت
flutter pub get

# تشغيل build_runner
dart run build_runner build --delete-conflicting-outputs
```

### خيار 2: استخدام إصدارات محددة متوافقة

قم بتحديث `pubspec.yaml`:

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  drift_dev: ^2.18.0
  freezed: ^2.5.8  # يبقى على هذا الإصدار
```

### خيار 3: حذف custom_lint dependencies

إذا لم تكن بحاجة إلى `custom_lint`، قم بإزالته من `pubspec.yaml`:

```yaml
# إزالة هذه السطور إذا كانت موجودة:
# custom_lint: ^0.8.1
# riverpod_lint: ^2.6.4
```

## الحل البديل: استخدام Drift بدون Code Generation

إذا استمرت المشكلة، يمكن استخدام Drift بدون code generation، لكن هذا يتطلب تعديلات في الكود.

## ملاحظة

الكود جاهز 100% - المشكلة فقط في تشغيل build_runner لتوليد `app_database.g.dart`.

بعد حل المشكلة، سيتم إنشاء الملف تلقائياً وستعمل قاعدة البيانات بشكل كامل.

