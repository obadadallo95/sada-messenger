// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'صدى';

  @override
  String get hello => 'مرحباً';

  @override
  String get welcomeMessage => 'مرحباً بك في طبقة الأساس لتطبيق صدى';

  @override
  String get settings => 'الإعدادات';

  @override
  String get theme => 'المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'تلقائي';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get chat => 'الدردشة';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get foundationLayer => 'طبقة الأساس - هندسة واجهة المستخدم';

  @override
  String get skip => 'تخطي';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get onboardingSlide1Title => 'تواصل بلا حدود';

  @override
  String get onboardingSlide1Description =>
      'تواصل مع أحبابك حتى عند انقطاع الإنترنت عبر شبكة Mesh.';

  @override
  String get onboardingSlide2Title => 'أمان مطلق';

  @override
  String get onboardingSlide2Description =>
      'تشفير كامل لرسائلك. لا خوادم مركزية، لا تعقب.';

  @override
  String get onboardingSlide3Title => 'صنع لأجلنا';

  @override
  String get onboardingSlide3Description =>
      'تطبيق مفتوح المصدر، مجاني، ومصمم للواقع السوري.';

  @override
  String get noChats => 'لا توجد محادثات';

  @override
  String get errorLoadingChats => 'حدث خطأ في تحميل المحادثات';

  @override
  String get searchFeatureComingSoon => 'ميزة البحث قريباً';

  @override
  String get online => 'متصل الآن';

  @override
  String get noMessages => 'لا توجد رسائل بعد';

  @override
  String get errorLoadingMessages => 'حدث خطأ في تحميل الرسائل';

  @override
  String get typeMessage => 'اكتب رسالة...';

  @override
  String get yesterday => 'أمس';

  @override
  String daysAgo(int count) {
    return '$count أيام';
  }

  @override
  String get addFriend => 'إضافة صديق';

  @override
  String get myCode => 'رمزي';

  @override
  String get scan => 'مسح';

  @override
  String get userId => 'معرف المستخدم';

  @override
  String get share => 'مشاركة';

  @override
  String get friendFound => 'تم العثور على صديق!';

  @override
  String get newFriend => 'صديق جديد';

  @override
  String get addFriendButton => 'إضافة صديق';

  @override
  String get cameraPermissionDenied => 'تم رفض صلاحية الكاميرا';

  @override
  String get cameraPermissionRequired =>
      'نحتاج إلى صلاحية الكاميرا لمسح رمز QR';

  @override
  String get grantPermission => 'منح الصلاحية';

  @override
  String get placeQrInFrame => 'ضع رمز QR داخل الإطار';

  @override
  String get friendAddedSuccessfully => 'تمت إضافة الصديق بنجاح';

  @override
  String get name => 'الاسم';

  @override
  String get id => 'المعرف';

  @override
  String get simulateMessage => 'محاكاة رسالة';

  @override
  String get simulatingMessage => 'جاري المحاكاة...';

  @override
  String newMessageFrom(String name) {
    return 'رسالة جديدة من $name';
  }

  @override
  String get notificationPermissionRequired =>
      'نحتاج إلى صلاحية الإشعارات لعرض التنبيهات';

  @override
  String get powerUsage => 'استهلاك البطارية';

  @override
  String get disableBatteryOptimization => 'إلغاء تحسين البطارية';

  @override
  String get batteryOptimizationDescription =>
      'لضمان عمل Sada في الخلفية، يرجى إلغاء تحسين البطارية من إعدادات النظام';

  @override
  String get couldNotOpenSettings => 'تعذر فتح الإعدادات';

  @override
  String get serviceActive => 'Sada نشط';

  @override
  String get serviceScanning => 'Sada: جاري المسح...';

  @override
  String get serviceSleeping => 'Sada: نائم';

  @override
  String get appearance => 'المظهر';

  @override
  String get performance => 'الأداء';

  @override
  String get aboutAndLegal => 'حول التطبيق';

  @override
  String get aboutUs => 'حولنا';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get openSourceLicenses => 'تراخيص مفتوحة المصدر';

  @override
  String get version => 'الإصدار';

  @override
  String get aboutDescription =>
      'Sada هو تطبيق مراسلة شبكة Mesh مفتوح المصدر، مجاني، ومصمم للواقع السوري. يتيح التواصل حتى عند انقطاع الإنترنت عبر شبكة Mesh لاسلكية.';

  @override
  String get website => 'الموقع';

  @override
  String get madeWithLove => 'صُنع بـ ❤️ من أجل سوريا';

  @override
  String get lastUpdated => 'آخر تحديث: يناير 2024';

  @override
  String get noDataCollection => 'لا جمع للبيانات';

  @override
  String get noDataCollectionDescription =>
      'نحن لا نجمع أو نخزن أي بيانات شخصية على خوادمنا. جميع البيانات تبقى محلية على جهازك فقط.';

  @override
  String get localStorage => 'التخزين المحلي';

  @override
  String get localStorageDescription =>
      'جميع رسائلك ومحادثاتك مخزنة محلياً على جهازك. لا يتم إرسال أي بيانات إلى خوادم خارجية.';

  @override
  String get encryption => 'التشفير';

  @override
  String get encryptionDescription =>
      'جميع الرسائل مشفرة من طرف إلى طرف (E2E). حتى لو تم اعتراض الرسائل، لا يمكن قراءتها بدون المفاتيح الخاصة.';

  @override
  String get meshNetworking => 'شبكة Mesh';

  @override
  String get meshNetworkingDescription =>
      'Sada يستخدم تقنية Mesh Networking للتواصل مباشرة بين الأجهزة بدون الحاجة لخوادم مركزية أو اتصال بالإنترنت.';

  @override
  String get openSource => 'مفتوح المصدر';

  @override
  String get openSourceDescription =>
      'Sada هو مشروع مفتوح المصدر. يمكنك مراجعة الكود المصدري على GitHub والمساهمة في تطويره.';

  @override
  String get exitMessage => 'اضغط مرة أخرى للخروج';

  @override
  String get createIdentity => 'أنشئ هويتك';

  @override
  String get identityInfo =>
      'يتم توليد هويتك من التوقيع الفريد لهذا الجهاز. لا حاجة لرقم هاتف.';

  @override
  String get nickname => 'الاسم المستعار';

  @override
  String get nicknameHint => 'أدخل اسمك المستعار';

  @override
  String get nicknameRequired => 'الاسم المستعار مطلوب';

  @override
  String get nicknameTooShort =>
      'الاسم المستعار قصير جداً (يجب أن يكون حرفين على الأقل)';

  @override
  String get enterSada => 'دخول Sada';

  @override
  String get securityNote =>
      'هويتك مرتبطة بهذا الجهاز فقط. لا يتم إرسال أي بيانات إلى خوادم خارجية.';

  @override
  String get registrationFailed => 'فشل التسجيل. يرجى المحاولة مرة أخرى.';

  @override
  String get privacyAndSecurity => 'الخصوصية والأمان';

  @override
  String get appLock => 'قفل التطبيق';

  @override
  String get appLockDescription => 'طلب البصمة عند فتح التطبيق';

  @override
  String get sadaIsLocked => 'تطبيق صدى مقفل';

  @override
  String get unlockToContinue => 'استخدم البصمة لفتح التطبيق';

  @override
  String get unlock => 'افتح القفل';

  @override
  String get scanFingerprintToEnter => 'امسح بصمتك للدخول إلى Sada';

  @override
  String get authenticationFailed => 'فشلت المصادقة';

  @override
  String get biometricNotAvailable => 'البصمة غير متاحة على هذا الجهاز';

  @override
  String get failedToChangeLock => 'فشل تغيير حالة القفل';

  @override
  String get createCommunity => 'إنشاء مجتمع';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String get groupNameHint => 'أدخل اسم المجموعة';

  @override
  String get groupNameRequired => 'اسم المجموعة مطلوب';

  @override
  String get groupNameTooShort =>
      'اسم المجموعة قصير جداً (يجب أن يكون 3 أحرف على الأقل)';

  @override
  String get groupDescription => 'وصف المجموعة';

  @override
  String get groupDescriptionHint => 'أدخل وصفاً للمجموعة';

  @override
  String get groupDescriptionRequired => 'وصف المجموعة مطلوب';

  @override
  String get publicGroup => 'مجموعة عامة';

  @override
  String get publicGroupDescription =>
      'يمكن لأي شخص في المنطقة اكتشاف المجموعة والانضمام إليها';

  @override
  String get privateGroupDescription =>
      'المجموعة خاصة وتتطلب كلمة مرور للانضمام';

  @override
  String get groupPassword => 'كلمة المرور';

  @override
  String get groupPasswordHint => 'أدخل كلمة المرور';

  @override
  String get groupPasswordRequired => 'كلمة المرور مطلوبة للمجموعات الخاصة';

  @override
  String get launchGroup => 'إطلاق المجموعة';

  @override
  String get myGroups => 'مجموعاتي';

  @override
  String get nearbyCommunities => 'المجتمعات القريبة';

  @override
  String peersNearby(int count) {
    return '$count أقران قريبين';
  }

  @override
  String get join => 'انضم';

  @override
  String get scanning => 'جارٍ المسح...';

  @override
  String get enterPin => 'أدخل PIN';

  @override
  String get changeMasterPin => 'تغيير Master PIN';

  @override
  String get setDuressPin => 'تعيين Duress PIN';

  @override
  String get duressPinWarning =>
      'استخدم هذا PIN فقط في حالة الخطر. سيخفي بياناتك الحقيقية ويعرض بيانات وهمية.';

  @override
  String get enterMasterPin => 'أدخل Master PIN';

  @override
  String get enterDuressPin => 'أدخل Duress PIN';

  @override
  String get confirmPin => 'تأكيد PIN';

  @override
  String get pinMismatch => 'PIN غير متطابق';

  @override
  String get pinSetSuccessfully => 'تم تعيين PIN بنجاح';

  @override
  String get pinChangedSuccessfully => 'تم تغيير PIN بنجاح';

  @override
  String get yourIdentity => 'هويتك';

  @override
  String get yourIdentityDescription =>
      'اضغط لعرض رمز QR الخاص بك والملف الشخصي';

  @override
  String get startConnecting => 'ابدأ الاتصال';

  @override
  String get startConnectingDescription =>
      'اضغط هنا للبحث عن الأجهزة القريبة أو إنشاء مجموعة';

  @override
  String get leadDeveloper => 'المطور الرئيسي';

  @override
  String get founder => 'المؤسس';

  @override
  String get shareAppOffline => 'شارك التطبيق';

  @override
  String get shareAppOfflineDescription =>
      'إرسال ملف APK عبر البلوتوث أو تطبيقات المشاركة';

  @override
  String get preparingApk => 'جاري تحضير ملف APK...';

  @override
  String get apkShareSuccess => 'تم فتح شاشة المشاركة بنجاح';

  @override
  String get apkShareError => 'فشل مشاركة ملف APK';
}
