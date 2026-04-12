# دليل البدء السريع - مشروع صدى

## ⚡ في 5 دقائق

### 1. متطلبات النظام
```bash
- Android Studio Hedgehog (2023.1.1) أو أحدث
- JDK 21
- Android SDK 35
- جهاز Android حقيقي (الإmulator لا يدعم Wi-Fi Direct)
```

### 2. بناء المشروع
```bash
git clone [repo-url]
cd sada
./gradlew :app:assembleDebug
```

### 3. تثبيت على الجهاز
```bash
adb install app/build/outputs/apk/debug/app-debug.apk
# أو
./gradlew :app:installDebug
```

---

## 🗺️ فهم بنية المشروع

### البداية: MainActivity.kt
```kotlin
// MainActivity.kt: نقطة الدخول الرئيسية
- تهيئة MeshEngine
- إعداد NavHost للتنقل
- طلب الصلاحيات
- تسجيل Wi-Fi P2P Receiver
```

### العمود الفقري: MeshEngine.kt
```kotlin
// MeshEngine.kt: قلب التطبيق
- إدارة الاتصالات (Wi-Fi/BLE/LoRa)
- توجيه الرسائل (Routing)
- Handshake و ACK
- Epidemic Gossip
```

### قاعدة البيانات: AppDatabase.kt
```
// الجداول الرئيسية:
- contacts: جهات الاتصال
- chats: المحادثات والمجموعات
- messages: الرسائل
- relay_queue: الرسائل المُرحلة
- group_members: أعضاء المجموعات
```

---

## 🎯 تعديل سريع

### إضافة Screen جديدة:
```kotlin
// 1. أنشئ الملف في ui/screens/
ui/screens/NewScreen.kt

// 2. أضف الـ Route في MainActivity.kt
composable("new_screen") {
    NewScreen(onBack = { navController.popBackStack() })
}

// 3. أضف زر التنقل (من أي screen)
Button(onClick = { navController.navigate("new_screen") }) {
    Text("Go to New Screen")
}
```

### تعديل لون التطبيق:
```kotlin
// ui/theme/Theme.kt
val SadaPrimary = Color(0xFF00D1C1)      // Teal
val SadaBackground = Color(0xFF0A1628)  // Dark blue
val SadaSurface = Color(0xFF111B2B)      // Lighter blue
```

### إضافة لغة جديدة:
```xml
<!-- res/values/strings.xml (English) -->
<string name="app_name">Sada</string>

<!-- res/values-ar/strings.xml (Arabic) -->
<string name="app_name">صدى</string>
```

---

## 🔧 أهم الدوال للتخصيص

### إرسال رسالة:
```kotlin
// في ChatViewModel.kt
fun sendMessage(content: String) {
    // 1. تشفير الرسالة
    val encrypted = encryptionManager.encryptMessage(content, sharedSecret)
    
    // 2. إنشاء MeshMessage
    val meshMessage = MeshMessage(...)
    
    // 3. إرسال عبر MeshEngine
    meshEngine.sendMeshMessage(meshMessage)
}
```

### إنشاء مجموعة:
```kotlin
// في HomeViewModel.kt
fun createGroup(name: String, isPublic: Boolean, ...) {
    // 1. توليد مفتاح المجموعة
    val groupKey = meshEngine.generateGroupKey()
    
    // 2. حفظ في Database
    database.chatDao().insertChat(chat)
    
    // 3. إعلان المجموعة (إذا عامة)
    if (isPublic) {
        meshEngine.announcePublicGroup(chat)
    }
}
```

---

## 🐛 تصحيح الأخطاء الشائعة

### المشكلة: "Wi-Fi P2P لا يعمل"
```
الحل:
1. تأكد أن الجهاز حقيقي (لا يعمل على Emulator)
2. تأكد من صلاحية LOCATION
3. تأكد أن Wi-Fi مفعل
4. راجع MeshDiagnosticsScreen
```

### المشكلة: "BLE لا يكتشف أجهزة"
```
الحل:
1. تأكد من صلاحيات BLUETOOTH_SCAN و BLUETOOTH_CONNECT
2. تأكد أن Bluetooth مفعل
3. جرب on/off للـ Bluetooth
4. افحص BleMeshManager logs
```

### المشكلة: "الرسائل لا تُرسل"
```
الحل:
1. تأكد من handshake (هل الأقران متصلون؟)
2. راجع MeshDiagnostics → Handshake Stats
3. تأكد من أن الطرف الآخر ليس blocked
4. افحص logs: `adb logcat -s MeshEngine:D`
```

---

## 📚 أهم الملفات للقراءة

| الملف | الغرض | الأولوية |
|-------|-------|----------|
| `MeshEngine.kt` | قلب الشبكة | 🔴 عالية |
| `ChatScreen.kt` | واجهة الدردشة | 🔴 عالية |
| `HomeScreen.kt` | الشاشة الرئيسية | 🟡 متوسطة |
| `BleMeshManager.kt` | Bluetooth Low Energy | 🔴 عالية |
| `KeyManager.kt` | توليد وإدارة المفاتيح | 🔴 عالية |
| `EncryptionManager.kt` | تشفير/فك تشفير | 🔴 عالية |

---

## 🧪 اختبار سريع

### اختبار 2 أجهزة:
```
1. شغّل التطبيق على جهازين
2. افتح MyQR على الجهاز الأول
3. افتح Add Contact على الجهاز الثاني
4. امسح QR code
5. أرسل رسالة من الجهاز الأول
6. تأكد من وصولها للجهاز الثاني
```

### اختبار الـ Mesh:
```
1. شغّل 3 أجهزة (A, B, C)
2. ضع A و B قريبين (متصلين)
3. ضع B و C قريبين (متصلين)
4. ابعد A عن C (غير متصلين مباشرة)
5. أرسل رسالة من A إلى C
6. يجب أن تمر عبر B (multi-hop)
```

---

## 🔗 روابط مفيدة

- **docs/ARCHITECTURE.md** - بنية النظام
- **docs/TRANSPORT_AND_ROUTING.md** - بروتوكولات النقل
- **docs/SECURITY_AND_PRIVACY.md** - نموذج الأمان
- **docs/PROJECT_SUMMARY_v1.0.md** - ملخص شامل

---

## 💡 نصائح للمطورين

1. **استخدم جهاز حقيقي** - الـ Emulator لا يدعم Wi-Fi Direct
2. **شغّل 2-3 أجهزة** - للاختبار الحقيقي للـ Mesh
3. **راجع Logs** - `adb logcat -s MeshEngine:D`
4. **افحص Diagnostics** - شاشة التشخيص مفيدة جداً
5. **جرب Offline** - أغلق Wi-Fi/4G واختبر

---

**استفسارات؟** افتح Issue في GitHub

**سعيد بالبرمجة! 🚀**
