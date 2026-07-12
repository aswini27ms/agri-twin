// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'AgriTwin AI';

  @override
  String get splashTagline =>
      'AI-powered farming, offline and in your language';

  @override
  String get loginTitle => 'Farmer Login';

  @override
  String get loginSubtitle => 'Create or access your local farming profile';

  @override
  String get name => 'Name';

  @override
  String get nameHint => 'Enter your name';

  @override
  String get phone => 'Phone Number / Farmer ID';

  @override
  String get phoneHint => 'Enter phone or farmer ID';

  @override
  String get pin => 'Security PIN';

  @override
  String get pinHint => 'Enter 4-digit PIN';

  @override
  String get getStarted => 'Get Started';

  @override
  String get soilSnapshot => 'Soil Snapshot';

  @override
  String get nitrogen => 'Nitrogen (N)';

  @override
  String get phosphorus => 'Phosphorus (P)';

  @override
  String get potassium => 'Potassium (K)';

  @override
  String get moisture => 'Moisture';

  @override
  String get connected => 'Connected';

  @override
  String get offline => 'Offline';

  @override
  String lastUpdated(Object time) {
    return 'Last updated: $time';
  }

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get gallery => 'Open Gallery';

  @override
  String get dashboard => 'Digital Twin';

  @override
  String get fieldHealthScore => 'Field Health Score';

  @override
  String get healthTrend => 'Health Trend';

  @override
  String get topRiskFactor => 'Top Risk Factor';

  @override
  String get whatIfSimulator => 'What-If Simulator';

  @override
  String get simulateIrrigation => 'Simulate irrigation today';

  @override
  String get addField => 'Add New Field';

  @override
  String get selectField => 'Select Field';

  @override
  String get result => 'Diagnosis Result';

  @override
  String get disease => 'Crop Disease';

  @override
  String get confidence => 'Confidence Score';

  @override
  String get remedyAdvice => 'Localized AI Remedy';

  @override
  String get listenAdvice => 'Listen to Remedy';

  @override
  String get askFollowUp => 'Ask a follow-up question...';

  @override
  String get scanHistory => 'Scan History';

  @override
  String get filterAll => 'All';

  @override
  String get filterByField => 'Filter by Field';

  @override
  String get filterByDisease => 'Filter by Disease';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get backendIP => 'Backend Server IP / Address';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get defaultLanguage => 'Default Language';

  @override
  String get manageFields => 'Manage Fields/Plots';

  @override
  String get switchFarmer => 'Switch Farmer / Log Out';

  @override
  String get connectionSuccess => 'Connection successful!';

  @override
  String get connectionFailed => 'Connection failed. Please check IP.';

  @override
  String get testingConnection => 'Testing connection...';

  @override
  String get listen => 'Listen';

  @override
  String get stop => 'Stop';

  @override
  String simulatedLabel(Object score) {
    return 'Simulated Projected Score: $score';
  }

  @override
  String get landingTitle => 'AgriTwin AI';

  @override
  String get landingDesc =>
      'Your personal AI assistant for managing farm health and digital twins.';

  @override
  String get onboardingRealtime => 'Real-time Monitoring';

  @override
  String get onboardingRealtimeDesc =>
      'Monitor moisture, nutrients, and weather conditions in real-time.';

  @override
  String get onboardingDisease => 'Disease Detection';

  @override
  String get onboardingDiseaseDesc =>
      'Scan crops to instantly detect diseases and get treatment recommendations.';

  @override
  String get onboardingGemma => 'Gemma AI';

  @override
  String get onboardingGemmaDesc =>
      'Chat with our advanced offline AI to get personalized farming advice.';

  @override
  String get btnGetStarted => 'Get Started';

  @override
  String get btnNext => 'Next';

  @override
  String get loginWelcome => 'Welcome Back';

  @override
  String get loginSetupProfile => 'Setup your profile to continue';

  @override
  String get loginHintName => 'Your Name (e.g. John Doe)';

  @override
  String get loginHintFarm => 'Farm Name (e.g. Green Valley Farm)';

  @override
  String get loginHintLocation => 'Location (e.g. Coimbatore)';

  @override
  String get btnContinue => 'Continue';

  @override
  String get loadingTwin => 'Setting up your digital twin...';

  @override
  String get navHome => 'Home';

  @override
  String get navTwin => 'Digital Twin';

  @override
  String get navVillage => 'Village';

  @override
  String get navChat => 'Chat';

  @override
  String get navSettings => 'Settings';

  @override
  String homeWelcomeBack(String userName) {
    return 'Welcome Back, $userName';
  }

  @override
  String get homeOfflineMode => 'Offline Mode - Showing Cached Data';

  @override
  String get homeFarmHealth => 'Overall Farm Health';

  @override
  String get homeSensors => 'Live Sensors';

  @override
  String get homeTemperature => 'Temp';

  @override
  String get homeHumidity => 'Humidity';

  @override
  String get homeLiveSensors => 'Live Sensors';

  @override
  String get homeNoSensorData => 'No sensor data. Ensure Edge Node is active.';

  @override
  String get homeWeatherUnavailable => 'Weather unavailable';

  @override
  String get homeNoHealthData => 'No health data yet. Scan a crop.';

  @override
  String get homeOverallScore => 'Overall Score';

  @override
  String get homeScanned => 'Scanned';

  @override
  String get homeInfected => 'Infected';

  @override
  String get homeAvgRisk => 'Avg Risk';

  @override
  String get homeFailedLoadHealth => 'Failed to load health data';

  @override
  String get homeQuickActions => 'Quick Actions';

  @override
  String get homeScanCrop => 'Scan Crop';

  @override
  String get homeAskGemma => 'Ask Gemma';

  @override
  String get twinLiveView => 'Live View';

  @override
  String get twinPredictive => 'Predictive Analytics (Next 7 days)';

  @override
  String get twinSimulate => 'Simulate Twin';

  @override
  String get twinHealthHistory => 'Health History';

  @override
  String get villageDashboard => 'Village Intelligence';

  @override
  String get villageSummary => 'District Summary';

  @override
  String get villageAlerts => 'Active Outbreaks & Alerts';

  @override
  String get chatGemma => 'Gemma AI Assistant';

  @override
  String get chatHint => 'Ask about your farm or diseases...';

  @override
  String get chatOffline =>
      'Gemma is running locally on your device for complete privacy.';

  @override
  String get settingsProfile => 'User Profile';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLocation => 'Location (City)';

  @override
  String get settingsConnection => 'Backend Connection';

  @override
  String get btnSave => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved successfully';
}
