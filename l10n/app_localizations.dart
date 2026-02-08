import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'Sada'**
  String get appName;

  /// Greeting message
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// Welcome message on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sada Foundation Layer'**
  String get welcomeMessage;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Theme section title
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Language section title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic language option
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// Chat screen title
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Placeholder message for features not yet implemented
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Description of the foundation layer
  ///
  /// In en, this message translates to:
  /// **'Foundation Layer - UI/UX Architecture'**
  String get foundationLayer;

  /// Skip button text in onboarding
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Next button text in onboarding
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Get started button text in onboarding
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Title for onboarding slide 1
  ///
  /// In en, this message translates to:
  /// **'Connect Without Limits'**
  String get onboardingSlide1Title;

  /// Description for onboarding slide 1
  ///
  /// In en, this message translates to:
  /// **'Connect with your loved ones even when the internet is down through Mesh network.'**
  String get onboardingSlide1Description;

  /// Title for onboarding slide 2
  ///
  /// In en, this message translates to:
  /// **'Absolute Security'**
  String get onboardingSlide2Title;

  /// Description for onboarding slide 2
  ///
  /// In en, this message translates to:
  /// **'Full encryption for your messages. No central servers, no tracking.'**
  String get onboardingSlide2Description;

  /// Title for onboarding slide 3
  ///
  /// In en, this message translates to:
  /// **'Made for Us'**
  String get onboardingSlide3Title;

  /// Description for onboarding slide 3
  ///
  /// In en, this message translates to:
  /// **'Open source app, free, and designed for the Syrian reality.'**
  String get onboardingSlide3Description;

  /// Message when there are no chats
  ///
  /// In en, this message translates to:
  /// **'No chats'**
  String get noChats;

  /// Error message when loading chats fails
  ///
  /// In en, this message translates to:
  /// **'Error loading chats'**
  String get errorLoadingChats;

  /// Message for search feature not yet implemented
  ///
  /// In en, this message translates to:
  /// **'Search feature coming soon'**
  String get searchFeatureComingSoon;

  /// Online status in chat screen
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Message when there are no messages in chat
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// Error message when loading messages fails
  ///
  /// In en, this message translates to:
  /// **'Error loading messages'**
  String get errorLoadingMessages;

  /// Placeholder text for message input field
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Word for yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Number of days ago
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// Add friend screen title
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriend;

  /// Tab 1 title - My QR Code
  ///
  /// In en, this message translates to:
  /// **'My Code'**
  String get myCode;

  /// Tab 2 title - Scan QR Code
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// User ID label
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Message when friend is found
  ///
  /// In en, this message translates to:
  /// **'Friend Found!'**
  String get friendFound;

  /// Default name for new friend
  ///
  /// In en, this message translates to:
  /// **'New Friend'**
  String get newFriend;

  /// Add friend button
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriendButton;

  /// Message when camera permission is denied
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get cameraPermissionDenied;

  /// Message when camera permission is denied
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraPermissionRequired;

  /// Button to grant permission
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// Instructions for user when scanning QR code
  ///
  /// In en, this message translates to:
  /// **'Position the QR code within the frame'**
  String get placeQrInFrame;

  /// Success message when adding a friend
  ///
  /// In en, this message translates to:
  /// **'Friend added successfully'**
  String get friendAddedSuccessfully;

  /// Name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// ID label
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// Button to simulate incoming message
  ///
  /// In en, this message translates to:
  /// **'Simulate Message'**
  String get simulateMessage;

  /// Message while simulating
  ///
  /// In en, this message translates to:
  /// **'Simulating...'**
  String get simulatingMessage;

  /// Notification title for new message
  ///
  /// In en, this message translates to:
  /// **'New message from {name}'**
  String newMessageFrom(String name);

  /// Message requesting notification permission
  ///
  /// In en, this message translates to:
  /// **'We need notification permission to show alerts'**
  String get notificationPermissionRequired;

  /// Power usage section title
  ///
  /// In en, this message translates to:
  /// **'Power Usage'**
  String get powerUsage;

  /// Disable battery optimization button
  ///
  /// In en, this message translates to:
  /// **'Disable Battery Optimization'**
  String get disableBatteryOptimization;

  /// Description for battery optimization button
  ///
  /// In en, this message translates to:
  /// **'To ensure Sada works in the background, please disable battery optimization from system settings'**
  String get batteryOptimizationDescription;

  /// Message when settings cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open settings'**
  String get couldNotOpenSettings;

  /// Background service notification text - active
  ///
  /// In en, this message translates to:
  /// **'Sada is active'**
  String get serviceActive;

  /// Background service notification text - scanning
  ///
  /// In en, this message translates to:
  /// **'Sada: Scanning...'**
  String get serviceScanning;

  /// Background service notification text - sleeping
  ///
  /// In en, this message translates to:
  /// **'Sada: Sleeping'**
  String get serviceSleeping;

  /// Appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Performance section title
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// About & Legal section title
  ///
  /// In en, this message translates to:
  /// **'About & Legal'**
  String get aboutAndLegal;

  /// About Us page title
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// Privacy Policy page title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Open Source Licenses page title
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// Version word
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// App description in About page
  ///
  /// In en, this message translates to:
  /// **'Sada is an open-source, free, offline mesh messaging application designed for the Syrian reality. It enables communication even when the internet is cut off through a wireless Mesh network.'**
  String get aboutDescription;

  /// Website word
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Footer text in About page
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ for Syria'**
  String get madeWithLove;

  /// Last update date for privacy policy
  ///
  /// In en, this message translates to:
  /// **'Last updated: January 2024'**
  String get lastUpdated;

  /// No data collection section title
  ///
  /// In en, this message translates to:
  /// **'No Data Collection'**
  String get noDataCollection;

  /// No data collection description
  ///
  /// In en, this message translates to:
  /// **'We do not collect or store any personal data on our servers. All data remains local on your device only.'**
  String get noDataCollectionDescription;

  /// Local storage section title
  ///
  /// In en, this message translates to:
  /// **'Local Storage'**
  String get localStorage;

  /// Local storage description
  ///
  /// In en, this message translates to:
  /// **'All your messages and conversations are stored locally on your device. No data is sent to external servers.'**
  String get localStorageDescription;

  /// Encryption section title
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get encryption;

  /// Encryption description
  ///
  /// In en, this message translates to:
  /// **'All messages are end-to-end encrypted (E2E). Even if messages are intercepted, they cannot be read without the private keys.'**
  String get encryptionDescription;

  /// Mesh networking section title
  ///
  /// In en, this message translates to:
  /// **'Mesh Networking'**
  String get meshNetworking;

  /// Mesh networking description
  ///
  /// In en, this message translates to:
  /// **'Sada uses Mesh Networking technology to communicate directly between devices without the need for central servers or internet connection.'**
  String get meshNetworkingDescription;

  /// Open source section title
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get openSource;

  /// Open source description
  ///
  /// In en, this message translates to:
  /// **'Sada is an open-source project. You can review the source code on GitHub and contribute to its development.'**
  String get openSourceDescription;

  /// Exit message when pressing back button
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get exitMessage;

  /// Registration screen title
  ///
  /// In en, this message translates to:
  /// **'Create Your Identity'**
  String get createIdentity;

  /// Information about how identity is generated
  ///
  /// In en, this message translates to:
  /// **'Your identity is generated from this device\'s unique signature. No phone number required.'**
  String get identityInfo;

  /// Nickname field label
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// Nickname field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get nicknameHint;

  /// Error message when nickname is not entered
  ///
  /// In en, this message translates to:
  /// **'Nickname is required'**
  String get nicknameRequired;

  /// Error message when nickname is too short
  ///
  /// In en, this message translates to:
  /// **'Nickname is too short (must be at least 2 characters)'**
  String get nicknameTooShort;

  /// Register button
  ///
  /// In en, this message translates to:
  /// **'Enter Sada'**
  String get enterSada;

  /// Security note in registration screen
  ///
  /// In en, this message translates to:
  /// **'Your identity is bound to this device only. No data is sent to external servers.'**
  String get securityNote;

  /// Error message when registration fails
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailed;

  /// Privacy & Security section title
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacyAndSecurity;

  /// App lock setting title
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// App lock setting description
  ///
  /// In en, this message translates to:
  /// **'Require fingerprint to open'**
  String get appLockDescription;

  /// Lock screen title
  ///
  /// In en, this message translates to:
  /// **'Sada is Locked'**
  String get sadaIsLocked;

  /// Lock screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint to unlock the app'**
  String get unlockToContinue;

  /// Unlock button
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// Biometric authentication message
  ///
  /// In en, this message translates to:
  /// **'Scan your fingerprint to enter Sada'**
  String get scanFingerprintToEnter;

  /// Error message when authentication fails
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// Message when biometric is not available
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device'**
  String get biometricNotAvailable;

  /// Error message when changing lock status fails
  ///
  /// In en, this message translates to:
  /// **'Failed to change lock status'**
  String get failedToChangeLock;

  /// Create group screen title
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get createCommunity;

  /// Group name field label
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// Group name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get groupNameHint;

  /// Error message when group name is empty
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get groupNameRequired;

  /// Error message when group name is too short
  ///
  /// In en, this message translates to:
  /// **'Group name is too short (must be at least 3 characters)'**
  String get groupNameTooShort;

  /// Group description field label
  ///
  /// In en, this message translates to:
  /// **'Group Description'**
  String get groupDescription;

  /// Group description field hint
  ///
  /// In en, this message translates to:
  /// **'Enter group description'**
  String get groupDescriptionHint;

  /// Error message when group description is empty
  ///
  /// In en, this message translates to:
  /// **'Group description is required'**
  String get groupDescriptionRequired;

  /// Public group type label
  ///
  /// In en, this message translates to:
  /// **'Public Group'**
  String get publicGroup;

  /// Public group description
  ///
  /// In en, this message translates to:
  /// **'Anyone nearby can discover and join this group'**
  String get publicGroupDescription;

  /// Private group description
  ///
  /// In en, this message translates to:
  /// **'Private group requires a password to join'**
  String get privateGroupDescription;

  /// Group password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get groupPassword;

  /// Group password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get groupPasswordHint;

  /// Error message when password is empty
  ///
  /// In en, this message translates to:
  /// **'Password is required for private groups'**
  String get groupPasswordRequired;

  /// Create group button
  ///
  /// In en, this message translates to:
  /// **'Launch Group'**
  String get launchGroup;

  /// My groups section title
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get myGroups;

  /// Nearby communities section title
  ///
  /// In en, this message translates to:
  /// **'Nearby Communities'**
  String get nearbyCommunities;

  /// Number of nearby peers
  ///
  /// In en, this message translates to:
  /// **'{count} peers nearby'**
  String peersNearby(int count);

  /// Join group button
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Scanning text for discovering groups
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// Button to switch to PIN entry
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// Change Master PIN option title
  ///
  /// In en, this message translates to:
  /// **'Change Master PIN'**
  String get changeMasterPin;

  /// Set Duress PIN option title
  ///
  /// In en, this message translates to:
  /// **'Set Duress PIN'**
  String get setDuressPin;

  /// Warning when setting Duress PIN
  ///
  /// In en, this message translates to:
  /// **'Use this PIN only in danger. It will hide your real data and show fake data.'**
  String get duressPinWarning;

  /// Prompt to enter Master PIN
  ///
  /// In en, this message translates to:
  /// **'Enter Master PIN'**
  String get enterMasterPin;

  /// Prompt to enter Duress PIN
  ///
  /// In en, this message translates to:
  /// **'Enter Duress PIN'**
  String get enterDuressPin;

  /// Prompt to confirm PIN
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// Error message when PIN doesn't match
  ///
  /// In en, this message translates to:
  /// **'PIN mismatch'**
  String get pinMismatch;

  /// Success message when PIN is set
  ///
  /// In en, this message translates to:
  /// **'PIN set successfully'**
  String get pinSetSuccessfully;

  /// Success message when PIN is changed
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully'**
  String get pinChangedSuccessfully;

  /// Showcase title for profile avatar
  ///
  /// In en, this message translates to:
  /// **'Your Identity'**
  String get yourIdentity;

  /// Showcase description for profile avatar
  ///
  /// In en, this message translates to:
  /// **'Tap to view your QR code and profile'**
  String get yourIdentityDescription;

  /// Showcase title for FAB button
  ///
  /// In en, this message translates to:
  /// **'Start Connecting'**
  String get startConnecting;

  /// Showcase description for FAB button
  ///
  /// In en, this message translates to:
  /// **'Tap here to search for nearby devices or create a group'**
  String get startConnectingDescription;

  /// Developer role
  ///
  /// In en, this message translates to:
  /// **'Lead Developer'**
  String get leadDeveloper;

  /// Founder role
  ///
  /// In en, this message translates to:
  /// **'Founder'**
  String get founder;

  /// Title for app sharing button
  ///
  /// In en, this message translates to:
  /// **'Share App Offline'**
  String get shareAppOffline;

  /// Description for app sharing button
  ///
  /// In en, this message translates to:
  /// **'Send APK file via Bluetooth or sharing apps'**
  String get shareAppOfflineDescription;

  /// Message while preparing APK file
  ///
  /// In en, this message translates to:
  /// **'Preparing APK file...'**
  String get preparingApk;

  /// Success message for APK sharing
  ///
  /// In en, this message translates to:
  /// **'Share sheet opened successfully'**
  String get apkShareSuccess;

  /// Error message for APK sharing
  ///
  /// In en, this message translates to:
  /// **'Failed to share APK file'**
  String get apkShareError;

  /// Title for user's QR code display screen
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get myQrCode;

  /// Title for QR code scanning screen
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// Error message when scanning invalid QR code
  ///
  /// In en, this message translates to:
  /// **'Invalid QR Code'**
  String get invalidQrCode;

  /// Error message when failing to parse JSON from QR code
  ///
  /// In en, this message translates to:
  /// **'Invalid QR Code format'**
  String get invalidQrCodeFormat;

  /// Error message when required fields are missing in QR code
  ///
  /// In en, this message translates to:
  /// **'Invalid QR Code: Missing required fields'**
  String get invalidQrCodeFields;

  /// Message while processing QR code
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Error message when trying to add yourself
  ///
  /// In en, this message translates to:
  /// **'You cannot add yourself as a contact'**
  String get cannotAddYourself;

  /// Message when contact already exists
  ///
  /// In en, this message translates to:
  /// **'Contact already exists'**
  String get contactAlreadyExists;

  /// Generic error message when processing QR code
  ///
  /// In en, this message translates to:
  /// **'Error processing QR Code'**
  String get errorProcessingQrCode;

  /// Description of QR code when sharing
  ///
  /// In en, this message translates to:
  /// **'Share this QR code to add you as a contact'**
  String get shareQrCodeDescription;

  /// Security information about QR code
  ///
  /// In en, this message translates to:
  /// **'This QR code contains your public key for secure messaging.'**
  String get qrCodeSecurityInfo;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Button to mark all notifications as read
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllAsRead;

  /// Message when there are no notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// Title for Terms of Service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Title for Source Code
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get sourceCode;

  /// Text for View on GitHub button
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get viewOnGitHub;

  /// Text for Read privacy policy button
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readOurPrivacyPolicy;

  /// Text for Read terms of service button
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get readOurTermsOfService;

  /// Title for Open Source Libraries section
  ///
  /// In en, this message translates to:
  /// **'Open Source Libraries'**
  String get openSourceLibraries;

  /// Text 'Made with ❤️ for Freedom'
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ for Freedom'**
  String get madeWithLoveForFreedom;

  /// Text thanking open-source contributors
  ///
  /// In en, this message translates to:
  /// **'Sada is built with open-source software. Thank you to all contributors!'**
  String get sadaBuiltWithOpenSource;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
