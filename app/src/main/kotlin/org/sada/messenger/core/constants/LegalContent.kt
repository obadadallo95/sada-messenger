package org.sada.messenger.core.constants

object LegalContent {
    fun about(isArabic: Boolean): String {
        return if (isArabic) {
            """
صدى (Sada) هو تطبيق مراسلة شبكي لا مركزي يعمل بدون إنترنت.

الفكرة الأساسية:
- كل هاتف يعمل كعقدة في الشبكة.
- الرسائل تنتقل بنمط Store-Carry-Forward.
- التشفير من طرف إلى طرف يمنع قراءة المحتوى من أي وسيط.

ما الذي يميز صدى:
- يعمل في البيئات الضعيفة أو المنقطعة.
- لا يعتمد على خوادم مركزية للرسائل.
- يدعم الخصوصية أولاً مع مفاتيح محلية وتخزين محلي.

الإصدار الحالي:
- Android Native Build
- مصمم للاتصالات الميدانية والمرونة التشغيلية.
            """.trimIndent()
        } else {
            """
Sada is a decentralized mesh messenger designed to work without the internet.

Core model:
- Each phone acts as a network node.
- Messages follow Store-Carry-Forward routing.
- End-to-end encryption protects message content from intermediaries.

Why Sada:
- Works in low-connectivity or blackout conditions.
- No dependency on central messaging servers.
- Privacy-first architecture with local keys and local storage.

Current build:
- Android Native Build
- Built for field resilience and operational continuity.
            """.trimIndent()
        }
    }

    fun privacyPolicy(isArabic: Boolean): String {
        return if (isArabic) {
            """
سياسة الخصوصية

آخر تحديث: 2026-02-26

1) جمع البيانات
- لا نجمع رسائلك أو جهات الاتصال أو محتوى محادثاتك.
- لا توجد خوادم مركزية لتخزين الميتاداتا الخاصة بالمراسلة.

2) التشفير
- الرسائل تُشفّر من طرف إلى طرف.
- الأجهزة الوسيطة تنقل الحزم المشفرة فقط ولا تستطيع قراءتها.

3) التخزين
- البيانات الحساسة محفوظة محلياً على جهازك.
- مفاتيح التشفير تبقى على جهازك.

4) التحكم
- يمكنك تفعيل قفل التطبيق ورمز PIN.
- يمكنك حذف البيانات المحلية من جهازك.

5) الشفافية
- صدى مبني بفلسفة صفر-ثقة مع هندسة لا مركزية.
            """.trimIndent()
        } else {
            """
Privacy Policy

Last Updated: 2026-02-26

1) Data collection
- We do not collect your messages, contacts, or chat content.
- No central messaging servers are used to store mesh metadata.

2) Encryption
- Messages are end-to-end encrypted.
- Intermediate devices only carry encrypted packets and cannot read them.

3) Storage
- Sensitive data is stored locally on your device.
- Encryption keys remain on your device.

4) User control
- You can enable app lock and PIN protection.
- You can remove local app data from your device.

5) Transparency
- Sada follows a zero-trust, decentralized architecture.
            """.trimIndent()
        }
    }

    fun termsOfUse(isArabic: Boolean): String {
        return if (isArabic) {
            """
شروط الاستخدام

آخر تحديث: 2026-02-26

1) طبيعة التطبيق
- صدى برنامج اتصالات لا مركزي وقد يتأثر بجودة البيئة اللاسلكية.

2) الاستخدام المسموح
- للاستخدام القانوني والمسؤول فقط.
- يمنع أي استخدام يسبب ضرراً أو إساءة أو نشاطاً غير قانوني.

3) حدود الضمان
- التطبيق يقدم "كما هو" دون ضمان مطلق لوصول الرسائل.
- المطور غير مسؤول عن أي خسائر ناتجة عن سوء الاستخدام أو ظروف خارجية.

4) الأمن التشغيلي
- المستخدم مسؤول عن حماية جهازه ورموزه السرية.
- المستخدم مسؤول عن إدارة النسخ الاحتياطي المناسبة لبياناته.

5) التعديلات
- قد يتم تحديث الشروط لاحقاً، واستمرار الاستخدام يعني قبول التحديثات.
            """.trimIndent()
        } else {
            """
Terms of Use

Last Updated: 2026-02-26

1) App nature
- Sada is a decentralized communication app and depends on wireless conditions.

2) Allowed use
- Legal and responsible use only.
- Any abusive, harmful, or illegal use is prohibited.

3) Warranty limits
- The app is provided "as is" with no absolute delivery guarantee.
- The developer is not liable for losses caused by misuse or external conditions.

4) Operational security
- Users are responsible for securing devices and secret credentials.
- Users are responsible for their own backup strategy.

5) Changes
- Terms may be updated over time; continued use implies acceptance.
            """.trimIndent()
        }
    }
}
