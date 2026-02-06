/// ملف تعريف المسارات (Routes) للتطبيق
class AppRoutes {
  AppRoutes._();

  // شاشة البداية
  static const String splash = '/splash';
  
  // Onboarding
  static const String onboarding = '/onboarding';
  
  // Authentication
  static const String register = '/register';
  static const String lock = '/lock';

  // المسارات الرئيسية
  static const String home = '/home';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String addFriend = '/add_friend';
  
  // Settings sub-routes
  static const String about = '/settings/about';
  static const String privacy = '/settings/privacy';
  
  // Groups routes
  static const String createGroup = '/create_group';
  static const String groups = '/groups';
  static const String groupInfo = '/group_info';
  
  // Mesh Debug route
  static const String meshDebug = '/mesh_debug';

  // المسار الافتراضي (يبدأ من Splash)
  static const String initial = splash;
}

