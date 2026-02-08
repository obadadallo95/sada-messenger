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
  String get home => 'الرئيسية';

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
  String get addFriend => 'Add Friend';

  @override
  String get myCode => 'My Code';

  @override
  String get scan => 'Scan';

  @override
  String get userId => 'User ID';

  @override
  String get share => 'Share';

  @override
  String get friendFound => 'Friend Found';

  @override
  String get newFriend => 'New Friend';

  @override
  String get addFriendButton => 'Add Friend';

  @override
  String get cameraPermissionDenied => 'Camera permission denied';

  @override
  String get cameraPermissionRequired => 'Camera permission is required';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get placeQrInFrame => 'Place QR code in the frame';

  @override
  String get friendAddedSuccessfully => 'Friend added successfully';

  @override
  String get name => 'Name';

  @override
  String get id => 'ID';

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
  String get createCommunity => 'Create Community';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupNameHint => 'Enter group name';

  @override
  String get groupNameRequired => 'Group name is required';

  @override
  String get groupNameTooShort => 'Group name is too short';

  @override
  String get groupDescription => 'Description';

  @override
  String get groupDescriptionHint => 'Enter group description';

  @override
  String get groupDescriptionRequired => 'Description is required';

  @override
  String get publicGroup => 'Public Group';

  @override
  String get publicGroupDescription => 'Visible to everyone nearby';

  @override
  String get privateGroupDescription => 'Requires password to join';

  @override
  String get groupPassword => 'Password';

  @override
  String get groupPasswordHint => 'Enter password';

  @override
  String get groupPasswordRequired => 'Password is required';

  @override
  String get launchGroup => 'Launch Group';

  @override
  String get myGroups => 'My Groups';

  @override
  String get nearbyCommunities => 'Nearby Communities';

  @override
  String peersNearby(int count) {
    return '$count peers nearby';
  }

  @override
  String get join => 'انضم';

  @override
  String get scanning => 'Scanning...';

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

  @override
  String get notifications => 'الإشعارات';

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get markAllAsRead => 'تعليم الكل كمقروء';

  @override
  String get noInternetNoProblem => 'لا إنترنت؟\nلا مشكلة.';

  @override
  String get noInternetDescription =>
      'يعمل صدى عندما ينقطع الإنترنت. تواصل مباشرة مع من حولك باستخدام WiFi Direct.';

  @override
  String get youAreTheNetwork => 'أنت الشبكة';

  @override
  String get youAreTheNetworkDescription =>
      'هاتفك يعمل كجسر. ساعد مجتمعك على البقاء متصلاً بمجرد إبقاء التطبيق مفتوحاً.';

  @override
  String get invisibleAndSecure => 'غير مرئي وآمن';

  @override
  String get invisibleAndSecureDescription =>
      'لا خوادم. لا تعقب. رسائلك تبقى في حيّك.';

  @override
  String get readyToConnect => 'جاهز للاتصال؟';

  @override
  String get readyToConnectDescription =>
      'امنح الصلاحيات للبدء باكتشاف الأشخاص القريبين.';

  @override
  String get permissionLocation => 'الموقع';

  @override
  String get permissionNotify => 'إشعارات';

  @override
  String get permissionWifi => 'WiFi';

  @override
  String get zeroKnowledgePromise => 'وعد المعرفة الصفرية';

  @override
  String get noPhoneNumberRequired => 'لا حاجة لرقم هاتف';

  @override
  String get noPhoneNumberDescription =>
      'لا نطلب رقم هاتفك أو بريدك الإلكتروني. أنت مجرد مفتاح تشفير.';

  @override
  String get endToEndEncryptionDescription =>
      'جميع الرسائل مشفرة على جهازك ويتم فك تشفيرها فقط عند المستلم.';

  @override
  String get localDatabaseOnly => 'قاعدة بيانات محلية فقط';

  @override
  String get localDatabaseDescription =>
      'بياناتك تعيش على هاتفك. لا يوجد نسخ احتياطي سحابي. إذا حذفت التطبيق، ستضيع بياناتك للأبد.';

  @override
  String get transparency => 'الشفافية';

  @override
  String get transparencyDescription =>
      'يستخدم صدى تقنيات قياسية مثل WiFi Direct و UDP. بينما يعلن جهازك عن وجوده، تبقى هويتك الحقيقية مخفية.';

  @override
  String get viewSourceCode => 'عرض الكود المصدري';

  @override
  String get howItWorks => 'كيف يعمل';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get scanQrDescription =>
      'قابل صديقاً وامسح رمزه لتبادل المفاتيح بأمان.';

  @override
  String get autoConnect => 'اتصال تلقائي';

  @override
  String get autoConnectDescription =>
      'تجد أجهزتكم بعضها تلقائياً عبر WiFi Direct.';

  @override
  String get secureChat => 'محادثة آمنة';

  @override
  String get secureChatDescription =>
      'تنتقل الرسائل بين الأجهزة حتى تصل لوجهتها.';

  @override
  String get designedForResilience => 'صُمم للصمود';

  @override
  String get shareQrCodeDescription => 'شارك هذا الرمز لإضافتك كجهة اتصال';

  @override
  String get myQrCode => 'My QR Code';

  @override
  String get contactAlreadyExists => 'Contact already exists';

  @override
  String get errorProcessingQrCode => 'Error processing QR Code';

  @override
  String get cannotAddYourself => 'You cannot add yourself';

  @override
  String get processing => 'Processing...';

  @override
  String get qrCodeSecurityInfo =>
      'يحتوي هذا الرمز على مفتاحك العام للمراسلة الآمنة.';
}
