# اختبارات الوحدة - Sada

## نظرة عامة

هذا المجلد يحتوي على اختبارات الوحدة الشاملة لمحاكاة منطق التطبيق الداخلي بدون الحاجة لتشغيل محاكي أو واجهة المستخدم.

## البنية

- `simulation_test.dart`: الاختبارات الرئيسية للسيناريوهات الثلاثة
- `test_helpers.dart`: مساعدات الاختبار (قاعدة بيانات في الذاكرة)
- `widget_test.dart`: اختبارات الواجهة (إن وجدت)

## السيناريوهات المختبرة

### Scenario A: The Security Check (Encryption Logic)
- ✅ توليد KeyPair
- ✅ تشفير الرسائل
- ✅ فك التشفير

**⚠️ ملاحظة مهمة:** اختبارات التشفير **معطلة حالياً** لأن `sodium_libs` يحتاج تهيئة خاصة (`SodiumPlatform._instance`) حتى على الجهاز الحقيقي. 

**السبب:** `SodiumPlatform._instance` غير متاح في بيئة الاختبار حتى مع `TestWidgetsFlutterBinding.ensureInitialized()`.

**الحل البديل:** يمكن اختبار التشفير يدوياً في التطبيق الفعلي (`flutter run`) بدلاً من الاختبارات الآلية.

### Scenario B: The Memory Check (Database Logic)
- ✅ تهيئة قاعدة بيانات فارغة
- ✅ إنشاء مستخدم ورسالة
- ✅ الاستعلام عن البيانات

**✅ يعمل بشكل كامل في بيئة الاختبار المحلية!**

**ملاحظة:** يستخدم `TestDatabase` مع قاعدة بيانات في الذاكرة (`NativeDatabase.memory()`).

### Scenario C: The Gatekeeper (Auth Logic)
- ✅ تعيين Master PIN والتحقق منه
- ✅ تعيين Duress PIN والتحقق منه
- ✅ رفض PIN خاطئ
- ✅ التحقق من أن كلا PINs يعملان معاً

**✅ يعمل بشكل كامل في بيئة الاختبار المحلية!**

**ملاحظة:** يستخدم `MethodChannel` mock لمحاكاة `FlutterSecureStorage` في بيئة الاختبار.

## تشغيل الاختبارات

```bash
# تشغيل جميع الاختبارات
flutter test

# تشغيل اختبار محدد
flutter test test/simulation_test.dart

# تشغيل سيناريو محدد
flutter test test/simulation_test.dart --plain-name "Scenario B"

# تشغيل على جهاز/محاكي (للاختبارات التي تحتاج منصة فعلية)
flutter test --device-id=<device-id> test/simulation_test.dart
```

## المتطلبات

- `mocktail`: للـ mocking (مضاف في `pubspec.yaml`)
- `drift`: لقاعدة البيانات
- `sodium_libs`: للتشفير (قد يحتاج منصة فعلية)

## النتائج الحالية

- ✅ **Scenario B**: يعمل بشكل كامل (3/3 اختبارات نجحت) - **جاهز للاستخدام!**
- ✅ **Scenario C**: يعمل بشكل كامل (4/4 اختبارات نجحت) - **جاهز للاستخدام!**
- ⚠️ **Scenario A**: يحتاج منصة فعلية (`sodium_libs` يحتاج `SodiumPlatform._instance`)

### ملخص النتائج من آخر تشغيل:

```
✅ Scenario B: 3/3 اختبارات نجحت (Database Logic)
✅ Scenario C: 4/4 اختبارات نجحت (Auth Logic)
❌ Scenario A: 0/3 اختبارات (LateInitializationError - sodium_libs)
```

**الخلاصة:** **Scenario B (Database Logic)** و **Scenario C (Auth Logic)** يعملان بشكل كامل في بيئة الاختبار المحلية!

## ملاحظات مهمة

1. **اختبارات التشفير (Scenario A)**: 
   - تحتاج إلى منصة Flutter فعلية لأن `sodium_libs` يحتاج تهيئة منصة
   - استخدم: `flutter test --device-id=<device-id> test/simulation_test.dart --plain-name "Scenario A"`

2. **قاعدة البيانات (Scenario B)**: 
   - ✅ **يعمل بشكل كامل** في بيئة الاختبار المحلية
   - يستخدم `TestDatabase` مع قاعدة بيانات في الذاكرة (`NativeDatabase.memory()`)

3. **المصادقة (Scenario C)**: 
   - ✅ **يعمل بشكل كامل** في بيئة الاختبار المحلية
   - يستخدم `MethodChannel` mock لمحاكاة `FlutterSecureStorage`
   - جميع العمليات (`read`, `write`, `delete`) تعمل بشكل صحيح في بيئة الاختبار

## الإصلاحات المطبقة

- ✅ إضافة `TestWidgetsFlutterBinding.ensureInitialized()` في بداية `main()`
- ✅ استخدام `MethodChannel` mock لمحاكاة `FlutterSecureStorage` في Scenario C
- ✅ استخدام `NativeDatabase.memory()` لقاعدة البيانات في الذاكرة
- ✅ إضافة `Map<String, String>` للتخزين الوهمي في الاختبارات
