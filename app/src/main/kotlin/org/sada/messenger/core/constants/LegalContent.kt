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

    fun intellectualProperty(isArabic: Boolean): String {
        return if (isArabic) {
            """
حقوق الملكية الفكرية وشروط الاستخدام

آخر تحديث: أبريل 2026
جميع الحقوق محفوظة © 2026 — عبادة دللو

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1) الملكية الفكرية
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

جميع حقوق الملكية الفكرية المتعلقة بتطبيق "صدى" (Sada)، بما تشمل:
- الكود المصدري (Source Code)
- التصميم البصري وهوية الواجهة
- البنية التقنية ونماذج التشبيك اللامركزي
- الوثائق والمحتوى الأدبي المرفق
- الشعارات والعلامات التجارية

... هي ملكية حصرية لـ عبادة دللو (Obada Dallo).

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2) رخصة الاستخدام
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

يُمنح المستخدم ترخيصاً شخصياً غير تجاري لاستخدام التطبيق وفق الشروط التالية:

✅ مسموح به:
- استخدام التطبيق للاتصالات الشخصية والميدانية.
- مشاركة التطبيق مع أفراد آخرين دون تعديل.
- الاطلاع على الكود المصدري للأغراض التعليمية فقط.

🚫 ممنوع دون إذن كتابي مسبق:
- نسخ أو توزيع أو بيع التطبيق أو الكود بشكل تجاري.
- إنشاء مشاريع مشتقة (Fork) للنشر العلني.
- إزالة إشعارات حقوق الملكية أو نسب العمل.
- استخدام الكود أو التصميم في منتج أو خدمة أخرى.
- العكسية الهندسية (Reverse Engineering) بغرض تجاري.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3) المكونات مفتوحة المصدر
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

يستخدم هذا التطبيق مكتبات مفتوحة المصدر خاضعة لرخصها الخاصة:
- Jetpack Compose — Apache License 2.0
- Room Database — Apache License 2.0
- ZXing QR Code — Apache License 2.0
- Material Design 3 — Apache License 2.0
- Kotlin / Coroutines — Apache License 2.0

لا تمتد حقوق مالك التطبيق لتشمل هذه المكونات.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4) إخلاء المسؤولية
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- التطبيق مقدم "كما هو" دون أي ضمان صريح أو ضمني.
- المالك غير مسؤول عن أي ضرر مباشر أو غير مباشر ناتج عن الاستخدام.
- المستخدم يتحمل كامل المسؤولية عن أي استخدام مخالف للقوانين المحلية.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5) التواصل وطلب الأذونات
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

لطلب ترخيص تجاري أو الاستفسار عن الاستخدام:
البريد الإلكتروني: obada.dallo95@gmail.com
GitHub: github.com/obadadallo95

            """.trimIndent()
        } else {
            """
Intellectual Property & Usage Rights

Last Updated: April 2026
All Rights Reserved © 2026 — Obada Dallo

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1) Intellectual Property Ownership
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All intellectual property rights related to the "Sada" application, including but not limited to:
- Source code
- Visual design and UI identity
- Technical architecture and decentralized networking models
- Documentation and literary content
- Logos and trademarks

... are the exclusive property of Obada Dallo (عبادة دللو).

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2) License Grant
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Users are granted a personal, non-commercial license to use the application under the following conditions:

✅ Permitted:
- Using the application for personal and field communications.
- Sharing the application with others without modification.
- Viewing the source code for educational purposes only.

🚫 Prohibited without prior written permission:
- Copying, distributing, or selling the application or source code commercially.
- Creating derivative works (Forks) for public release.
- Removing copyright notices or attribution.
- Using the code or design in any other product or service.
- Reverse engineering for commercial purposes.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3) Open Source Components
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This application uses open-source libraries governed by their own licenses:
- Jetpack Compose — Apache License 2.0
- Room Database — Apache License 2.0
- ZXing QR Code — Apache License 2.0
- Material Design 3 — Apache License 2.0
- Kotlin / Coroutines — Apache License 2.0

The owner's rights do not extend to these components.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4) Disclaimer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- The application is provided "as is" without any express or implied warranty.
- The owner is not liable for any direct or indirect damage resulting from use.
- Users bear full responsibility for any use that violates local laws.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5) Contact & Permission Requests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For commercial licensing or usage inquiries:
Email: obada.dallo95@gmail.com
GitHub: github.com/obadadallo95

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
