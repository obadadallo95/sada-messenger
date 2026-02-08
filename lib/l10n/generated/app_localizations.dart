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
/// import 'generated/app_localizations.dart';
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

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

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

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriend;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'My Code'**
  String get myCode;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// Share button label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Success message when contact found
  ///
  /// In en, this message translates to:
  /// **'Friend Found'**
  String get friendFound;

  /// Default name for new contact
  ///
  /// In en, this message translates to:
  /// **'New Friend'**
  String get newFriend;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriendButton;

  /// Permission error
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get cameraPermissionDenied;

  /// Permission rationale
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraPermissionRequired;

  /// Button to request permission
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// Instruction for scanning
  ///
  /// In en, this message translates to:
  /// **'Place QR code in the frame'**
  String get placeQrInFrame;

  /// Success toast
  ///
  /// In en, this message translates to:
  /// **'Friend added successfully'**
  String get friendAddedSuccessfully;

  /// Label for name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Label for ID field
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

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get createCommunity;

  /// Input label
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// Input hint
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get groupNameHint;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get groupNameRequired;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Group name is too short'**
  String get groupNameTooShort;

  /// Input label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupDescription;

  /// Input hint
  ///
  /// In en, this message translates to:
  /// **'Enter group description'**
  String get groupDescriptionHint;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get groupDescriptionRequired;

  /// Switch label
  ///
  /// In en, this message translates to:
  /// **'Public Group'**
  String get publicGroup;

  /// Switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone nearby'**
  String get publicGroupDescription;

  /// Switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Requires password to join'**
  String get privateGroupDescription;

  /// Input label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get groupPassword;

  /// Input hint
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get groupPasswordHint;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get groupPasswordRequired;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Launch Group'**
  String get launchGroup;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get myGroups;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Nearby Communities'**
  String get nearbyCommunities;

  /// Peer count
  ///
  /// In en, this message translates to:
  /// **'{count} peers nearby'**
  String peersNearby(int count);

  /// Join group button
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Status text
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

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Message when there are no notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// Button to mark all notifications as read
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// Onboarding slide 1 title
  ///
  /// In en, this message translates to:
  /// **'No Internet?\nNo Problem.'**
  String get noInternetNoProblem;

  /// Onboarding slide 1 description
  ///
  /// In en, this message translates to:
  /// **'Sada works when the internet doesn\'t. Connect directly with people around you using WiFi Direct.'**
  String get noInternetDescription;

  /// Onboarding slide 2 title
  ///
  /// In en, this message translates to:
  /// **'You Are The Network'**
  String get youAreTheNetwork;

  /// Onboarding slide 2 description
  ///
  /// In en, this message translates to:
  /// **'Your phone acts as a bridge. Help your community stay connected just by keeping the app open.'**
  String get youAreTheNetworkDescription;

  /// Onboarding slide 3 title
  ///
  /// In en, this message translates to:
  /// **'Invisible & Secure'**
  String get invisibleAndSecure;

  /// Onboarding slide 3 description
  ///
  /// In en, this message translates to:
  /// **'No servers. No tracking. Your messages stay in your neighborhood.'**
  String get invisibleAndSecureDescription;

  /// Onboarding slide 4 title
  ///
  /// In en, this message translates to:
  /// **'Ready to Connect?'**
  String get readyToConnect;

  /// Onboarding slide 4 description
  ///
  /// In en, this message translates to:
  /// **'Grant permissions to start discovering people nearby.'**
  String get readyToConnectDescription;

  /// Location permission badge
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permissionLocation;

  /// Notification permission badge
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get permissionNotify;

  /// WiFi permission badge
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get permissionWifi;

  /// Privacy screen section title
  ///
  /// In en, this message translates to:
  /// **'Zero-Knowledge Promise'**
  String get zeroKnowledgePromise;

  /// Privacy feature title
  ///
  /// In en, this message translates to:
  /// **'No Phone Number Required'**
  String get noPhoneNumberRequired;

  /// Privacy feature description
  ///
  /// In en, this message translates to:
  /// **'We don\'t ask for your phone number, email, or real identity. You are just a cryptographic key pair.'**
  String get noPhoneNumberDescription;

  /// Encryption description for privacy screen
  ///
  /// In en, this message translates to:
  /// **'All messages are encrypted on your device and only decrypted by the recipient. We cannot read your chats.'**
  String get endToEndEncryptionDescription;

  /// Privacy feature title
  ///
  /// In en, this message translates to:
  /// **'Local Database Only'**
  String get localDatabaseOnly;

  /// Privacy feature description
  ///
  /// In en, this message translates to:
  /// **'Your data lives on your phone. There is no cloud backup. If you delete the app, your data is gone forever.'**
  String get localDatabaseDescription;

  /// Privacy section title
  ///
  /// In en, this message translates to:
  /// **'Transparency'**
  String get transparency;

  /// Transparency description
  ///
  /// In en, this message translates to:
  /// **'Sada uses standard WiFi Direct and UDP broadcasts to find peers. While your device announces its presence, your real identity remains hidden behind a random ID.'**
  String get transparencyDescription;

  /// Button to view source code
  ///
  /// In en, this message translates to:
  /// **'View Source Code'**
  String get viewSourceCode;

  /// About screen section title
  ///
  /// In en, this message translates to:
  /// **'How it Works'**
  String get howItWorks;

  /// Title for Scan QR Code screen
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// Timeline step 1 description
  ///
  /// In en, this message translates to:
  /// **'Meet a friend and scan their QR code to swap keys securely.'**
  String get scanQrDescription;

  /// Timeline step 2 title
  ///
  /// In en, this message translates to:
  /// **'Auto Connect'**
  String get autoConnect;

  /// Timeline step 2 description
  ///
  /// In en, this message translates to:
  /// **'Your devices automatically find each other over WiFi Direct.'**
  String get autoConnectDescription;

  /// Timeline step 3 title
  ///
  /// In en, this message translates to:
  /// **'Secure Chat'**
  String get secureChat;

  /// Timeline step 3 description
  ///
  /// In en, this message translates to:
  /// **'Messages hop between devices until they reach the destination.'**
  String get secureChatDescription;

  /// About screen footer
  ///
  /// In en, this message translates to:
  /// **'Designed for Resilience'**
  String get designedForResilience;

  /// Description for sharing QR code
  ///
  /// In en, this message translates to:
  /// **'Share this QR code to add you as a contact'**
  String get shareQrCodeDescription;

  /// Title for My QR Code screen
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get myQrCode;

  /// Error message when adding existing contact
  ///
  /// In en, this message translates to:
  /// **'Contact already exists'**
  String get contactAlreadyExists;

  /// Error message for invalid QR
  ///
  /// In en, this message translates to:
  /// **'Error processing QR Code'**
  String get errorProcessingQrCode;

  /// Error message when scanning own QR
  ///
  /// In en, this message translates to:
  /// **'You cannot add yourself'**
  String get cannotAddYourself;

  /// Loading state text
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Security information about QR code
  ///
  /// In en, this message translates to:
  /// **'This QR code contains your public key for secure messaging.'**
  String get qrCodeSecurityInfo;
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
