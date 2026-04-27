# Duress Mode (نظام الذعر) - Sada

تم بناء نظام Duress Mode للتطبيق، والذي يسمح للمستخدم بإدخال PIN مختلف لعرض بيانات وهمية عند الإكراه.

## ✅ المكونات المنجزة

### 1. تحديث AuthService (`lib/core/services/auth_service.dart`)
- **AuthType Enum**: إضافة `master`, `duress`, `failure`
- **setMasterPin()**: تعيين Master PIN مع Hash آمن
- **setDuressPin()**: تعيين Duress PIN مع Hash آمن
- **verifyPin()**: التحقق من PIN وإرجاع AuthType المناسب
- **Security**: 
  - استخدام SHA-256 مع Salt لتشفير PINs
  - حفظ Hashes في `FlutterSecureStorage`
  - عدم حفظ PINs بشكل نصي

### 2. Database Provider (`lib/core/database/database_provider.dart`)
- **DatabaseMode Enum**: `real` و `dummy`
- **databaseModeProvider**: Provider لحالة قاعدة البيانات
- **currentAuthTypeProvider**: Provider لنوع المصادقة الحالي
- **databasePathProvider**: Provider لمسار قاعدة البيانات (حقيقي أو وهمي)
- **DatabaseInitializer**: 
  - `initializeDatabase()`: تهيئة قاعدة البيانات بناءً على AuthType
  - `_initializeRealDatabase()`: تهيئة قاعدة البيانات الحقيقية
  - `_initializeDummyDatabase()`: تهيئة قاعدة البيانات الوهمية (مع seeding)

### 3. تحديث Lock Screen (`lib/features/auth/presentation/pages/lock_screen.dart`)
- **PIN Entry**: 
  - NumPad كامل (0-9)
  - PIN Dots لإظهار عدد الأرقام المدخلة
  - Shake Animation عند الخطأ (باستخدام `flutter_animate`)
  - Haptic Feedback
- **Biometric Integration**: 
  - محاولة المصادقة البيومترية تلقائياً
  - التبديل إلى PIN Pad إذا فشلت أو لم تكن متاحة
- **Seamless Transition**: 
  - Fade transition عند النجاح
  - لا تظهر أي رسالة مختلفة في Duress Mode
  - UI متطابق في كلا الوضعين

### 4. تحديث Settings (`lib/features/settings/presentation/pages/settings_screen.dart`)
- **Change Master PIN**: خيار لتغيير Master PIN
- **Set Duress PIN**: خيار لتعيين Duress PIN مع تحذير
- **Warning Dialog**: تحذير واضح عند تعيين Duress PIN
- **Validation**: التحقق من تطابق PINs

### 5. الترجمة
- إضافة جميع النصوص المطلوبة بالعربية والإنجليزية:
  - `enterPin`, `changeMasterPin`, `setDuressPin`
  - `duressPinWarning`, `enterMasterPin`, `enterDuressPin`
  - `confirmPin`, `pinMismatch`, `pinSetSuccessfully`, `pinChangedSuccessfully`

## 🔒 الأمان

### الميزات الأمنية المطبقة:
- ✅ SHA-256 Hash مع Salt لـ PINs
- ✅ حفظ Hashes في `FlutterSecureStorage` (مشفر)
- ✅ عدم حفظ PINs بشكل نصي
- ✅ Salt فريد لكل مستخدم
- ✅ UI متطابق في كلا الوضعين (لا توجد علامات على Duress Mode)

### الميزات المطلوبة:
- ⏳ Seeding قاعدة البيانات الوهمية ببيانات واقعية
- ⏳ تعطيل "Backup" و "Export Keys" في Duress Mode
- ⏳ Integration مع قاعدة البيانات الفعلية

## 📝 ملاحظات

1. **Database Seeding**: يجب إضافة بيانات وهمية واقعية في `_initializeDummyDatabase()`:
   - Contact: "Mom", Message: "Don't forget to buy bread."
   - Contact: "Football Group", Message: "Match is at 5 PM."
   - إلخ...

2. **Silent Failures**: في Duress Mode، يجب تعطيل:
   - Backup features
   - Export Keys
   - أي شيء قد يكشف البيانات الحقيقية

3. **UI Consistency**: ⚠️ مهم جداً - UI يجب أن يكون متطابقاً تماماً في كلا الوضعين.

## 🔧 الخطوات المتبقية

### 1. Database Seeding
```dart
Future<void> _initializeDummyDatabase() async {
  // إدراج بيانات وهمية:
  // - Contact: "Mom", Message: "Don't forget to buy bread."
  // - Contact: "Football Group", Message: "Match is at 5 PM."
  // - إلخ...
}
```

### 2. Disable Features in Duress Mode
في Settings، يجب تعطيل:
- Backup
- Export Keys
- أي شيء قد يكشف البيانات الحقيقية

### 3. Integration with Real Database
عند تنفيذ قاعدة البيانات الفعلية:
- ربط `databasePathProvider` بمسار قاعدة البيانات الفعلية
- تهيئة قاعدة البيانات بناءً على AuthType

## ✅ الحالة

جميع المكونات الأساسية جاهزة! النظام يدعم:
- ✅ Master PIN و Duress PIN
- ✅ Hash آمن لـ PINs
- ✅ PIN Entry مع NumPad
- ✅ Shake Animation عند الخطأ
- ✅ Seamless Transition
- ✅ Settings Integration
- ✅ UI متطابق في كلا الوضعين

## 🚀 الاستخدام

1. **تعيين PINs**: Settings → Privacy & Security → Set Master PIN / Set Duress PIN
2. **الدخول**: Lock Screen → إدخال PIN (Master أو Duress)
3. **Duress Mode**: عند إدخال Duress PIN، يتم تحميل قاعدة البيانات الوهمية تلقائياً

