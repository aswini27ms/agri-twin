import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

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
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AgriTwin AI'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'AI-powered farming, offline and in your language'**
  String get splashTagline;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create or access your local farming profile'**
  String get loginSubtitle;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameHint;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number / Farmer ID'**
  String get phone;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone or farmer ID'**
  String get phoneHint;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Security PIN'**
  String get pin;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-digit PIN'**
  String get pinHint;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @soilSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Soil Snapshot'**
  String get soilSnapshot;

  /// No description provided for @nitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen (N)'**
  String get nitrogen;

  /// No description provided for @phosphorus.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus (P)'**
  String get phosphorus;

  /// No description provided for @potassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium (K)'**
  String get potassium;

  /// No description provided for @moisture.
  ///
  /// In en, this message translates to:
  /// **'Moisture'**
  String get moisture;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String lastUpdated(Object time);

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Open Gallery'**
  String get gallery;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin'**
  String get dashboard;

  /// No description provided for @fieldHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Field Health Score'**
  String get fieldHealthScore;

  /// No description provided for @healthTrend.
  ///
  /// In en, this message translates to:
  /// **'Health Trend'**
  String get healthTrend;

  /// No description provided for @topRiskFactor.
  ///
  /// In en, this message translates to:
  /// **'Top Risk Factor'**
  String get topRiskFactor;

  /// No description provided for @whatIfSimulator.
  ///
  /// In en, this message translates to:
  /// **'What-If Simulator'**
  String get whatIfSimulator;

  /// No description provided for @simulateIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Simulate irrigation today'**
  String get simulateIrrigation;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add New Field'**
  String get addField;

  /// No description provided for @selectField.
  ///
  /// In en, this message translates to:
  /// **'Select Field'**
  String get selectField;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Result'**
  String get result;

  /// No description provided for @disease.
  ///
  /// In en, this message translates to:
  /// **'Crop Disease'**
  String get disease;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence Score'**
  String get confidence;

  /// No description provided for @remedyAdvice.
  ///
  /// In en, this message translates to:
  /// **'Localized AI Remedy'**
  String get remedyAdvice;

  /// No description provided for @listenAdvice.
  ///
  /// In en, this message translates to:
  /// **'Listen to Remedy'**
  String get listenAdvice;

  /// No description provided for @askFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Ask a follow-up question...'**
  String get askFollowUp;

  /// No description provided for @scanHistory.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get scanHistory;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterByField.
  ///
  /// In en, this message translates to:
  /// **'Filter by Field'**
  String get filterByField;

  /// No description provided for @filterByDisease.
  ///
  /// In en, this message translates to:
  /// **'Filter by Disease'**
  String get filterByDisease;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @backendIP.
  ///
  /// In en, this message translates to:
  /// **'Backend Server IP / Address'**
  String get backendIP;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @defaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default Language'**
  String get defaultLanguage;

  /// No description provided for @manageFields.
  ///
  /// In en, this message translates to:
  /// **'Manage Fields/Plots'**
  String get manageFields;

  /// No description provided for @switchFarmer.
  ///
  /// In en, this message translates to:
  /// **'Switch Farmer / Log Out'**
  String get switchFarmer;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please check IP.'**
  String get connectionFailed;

  /// No description provided for @testingConnection.
  ///
  /// In en, this message translates to:
  /// **'Testing connection...'**
  String get testingConnection;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @simulatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Simulated Projected Score: {score}'**
  String simulatedLabel(Object score);

  /// No description provided for @landingTitle.
  ///
  /// In en, this message translates to:
  /// **'AgriTwin AI'**
  String get landingTitle;

  /// No description provided for @landingDesc.
  ///
  /// In en, this message translates to:
  /// **'Your personal AI assistant for managing farm health and digital twins.'**
  String get landingDesc;

  /// No description provided for @onboardingRealtime.
  ///
  /// In en, this message translates to:
  /// **'Real-time Monitoring'**
  String get onboardingRealtime;

  /// No description provided for @onboardingRealtimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Monitor moisture, nutrients, and weather conditions in real-time.'**
  String get onboardingRealtimeDesc;

  /// No description provided for @onboardingDisease.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection'**
  String get onboardingDisease;

  /// No description provided for @onboardingDiseaseDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan crops to instantly detect diseases and get treatment recommendations.'**
  String get onboardingDiseaseDesc;

  /// No description provided for @onboardingGemma.
  ///
  /// In en, this message translates to:
  /// **'Gemma AI'**
  String get onboardingGemma;

  /// No description provided for @onboardingGemmaDesc.
  ///
  /// In en, this message translates to:
  /// **'Chat with our advanced offline AI to get personalized farming advice.'**
  String get onboardingGemmaDesc;

  /// No description provided for @btnGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get btnGetStarted;

  /// No description provided for @btnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get btnNext;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcome;

  /// No description provided for @loginSetupProfile.
  ///
  /// In en, this message translates to:
  /// **'Setup your profile to continue'**
  String get loginSetupProfile;

  /// No description provided for @loginHintName.
  ///
  /// In en, this message translates to:
  /// **'Your Name (e.g. John Doe)'**
  String get loginHintName;

  /// No description provided for @loginHintFarm.
  ///
  /// In en, this message translates to:
  /// **'Farm Name (e.g. Green Valley Farm)'**
  String get loginHintFarm;

  /// No description provided for @loginHintLocation.
  ///
  /// In en, this message translates to:
  /// **'Location (e.g. Coimbatore)'**
  String get loginHintLocation;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @loadingTwin.
  ///
  /// In en, this message translates to:
  /// **'Setting up your digital twin...'**
  String get loadingTwin;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTwin.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin'**
  String get navTwin;

  /// No description provided for @navVillage.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get navVillage;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, {userName}'**
  String homeWelcomeBack(String userName);

  /// No description provided for @homeOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode - Showing Cached Data'**
  String get homeOfflineMode;

  /// No description provided for @homeFarmHealth.
  ///
  /// In en, this message translates to:
  /// **'Overall Farm Health'**
  String get homeFarmHealth;

  /// No description provided for @homeSensors.
  ///
  /// In en, this message translates to:
  /// **'Live Sensors'**
  String get homeSensors;

  /// No description provided for @homeTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get homeTemperature;

  /// No description provided for @homeHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get homeHumidity;

  /// No description provided for @homeLiveSensors.
  ///
  /// In en, this message translates to:
  /// **'Live Sensors'**
  String get homeLiveSensors;

  /// No description provided for @homeNoSensorData.
  ///
  /// In en, this message translates to:
  /// **'No sensor data. Ensure Edge Node is active.'**
  String get homeNoSensorData;

  /// No description provided for @homeWeatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable'**
  String get homeWeatherUnavailable;

  /// No description provided for @homeNoHealthData.
  ///
  /// In en, this message translates to:
  /// **'No health data yet. Scan a crop.'**
  String get homeNoHealthData;

  /// No description provided for @homeOverallScore.
  ///
  /// In en, this message translates to:
  /// **'Overall Score'**
  String get homeOverallScore;

  /// No description provided for @homeScanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get homeScanned;

  /// No description provided for @homeInfected.
  ///
  /// In en, this message translates to:
  /// **'Infected'**
  String get homeInfected;

  /// No description provided for @homeAvgRisk.
  ///
  /// In en, this message translates to:
  /// **'Avg Risk'**
  String get homeAvgRisk;

  /// No description provided for @homeFailedLoadHealth.
  ///
  /// In en, this message translates to:
  /// **'Failed to load health data'**
  String get homeFailedLoadHealth;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// No description provided for @homeScanCrop.
  ///
  /// In en, this message translates to:
  /// **'Scan Crop'**
  String get homeScanCrop;

  /// No description provided for @homeAskGemma.
  ///
  /// In en, this message translates to:
  /// **'Ask Gemma'**
  String get homeAskGemma;

  /// No description provided for @twinLiveView.
  ///
  /// In en, this message translates to:
  /// **'Live View'**
  String get twinLiveView;

  /// No description provided for @twinPredictive.
  ///
  /// In en, this message translates to:
  /// **'Predictive Analytics (Next 7 days)'**
  String get twinPredictive;

  /// No description provided for @twinSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate Twin'**
  String get twinSimulate;

  /// No description provided for @twinHealthHistory.
  ///
  /// In en, this message translates to:
  /// **'Health History'**
  String get twinHealthHistory;

  /// No description provided for @villageDashboard.
  ///
  /// In en, this message translates to:
  /// **'Village Intelligence'**
  String get villageDashboard;

  /// No description provided for @villageSummary.
  ///
  /// In en, this message translates to:
  /// **'District Summary'**
  String get villageSummary;

  /// No description provided for @villageAlerts.
  ///
  /// In en, this message translates to:
  /// **'Active Outbreaks & Alerts'**
  String get villageAlerts;

  /// No description provided for @chatGemma.
  ///
  /// In en, this message translates to:
  /// **'Gemma AI Assistant'**
  String get chatGemma;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your farm or diseases...'**
  String get chatHint;

  /// No description provided for @chatOffline.
  ///
  /// In en, this message translates to:
  /// **'Gemma is running locally on your device for complete privacy.'**
  String get chatOffline;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get settingsProfile;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location (City)'**
  String get settingsLocation;

  /// No description provided for @settingsConnection.
  ///
  /// In en, this message translates to:
  /// **'Backend Connection'**
  String get settingsConnection;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get btnSave;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;
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
      <String>['en', 'hi', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
