# 🗺️ Sada — Development Roadmap

> **الهدف:** أول اختبار ميداني في قرية/حي سوري خلال 3 أشهر

---

## المرحلة 1: الأساسيات والاستقرار *(أسبوعان)*

> **الهدف:** نظام يعمل 48 ساعة متواصلة بدون توقف على جهازين

### استقرارية النظام
- [ ] إصلاح memory leak في `_processedMessages` (LRU cache بحد 10,000)
- [ ] إضافة battery listener مستمر (حالياً يُفحص مرة واحدة فقط)
- [ ] إضافة rate limiting لـ CONTACT_EXCHANGE (منع spam)
- [ ] تحديد حجم relay queue + تنظيف دوري

### تشفير قاعدة البيانات
- [ ] الانتقال من `drift/native` إلى `drift` + `sqlcipher_flutter_libs`
- [ ] تشفير ملفات الصوت المخزنة (XSalsa20)

### تبسيط الأمان
- [ ] تحويل Duress Mode إلى App Lock بسيط (PIN فقط)
- [ ] إزالة إشارات "Duress PIN" و "dual database" من UI
- [ ] تحديث `legal_content.dart` لإزالة مراجع Duress Mode

### تنظيف الكود
- [ ] تعطيل logging الحساس (device IDs, IPs) في production builds
- [ ] حذف `user_data_backup` من SharedPreferences

### اختبار
- [ ] اختبار 48 ساعة: جهازين متصلين عبر WiFi → إرسال/استقبال كل 5 دقائق
- [ ] اختبار battery drain: 8 ساعات في وضع balanced

---

## المرحلة 2: LoRa Integration *(أسبوعان)*

> **الهدف:** إرسال أول رسالة "Hello Sada" عبر LoRa بين جهازين على مسافة 2 كم

### الأجهزة
- **Board:** Heltec WiFi LoRa 32 (V3) — ESP32-S3 + SX1262
- **التردد:** 868 MHz (ISM band — سوريا/أوروبا)
- **Spread Factor:** SF10 (توازن بين مدى واستهلاك)

### البرمجيات
- [ ] كتابة firmware للـ ESP32 (Arduino/PlatformIO)
  - UART serial bridge: يستقبل رسائل من الهاتف عبر USB/BLE
  - LoRa TX/RX مع acknowledgment بسيط
  - Deep sleep + wake-on-receive
- [ ] كتابة Flutter LoRa Module
  - `LoRaTransportService`: يتصل بالـ ESP32 عبر USB Serial / BLE
  - Message fragmentation: تقسيم الرسائل > 50 بايت
  - Binary protocol (لا JSON — payload صغير جداً)
- [ ] Gateway Mode: الهاتف يعمل كجسر بين WiFi Mesh ↔ LoRa

### اختبار ميداني
- [ ] اختبار المدى: 500م / 1 كم / 2 كم / 5 كم
- [ ] اختبار الطاقة: كم ساعة على بطارية 18650 (3.7V 3000mAh)
- [ ] اختبار معدل الخطأ: Packet Error Rate في بيئة حضرية

---

## المرحلة 3: التجربة الميدانية *(شهر)*

> **الهدف:** نشر في حي/قرية واحدة — 50-100 مستخدم حقيقي

### التجهيز
- [ ] بناء 3-5 عقد LoRa ثابتة (Solar + Battery + Heltec board)
- [ ] تثبيت التطبيق على 20+ جهاز
- [ ] إعداد تقرير تشخيصي تلقائي (diagnostic report generator)

### جمع البيانات
- [ ] جمع feedback عبر نموذج بسيط في التطبيق
- [ ] تتبع: معدل وصول الرسائل، وقت التأخير، استهلاك البطارية
- [ ] مقابلات مع 10 مستخدمين لفهم الاستخدام الفعلي

### التحسين
- [ ] إصلاح المشاكل المكتشفة
- [ ] تحسين UI/UX بناءً على feedback المستخدمين
- [ ] تحسين استهلاك البطارية بناءً على البيانات الفعلية

---

## المرحلة 4: الإطلاق العام *(شهر)*

> **الهدف:** نشر عام على F-Droid + GitHub Releases

- [ ] نشر APK على F-Droid (لا يحتاج Google Play)
- [ ] GitHub Releases مع APK مباشر
- [ ] توثيق كامل بالعربية والإنجليزية
- [ ] فيديو شرح (2 دقيقة) للمستخدم العادي
- [ ] تصميم ملصق/منشور للتوعية المجتمعية
- [ ] إعداد صفحة ويب بسيطة (landing page)

---

## الملفات التي يجب تعديلها/حذفها

### حذف
| الملف | السبب |
|---|---|
| `test/features/duress/safe_notes_screen_test.dart` | ميزة Duress Mode ملغاة |

### تعديل
| الملف | التعديل |
|---|---|
| `lib/core/constants/legal_content.dart` | إزالة مراجع Duress Mode من Privacy Policy |
| `lib/core/services/background_service.dart` | تبسيط منطق `authTypeStr == 'duress'` إلى مجرد app lock |
| `lib/core/widgets/hidden_exit_gesture.dart` | إزالة أو تحويل إلى ميزة عادية |
| `lib/features/settings/presentation/pages/settings_screen.dart` | إزالة خيار "Set Duress PIN" |
| `lib/core/router/app_router.dart` | إزالة route لـ `safe_notes_screen` |
| `lib/l10n/app_localizations_*.dart` | إزالة strings: `setDuressPin`, `duressPinWarning`, `enterDuressPin` |

---

## أولويات التطوير

```
P0 (حرج):    استقرار النظام + LoRa + إدارة البطارية
P1 (عالي):    تشفير قاعدة البيانات + موثوقية الرسائل
P2 (متوسط):  سهولة الاستخدام + UI/UX + Localization دقيق
P3 (منخفض):  ميزات متقدمة (مشاركة ملفات، موقع، خريطة الشبكة)
```
