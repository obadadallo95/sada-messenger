# نظام إدارة الطاقة - Sada

تم بناء نظام إدارة الطاقة الكامل للتطبيق مع دعم Duty Cycle لتوفير البطارية.

## ✅ المكونات المنجزة

### 1. PowerMode Model (`lib/core/models/power_mode.dart`)
- **High Performance**: مسح مستمر (جيد للمحادثات النشطة)
- **Balanced**: مسح 30 ثانية، نوم 5 دقائق (افتراضي)
- **Low Power**: مسح 30 ثانية، نوم 15 دقيقة

### 2. PowerModeProvider (`lib/core/services/power_mode_provider.dart`)
- إدارة حالة وضع الطاقة باستخدام Riverpod
- حفظ/تحميل من SharedPreferences
- تحديث تلقائي للـ Background Service عند التغيير

### 3. Background Service (`lib/core/services/background_service.dart`)
- خدمة خلفية Foreground مع إشعار دائم
- Duty Cycle Logic:
  - **High Performance**: مسح مستمر
  - **Balanced/Low Power**: مسح ثم نوم حسب المدة المحددة
- تحديث الإشعار تلقائياً ("Scanning..." / "Sleeping")
- دعم تحديث الوضع ديناميكياً بدون إعادة تشغيل

### 4. Settings UI (`lib/features/settings/presentation/pages/settings_page.dart`)
- قسم "استهلاك البطارية" مع 3 خيارات
- زر "إلغاء تحسين البطارية" لفتح إعدادات النظام
- وصف لكل وضع بالعربية والإنجليزية

## 📱 التبعيات المضافة

- `flutter_background_service`: للخدمة الخلفية
- `android_alarm_manager_plus`: لدعم Android (مستقبلاً)

## 🔧 التكوين المطلوب

### Android (`AndroidManifest.xml`)
تم إضافة الصلاحيات التالية:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS
لا يحتاج تعديلات إضافية.

## 🧪 الاستخدام

### تغيير وضع الطاقة:
```dart
final powerModeNotifier = ref.read(powerModeProvider.notifier);
await powerModeNotifier.setPowerMode(PowerMode.balanced);
```

### بدء/إيقاف الخدمة الخلفية:
```dart
// تهيئة
await BackgroundService.instance.initialize();

// بدء
await BackgroundService.instance.start();

// إيقاف
await BackgroundService.instance.stop();
```

## 📝 ملاحظات

1. **Reactive Architecture**: عند تغيير الوضع من Settings، يتم تحديث Background Service تلقائياً
2. **Foreground Notification**: الخدمة تعرض إشعار دائم لتجنب قتل التطبيق من Android
3. **Battery Optimization**: زر في Settings لفتح إعدادات النظام لإلغاء تحسين البطارية

## ✅ الحالة

جميع المكونات جاهزة! النظام يدعم:
- ✅ 3 أوضاع طاقة (High/Balanced/Low)
- ✅ Duty Cycle Logic
- ✅ تحديث ديناميكي للوضع
- ✅ إشعارات Foreground
- ✅ UI في Settings
- ✅ زر Battery Optimization

## ⚠️ ملاحظات مهمة

1. **Background Service**: يحتاج إلى تهيئة في `app.dart` عند بدء التطبيق
2. **Battery Optimization**: يجب توجيه المستخدمين لإلغاء تحسين البطارية يدوياً من إعدادات النظام
3. **Testing**: اختبر على أجهزة حقيقية لأن المحاكيات قد لا تدعم Background Services بشكل كامل

