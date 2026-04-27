# 🔒 Sada — Security Model

> **Version:** 2.0 (Civilian Context)  
> **Last Updated:** 2026-02-25

## نموذج التهديد (Threat Model)

### السياق

صدى هي منصة تواصل مجتمعي لمناطق ذات بنية تحتية ضعيفة. المستخدمون مدنيون عاديون (عائلات، جيران، متطوعون) وليسوا ناشطين تحت رقابة. الخصوصية مبدأ مهني وأخلاقي، وليست آلية حماية من الاضطهاد.

### التهديدات المستهدفة

| التهديد | الاحتمال | التأثير | الحماية |
|---|---|---|---|
| **سرقة/ضياع الجهاز** | عالي | متوسط | PIN Lock + تشفير قاعدة البيانات |
| **اختراق WiFi عشوائي** | متوسط | منخفض | تشفير E2E لمحتوى الرسائل |
| **قراءة عرضية للبيانات** | متوسط | منخفض | SQLCipher للتخزين المحلي |
| **التنصت على الشبكة** | منخفض | منخفض | E2E encryption + authenticated messages |

### التهديدات خارج النطاق

هذه التهديدات **لا** نصمم ضدها (لا نضحي بالموثوقية وسهولة الاستخدام من أجلها):

- هجمات الدولة المتقدمة (Nation-state adversaries)
- التحليل الجنائي المتخصص (Advanced forensic analysis)
- Cold Boot Attacks
- الإكراه الجسدي (Duress scenarios)
- Traffic Analysis المتقدم

---

## بنية التشفير

### التشفير من طرف لطرف (E2E)

```
Key Exchange:     X25519 (Curve25519 ECDH)
KDF:              Blake2b (Generic Hash)
Symmetric Cipher: XSalsa20-Poly1305 (Authenticated Encryption)
Library:          libsodium (sodium_libs)
```

**كيف يعمل:**
1. كل جهاز يُولِّد زوج مفاتيح Curve25519 عند الإعداد الأول
2. المفاتيح العامة تُتبادل عبر مسح QR Code وجهاً لوجه
3. يُشتق Session Key مشترك عبر ECDH + Blake2b
4. كل رسالة تُشفَّر بـ Nonce عشوائي فريد (24 بايت)

### تخزين المفاتيح

| المفتاح | المكان | الحماية |
|---|---|---|
| Private Key | FlutterSecureStorage (Android Keystore) | Hardware-backed encryption |
| Public Key | FlutterSecureStorage | تُشارك عبر QR فقط |
| PIN Hash | FlutterSecureStorage | Argon2id (interactive params) |

### حماية قاعدة البيانات

**الحالي:** SQLite عبر Drift (غير مشفر)  
**المخطط:** الانتقال إلى SQLCipher لتشفير البيانات المخزنة (at-rest encryption)

---

## حماية الجهاز

### App Lock
- PIN مكون من 6 أرقام
- Argon2id لتجزئة الـ PIN (مقاوم لهجمات القوة الغاشمة)
- قفل تصاعدي: 5 محاولات → قفل 60 ثانية، يتصاعد حتى 15 دقيقة
- Biometric unlock (اختياري)

### حماية الإشعارات
- محتوى الرسائل يظهر في الإشعارات (افتراضي — مفيد في سياق الأزمات)
- خيار إخفاء المحتوى متاح في الإعدادات

---

## القيود المعروفة

1. **لا يوجد Forward Secrecy** — نفس Session Key يُستخدم لكل الرسائل بين زوج. مقبول في السياق المدني
2. **Metadata مرئي على الشبكة المحلية** — عناوين الأجهزة مرئية عبر UDP broadcast. مقبول لأن الهدف الاكتشاف وليس الإخفاء
3. **لا يوجد تشفير للنقل (TLS)** — الاعتماد على E2E encryption لحماية المحتوى

---

## الإبلاغ عن ثغرات

إذا وجدت ثغرة أمنية، الرجاء الإبلاغ عبر:
- [GitHub Issues](https://github.com/obadadallo95/sada-messenger/issues) (للثغرات العامة)
- البريد المباشر للمطور (للثغرات الحساسة)
