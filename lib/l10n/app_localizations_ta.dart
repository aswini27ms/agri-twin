// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'AgriTwin AI';

  @override
  String get splashTagline =>
      'AI மூலம் இயங்கும் விவசாயம், ஆஃப்லைன் மற்றும் உங்கள் மொழியில்';

  @override
  String get loginTitle => 'விவசாயி உள்நுழைவு';

  @override
  String get loginSubtitle => 'உங்கள் உள்ளூர் விவசாய சுயவிவரத்தை உருவாக்கவும்';

  @override
  String get name => 'பெயர்';

  @override
  String get nameHint => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get phone => 'தொலைபேசி எண் / விவசாயி ஐடி';

  @override
  String get phoneHint => 'தொலைபேசி அல்லது ஐடியை உள்ளிடவும்';

  @override
  String get pin => 'பாதுகாப்பு பின்';

  @override
  String get pinHint => '4 இலக்க பின்னை உள்ளிடவும்';

  @override
  String get getStarted => 'தொடங்கு';

  @override
  String get soilSnapshot => 'மண் நிலை';

  @override
  String get nitrogen => 'நைட்ரஜன் (N)';

  @override
  String get phosphorus => 'பாஸ்பரஸ் (P)';

  @override
  String get potassium => 'பொட்டாசியம் (K)';

  @override
  String get moisture => 'ஈரப்பதம்';

  @override
  String get connected => 'இணைக்கப்பட்டுள்ளது';

  @override
  String get offline => 'ஆஃப்லைன்';

  @override
  String lastUpdated(Object time) {
    return 'கடைசியாக புதுப்பிக்கப்பட்டது: $time';
  }

  @override
  String get takePhoto => 'புகைப்படம் எடு';

  @override
  String get gallery => 'கேலரியைத் திற';

  @override
  String get dashboard => 'டிஜிட்டல் ட்வின்';

  @override
  String get fieldHealthScore => 'வயல் ஆரோக்கிய மதிப்பெண்';

  @override
  String get healthTrend => 'ஆரோக்கிய போக்கு';

  @override
  String get topRiskFactor => 'முக்கிய ஆபத்து காரணி';

  @override
  String get whatIfSimulator => 'சிமுலேட்டர்';

  @override
  String get simulateIrrigation => 'இன்று நீர்ப்பாசனத்தை உருவகப்படுத்துங்கள்';

  @override
  String get addField => 'புதிய வயலைச் சேர்';

  @override
  String get selectField => 'வயலைத் தேர்ந்தெடு';

  @override
  String get result => 'கண்டறிதல் முடிவு';

  @override
  String get disease => 'பயிர் நோய்';

  @override
  String get confidence => 'நம்பிக்கை மதிப்பெண்';

  @override
  String get remedyAdvice => 'உள்ளூர் AI தீர்வு';

  @override
  String get listenAdvice => 'தீர்வை கேளுங்கள்';

  @override
  String get askFollowUp => 'தொடர்ந்து ஒரு கேள்வியைக் கேளுங்கள்...';

  @override
  String get scanHistory => 'ஸ்கேன் வரலாறு';

  @override
  String get filterAll => 'அனைத்தும்';

  @override
  String get filterByField => 'வயல் மூலம் வடிகட்டு';

  @override
  String get filterByDisease => 'நோய் மூலம் வடிகட்டு';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get backendIP => 'சேவையக ஐபி / முகவரி';

  @override
  String get testConnection => 'இணைப்பைச் சோதிக்கவும்';

  @override
  String get defaultLanguage => 'இயல்புநிலை மொழி';

  @override
  String get manageFields => 'வயல்களை நிர்வகி';

  @override
  String get switchFarmer => 'விவசாயியை மாற்று / வெளியேறு';

  @override
  String get connectionSuccess => 'இணைப்பு வெற்றிகரமானது!';

  @override
  String get connectionFailed =>
      'இணைப்பு தோல்வியடைந்தது. ஐபியைச் சரிபார்க்கவும்.';

  @override
  String get testingConnection => 'இணைப்பைச் சோதிக்கிறது...';

  @override
  String get listen => 'கேள்';

  @override
  String get stop => 'நிறுத்து';

  @override
  String simulatedLabel(Object score) {
    return 'உருவகப்படுத்தப்பட்ட மதிப்பெண்: $score';
  }

  @override
  String get landingTitle => 'AgriTwin AI';

  @override
  String get landingDesc =>
      'பண்ணை ஆரோக்கியம் மற்றும் டிஜிட்டல் ட்வின்களை நிர்வகிப்பதற்கான உங்கள் தனிப்பட்ட AI உதவியாளர்.';

  @override
  String get onboardingRealtime => 'நிகழ்நேர கண்காணிப்பு';

  @override
  String get onboardingRealtimeDesc =>
      'ஈரப்பதம், ஊட்டச்சத்துக்கள் மற்றும் வானிலை நிலைமைகளை நிகழ்நேரத்தில் கண்காணிக்கவும்.';

  @override
  String get onboardingDisease => 'நோய் கண்டறிதல்';

  @override
  String get onboardingDiseaseDesc =>
      'நோய்களை உடனடியாகக் கண்டறிய பயிர்களை ஸ்கேன் செய்து சிகிச்சை பரிந்துரைகளைப் பெறுங்கள்.';

  @override
  String get onboardingGemma => 'Gemma AI';

  @override
  String get onboardingGemmaDesc =>
      'தனிப்பயனாக்கப்பட்ட விவசாய ஆலோசனைகளைப் பெற எங்கள் மேம்பட்ட ஆஃப்லைன் AI உடன் அரட்டையடிக்கவும்.';

  @override
  String get btnGetStarted => 'தொடங்கு';

  @override
  String get btnNext => 'அடுத்து';

  @override
  String get loginWelcome => 'மீண்டும் வருக';

  @override
  String get loginSetupProfile => 'தொடர உங்கள் சுயவிவரத்தை அமைக்கவும்';

  @override
  String get loginHintName => 'உங்கள் பெயர்';

  @override
  String get loginHintFarm => 'பண்ணையின் பெயர்';

  @override
  String get loginHintLocation => 'இடம் (நகரம்)';

  @override
  String get btnContinue => 'தொடரவும்';

  @override
  String get loadingTwin => 'உங்கள் டிஜிட்டல் ட்வினை அமைக்கிறது...';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navTwin => 'டிஜிட்டல் ட்வின்';

  @override
  String get navVillage => 'கிராமம்';

  @override
  String get navChat => 'அரட்டை';

  @override
  String get navSettings => 'அமைப்புகள்';

  @override
  String homeWelcomeBack(String userName) {
    return 'மீண்டும் வருக, $userName';
  }

  @override
  String get homeOfflineMode =>
      'ஆஃப்லைன் பயன்முறை - கேச் செய்யப்பட்ட தரவைக் காட்டுகிறது';

  @override
  String get homeFarmHealth => 'ஒட்டுமொத்த பண்ணை ஆரோக்கியம்';

  @override
  String get homeSensors => 'நேரடி சென்சார்கள்';

  @override
  String get homeTemperature => 'வெப்பநிலை';

  @override
  String get homeHumidity => 'ஈரப்பதம்';

  @override
  String get homeLiveSensors => 'நேரடி சென்சார்கள்';

  @override
  String get homeNoSensorData => 'சென்சார் தரவு இல்லை.';

  @override
  String get homeWeatherUnavailable => 'வானிலை கிடைக்கவில்லை';

  @override
  String get homeNoHealthData => 'சுகாதார தரவு இல்லை.';

  @override
  String get homeOverallScore => 'மொத்த மதிப்பெண்';

  @override
  String get homeScanned => 'ஸ்கேன் செய்யப்பட்டது';

  @override
  String get homeInfected => 'பாதிக்கப்பட்டுள்ளது';

  @override
  String get homeAvgRisk => 'சராசரி ஆபத்து';

  @override
  String get homeFailedLoadHealth => 'தரவை ஏற்ற முடியவில்லை';

  @override
  String get homeQuickActions => 'விரைவான செயல்கள்';

  @override
  String get homeScanCrop => 'பயிரை ஸ்கேன் செய்';

  @override
  String get homeAskGemma => 'Gemma-விடம் கேள்';

  @override
  String get twinLiveView => 'நேரடி காட்சி';

  @override
  String get twinPredictive => 'கணிப்பு பகுப்பாய்வு (அடுத்த 7 நாட்கள்)';

  @override
  String get twinSimulate => 'ட்வினை உருவகப்படுத்து';

  @override
  String get twinHealthHistory => 'ஆரோக்கிய வரலாறு';

  @override
  String get villageDashboard => 'கிராம நுண்ணறிவு';

  @override
  String get villageSummary => 'மாவட்ட சுருக்கம்';

  @override
  String get villageAlerts =>
      'செயலில் உள்ள வெடிப்புகள் மற்றும் விழிப்பூட்டல்கள்';

  @override
  String get chatGemma => 'Gemma AI உதவியாளர்';

  @override
  String get chatHint => 'உங்கள் பண்ணை அல்லது நோய்கள் பற்றி கேளுங்கள்...';

  @override
  String get chatOffline =>
      'முழுமையான தனியுரிமைக்காக ஜெம்மா உங்கள் சாதனத்தில் உள்ளூரில் இயங்குகிறது.';

  @override
  String get settingsProfile => 'பயனர் சுயவிவரம்';

  @override
  String get settingsLanguage => 'மொழி';

  @override
  String get settingsLocation => 'இடம் (நகரம்)';

  @override
  String get settingsConnection => 'பின்னணி இணைப்பு';

  @override
  String get btnSave => 'அமைப்புகளைச் சேமி';

  @override
  String get settingsSaved => 'அமைப்புகள் வெற்றிகரமாக சேமிக்கப்பட்டன';
}
