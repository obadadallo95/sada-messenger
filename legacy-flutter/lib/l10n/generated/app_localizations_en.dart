// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sada';

  @override
  String get hello => 'Hello';

  @override
  String get welcomeMessage => 'Welcome to Sada Foundation Layer';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get chat => 'Chat';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get foundationLayer => 'Foundation Layer - UI/UX Architecture';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingSlide1Title => 'Connect Without Limits';

  @override
  String get onboardingSlide1Description =>
      'Connect with your loved ones even when the internet is down through Mesh network.';

  @override
  String get onboardingSlide2Title => 'Absolute Security';

  @override
  String get onboardingSlide2Description =>
      'Full encryption for your messages. No central servers, no tracking.';

  @override
  String get onboardingSlide3Title => 'Made for Us';

  @override
  String get onboardingSlide3Description =>
      'Open source app, free, and designed for the Syrian reality.';

  @override
  String get noChats => 'No chats';

  @override
  String get errorLoadingChats => 'Error loading chats';

  @override
  String get searchFeatureComingSoon => 'Search feature coming soon';

  @override
  String get online => 'Online';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get errorLoadingMessages => 'Error loading messages';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
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
  String get simulateMessage => 'Simulate Message';

  @override
  String get simulatingMessage => 'Simulating...';

  @override
  String newMessageFrom(String name) {
    return 'New message from $name';
  }

  @override
  String get notificationPermissionRequired =>
      'We need notification permission to show alerts';

  @override
  String get powerUsage => 'Power Usage';

  @override
  String get disableBatteryOptimization => 'Disable Battery Optimization';

  @override
  String get batteryOptimizationDescription =>
      'To ensure Sada works in the background, please disable battery optimization from system settings';

  @override
  String get couldNotOpenSettings => 'Could not open settings';

  @override
  String get serviceActive => 'Sada is active';

  @override
  String get serviceScanning => 'Sada: Scanning...';

  @override
  String get serviceSleeping => 'Sada: Sleeping';

  @override
  String get appearance => 'Appearance';

  @override
  String get performance => 'Performance';

  @override
  String get aboutAndLegal => 'About & Legal';

  @override
  String get aboutUs => 'About Us';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get version => 'Version';

  @override
  String get aboutDescription =>
      'Sada is an open-source, free, offline mesh messaging application designed for the Syrian reality. It enables communication even when the internet is cut off through a wireless Mesh network.';

  @override
  String get website => 'Website';

  @override
  String get madeWithLove => 'Made with ❤️ for Syria';

  @override
  String get lastUpdated => 'Last updated: January 2024';

  @override
  String get noDataCollection => 'No Data Collection';

  @override
  String get noDataCollectionDescription =>
      'We do not collect or store any personal data on our servers. All data remains local on your device only.';

  @override
  String get localStorage => 'Local Storage';

  @override
  String get localStorageDescription =>
      'All your messages and conversations are stored locally on your device. No data is sent to external servers.';

  @override
  String get encryption => 'Encryption';

  @override
  String get encryptionDescription =>
      'All messages are end-to-end encrypted (E2E). Even if messages are intercepted, they cannot be read without the private keys.';

  @override
  String get meshNetworking => 'Mesh Networking';

  @override
  String get meshNetworkingDescription =>
      'Sada uses Mesh Networking technology to communicate directly between devices without the need for central servers or internet connection.';

  @override
  String get openSource => 'Open Source';

  @override
  String get openSourceDescription =>
      'Sada is an open-source project. You can review the source code on GitHub and contribute to its development.';

  @override
  String get exitMessage => 'Press back again to exit';

  @override
  String get createIdentity => 'Create Your Identity';

  @override
  String get identityInfo =>
      'Your identity is generated from this device\'s unique signature. No phone number required.';

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameHint => 'Enter your nickname';

  @override
  String get nicknameRequired => 'Nickname is required';

  @override
  String get nicknameTooShort =>
      'Nickname is too short (must be at least 2 characters)';

  @override
  String get enterSada => 'Enter Sada';

  @override
  String get securityNote =>
      'Your identity is bound to this device only. No data is sent to external servers.';

  @override
  String get registrationFailed => 'Registration failed. Please try again.';

  @override
  String get privacyAndSecurity => 'Privacy & Security';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockDescription => 'Require fingerprint to open';

  @override
  String get sadaIsLocked => 'Sada is Locked';

  @override
  String get unlockToContinue => 'Use your fingerprint to unlock the app';

  @override
  String get unlock => 'Unlock';

  @override
  String get scanFingerprintToEnter => 'Scan your fingerprint to enter Sada';

  @override
  String get authenticationFailed => 'Authentication failed';

  @override
  String get biometricNotAvailable =>
      'Biometric authentication is not available on this device';

  @override
  String get failedToChangeLock => 'Failed to change lock status';

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
  String get join => 'Join';

  @override
  String get scanning => 'Scanning...';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get changeMasterPin => 'Change Master PIN';

  @override
  String get setDuressPin => 'Set Duress PIN';

  @override
  String get duressPinWarning =>
      'Use this PIN only in danger. It will hide your real data and show fake data.';

  @override
  String get enterMasterPin => 'Enter Master PIN';

  @override
  String get enterDuressPin => 'Enter Duress PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get pinMismatch => 'PIN mismatch';

  @override
  String get pinSetSuccessfully => 'PIN set successfully';

  @override
  String get pinChangedSuccessfully => 'PIN changed successfully';

  @override
  String get yourIdentity => 'Your Identity';

  @override
  String get yourIdentityDescription => 'Tap to view your QR code and profile';

  @override
  String get startConnecting => 'Start Connecting';

  @override
  String get startConnectingDescription =>
      'Tap here to search for nearby devices or create a group';

  @override
  String get leadDeveloper => 'Lead Developer';

  @override
  String get founder => 'Founder';

  @override
  String get shareAppOffline => 'Share App Offline';

  @override
  String get shareAppOfflineDescription =>
      'Send APK file via Bluetooth or sharing apps';

  @override
  String get preparingApk => 'Preparing APK file...';

  @override
  String get apkShareSuccess => 'Share sheet opened successfully';

  @override
  String get apkShareError => 'Failed to share APK file';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get noInternetNoProblem => 'No Internet?\nNo Problem.';

  @override
  String get noInternetDescription =>
      'Sada works when the internet doesn\'t. Connect directly with people around you using WiFi Direct.';

  @override
  String get youAreTheNetwork => 'You Are The Network';

  @override
  String get youAreTheNetworkDescription =>
      'Your phone acts as a bridge. Help your community stay connected just by keeping the app open.';

  @override
  String get invisibleAndSecure => 'Invisible & Secure';

  @override
  String get invisibleAndSecureDescription =>
      'No servers. No tracking. Your messages stay in your neighborhood.';

  @override
  String get readyToConnect => 'Ready to Connect?';

  @override
  String get readyToConnectDescription =>
      'Grant permissions to start discovering people nearby.';

  @override
  String get permissionLocation => 'Location';

  @override
  String get permissionNotify => 'Notify';

  @override
  String get permissionWifi => 'WiFi';

  @override
  String get zeroKnowledgePromise => 'Zero-Knowledge Promise';

  @override
  String get noPhoneNumberRequired => 'No Phone Number Required';

  @override
  String get noPhoneNumberDescription =>
      'We don\'t ask for your phone number, email, or real identity. You are just a cryptographic key pair.';

  @override
  String get endToEndEncryptionDescription =>
      'All messages are encrypted on your device and only decrypted by the recipient. We cannot read your chats.';

  @override
  String get localDatabaseOnly => 'Local Database Only';

  @override
  String get localDatabaseDescription =>
      'Your data lives on your phone. There is no cloud backup. If you delete the app, your data is gone forever.';

  @override
  String get transparency => 'Transparency';

  @override
  String get transparencyDescription =>
      'Sada uses standard WiFi Direct and UDP broadcasts to find peers. While your device announces its presence, your real identity remains hidden behind a random ID.';

  @override
  String get viewSourceCode => 'View Source Code';

  @override
  String get howItWorks => 'How it Works';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get scanQrDescription =>
      'Meet a friend and scan their QR code to swap keys securely.';

  @override
  String get autoConnect => 'Auto Connect';

  @override
  String get autoConnectDescription =>
      'Your devices automatically find each other over WiFi Direct.';

  @override
  String get secureChat => 'Secure Chat';

  @override
  String get secureChatDescription =>
      'Messages hop between devices until they reach the destination.';

  @override
  String get designedForResilience => 'Designed for Resilience';

  @override
  String get shareQrCodeDescription =>
      'Share this QR code to add you as a contact';

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
      'This QR code contains your public key for secure messaging.';

  @override
  String get navigation_home => 'Home';

  @override
  String get navigation_chat => 'Chats';

  @override
  String get navigation_communities => 'Communities';

  @override
  String get navigation_add => 'Add';

  @override
  String get navigation_settings => 'Settings';

  @override
  String get home_title => 'Local Network';

  @override
  String get home_status_connected => 'Connected';

  @override
  String get home_status_connecting => 'Connecting...';

  @override
  String get home_status_offline => 'Offline';

  @override
  String home_peers_count(int count) {
    return '$count devices connected';
  }

  @override
  String get home_empty_title => 'Your Network is Ready';

  @override
  String get home_empty_subtitle =>
      'Wait for nearby devices or start a new conversation';

  @override
  String get home_empty_action => 'Start Chat';

  @override
  String get chat_empty_title => 'No Conversations';

  @override
  String get chat_empty_subtitle =>
      'Start a secure, encrypted conversation with your friends';

  @override
  String get chat_empty_action => 'Add Friend';

  @override
  String get communities_empty_title => 'No Communities';

  @override
  String get communities_empty_subtitle =>
      'Discover groups in your area or create a new community';

  @override
  String get communities_empty_action => 'Create Community';

  @override
  String get communities_create_button => 'New Community';

  @override
  String get qr_title => 'Share Code';

  @override
  String get qr_my_code => 'My Code';

  @override
  String get qr_scan => 'Scan Code';

  @override
  String get qr_share_title => 'Share via';

  @override
  String get qr_copy_id => 'Copy ID';

  @override
  String get qr_copied => 'Copied';

  @override
  String get qr_hint => 'Scan to add me as a friend';

  @override
  String get qr_user_id_label => 'ID:';

  @override
  String get settings_profile => 'Profile';

  @override
  String get settings_appearance => 'Appearance';

  @override
  String get settings_theme_light => 'Light';

  @override
  String get settings_theme_dark => 'Dark';

  @override
  String get settings_theme_system => 'System';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_language_ar => 'العربية';

  @override
  String get settings_language_en => 'English';

  @override
  String get settings_security => 'Security';

  @override
  String get settings_biometric => 'Biometric Lock';

  @override
  String get settings_network => 'Network';

  @override
  String get settings_power_mode => 'Power Mode';

  @override
  String get settings_power_high => 'High Performance';

  @override
  String get settings_power_balanced => 'Balanced';

  @override
  String get settings_power_low => 'Power Saving';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_done => 'Done';

  @override
  String get common_close => 'Close';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_error => 'Error occurred';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_search => 'Search';

  @override
  String get common_send => 'Send';

  @override
  String get termsOfService => 'Terms of Service';
}
