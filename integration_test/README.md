# اختبارات التكامل - Sada

## نظرة عامة

هذا المجلد يحتوي على اختبارات التكامل الشاملة التي تختبر التطبيق كوحدة واحدة على جهاز حقيقي أو محاكي.

## البنية

- `app_test.dart`: اختبار سيناريو "Happy Path" الكامل

## السيناريو المختبر

### Happy Path - رحلة المستخدم الكاملة

1. **إطلاق التطبيق**: إطلاق `App` widget
2. **معالجة المصادقة**:
   - إذا كان Lock Screen: إدخال PIN (123456)
   - إذا كان Onboarding: التمرير خلال slides ثم التسجيل
3. **التحقق من Home Screen**: التحقق من العنوان و FAB
4. **التفاعل مع Settings**: الانتقال إلى Settings والتحقق من Theme و Power Mode
5. **العودة إلى Home**: التنقل مرة أخرى إلى Home Screen

## تشغيل الاختبارات

```bash
# على جهاز حقيقي
flutter test integration_test/app_test.dart --device-id=<DEVICE_ID>

# على محاكي
flutter test integration_test/app_test.dart

# أو باستخدام integration_test مباشرة
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

## Keys المضافة للـ Widgets

لتمكين الاختبارات من العثور على الـ widgets، تم إضافة Keys التالية:

### Lock Screen (`lib/features/auth/presentation/pages/lock_screen.dart`)
- `Key('pin_0')` إلى `Key('pin_9')`: أزرار PIN
- `Key('pin_backspace')`: زر حذف

### Register Screen (`lib/features/auth/presentation/pages/register_screen.dart`)
- `Key('register_name_field')`: حقل إدخال الاسم
- `Key('register_button')`: زر التسجيل

### Bottom Navigation (`lib/core/router/app_router.dart`)
- `Key('bottom_nav_home')`: زر Home
- `Key('bottom_nav_settings')`: زر Settings

### Home Screen (`lib/features/home/presentation/pages/home_screen.dart`)
- `GlobalKey(debugLabel: 'home_fab')`: FAB (Radar button)

## ملاحظات مهمة

1. **الانتظار للرسوم المتحركة**: يستخدم الاختبار `pumpAndSettle()` للانتظار حتى اكتمال جميع الرسوم المتحركة
2. **المرونة**: الاختبار يتعامل مع حالات مختلفة (Lock Screen أو Onboarding)
3. **الترجمة**: الاختبار يبحث عن النصوص بالعربية والإنجليزية

## المتطلبات

- `integration_test`: package من Flutter SDK (مضاف في `pubspec.yaml`)
- جهاز حقيقي أو محاكي متصل

