// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'AgriTwin AI';

  @override
  String get splashTagline => 'AI-संचालित खेती, ऑफ़लाइन और आपकी भाषा में';

  @override
  String get loginTitle => 'किसान लॉगिन';

  @override
  String get loginSubtitle =>
      'अपनी स्थानीय कृषि प्रोफ़ाइल बनाएं या एक्सेस करें';

  @override
  String get name => 'नाम';

  @override
  String get nameHint => 'अपना नाम दर्ज करें';

  @override
  String get phone => 'फ़ोन नंबर / किसान आईडी';

  @override
  String get phoneHint => 'फ़ोन या किसान आईडी दर्ज करें';

  @override
  String get pin => 'सुरक्षा पिन';

  @override
  String get pinHint => '4-अंकीय पिन दर्ज करें';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get soilSnapshot => 'मिट्टी का स्नैपशॉट';

  @override
  String get nitrogen => 'नाइट्रोजन (N)';

  @override
  String get phosphorus => 'फास्फोरस (P)';

  @override
  String get potassium => 'पोटेशियम (K)';

  @override
  String get moisture => 'नमी';

  @override
  String get connected => 'जुड़ा हुआ';

  @override
  String get offline => 'ऑफ़लाइन';

  @override
  String lastUpdated(Object time) {
    return 'अंतिम अपडेट: $time';
  }

  @override
  String get takePhoto => 'फोटो लें';

  @override
  String get gallery => 'गैलरी खोलें';

  @override
  String get dashboard => 'डिजिटल ट्विन';

  @override
  String get fieldHealthScore => 'खेत स्वास्थ्य स्कोर';

  @override
  String get healthTrend => 'स्वास्थ्य रुझान';

  @override
  String get topRiskFactor => 'शीर्ष जोखिम कारक';

  @override
  String get whatIfSimulator => 'क्या-अगर सिम्युलेटर';

  @override
  String get simulateIrrigation => 'आज सिंचाई का अनुकरण करें';

  @override
  String get addField => 'नया खेत जोड़ें';

  @override
  String get selectField => 'खेत चुनें';

  @override
  String get result => 'निदान परिणाम';

  @override
  String get disease => 'फसल रोग';

  @override
  String get confidence => 'विश्वास स्कोर';

  @override
  String get remedyAdvice => 'स्थानीयकृत एआई उपाय';

  @override
  String get listenAdvice => 'उपाय सुनें';

  @override
  String get askFollowUp => 'एक अनुवर्ती प्रश्न पूछें...';

  @override
  String get scanHistory => 'स्कैन इतिहास';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterByField => 'खेत द्वारा फ़िल्टर करें';

  @override
  String get filterByDisease => 'रोग द्वारा फ़िल्टर करें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get backendIP => 'बैकएंड सर्वर आईपी / पता';

  @override
  String get testConnection => 'कनेक्शन का परीक्षण करें';

  @override
  String get defaultLanguage => 'डिफ़ॉल्ट भाषा';

  @override
  String get manageFields => 'खेतों/प्लॉटों का प्रबंधन करें';

  @override
  String get switchFarmer => 'किसान बदलें / लॉग आउट करें';

  @override
  String get connectionSuccess => 'कनेक्शन सफल!';

  @override
  String get connectionFailed => 'कनेक्शन विफल। कृपया आईपी जांचें।';

  @override
  String get testingConnection => 'कनेक्शन का परीक्षण हो रहा है...';

  @override
  String get listen => 'सुनो';

  @override
  String get stop => 'रुको';

  @override
  String simulatedLabel(Object score) {
    return 'अनुमानित अनुमानित स्कोर: $score';
  }

  @override
  String get landingTitle => 'AgriTwin AI';

  @override
  String get landingDesc =>
      'खेत के स्वास्थ्य और डिजिटल ट्विन्स के प्रबंधन के लिए आपका व्यक्तिगत एआई सहायक।';

  @override
  String get onboardingRealtime => 'रीयल-टाइम निगरानी';

  @override
  String get onboardingRealtimeDesc =>
      'वास्तविक समय में नमी, पोषक तत्वों और मौसम की स्थिति की निगरानी करें।';

  @override
  String get onboardingDisease => 'रोग का पता लगाना';

  @override
  String get onboardingDiseaseDesc =>
      'रोगों का तुरंत पता लगाने और उपचार की सिफारिशें प्राप्त करने के लिए फसलों को स्कैन करें।';

  @override
  String get onboardingGemma => 'Gemma AI';

  @override
  String get onboardingGemmaDesc =>
      'व्यक्तिगत कृषि सलाह प्राप्त करने के लिए हमारे उन्नत ऑफ़लाइन एआई के साथ चैट करें।';

  @override
  String get btnGetStarted => 'शुरू करें';

  @override
  String get btnNext => 'अगला';

  @override
  String get loginWelcome => 'वापसी पर स्वागत है';

  @override
  String get loginSetupProfile => 'जारी रखने के लिए अपनी प्रोफ़ाइल सेट करें';

  @override
  String get loginHintName => 'आपका नाम';

  @override
  String get loginHintFarm => 'खेत का नाम';

  @override
  String get loginHintLocation => 'स्थान (शहर)';

  @override
  String get btnContinue => 'जारी रखें';

  @override
  String get loadingTwin => 'आपका डिजिटल ट्विन सेट किया जा रहा है...';

  @override
  String get navHome => 'होम';

  @override
  String get navTwin => 'डिजिटल ट्विन';

  @override
  String get navVillage => 'गाँव';

  @override
  String get navChat => 'चैट';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String homeWelcomeBack(String userName) {
    return 'वापसी पर स्वागत है, $userName';
  }

  @override
  String get homeOfflineMode => 'ऑफ़लाइन मोड - कैश्ड डेटा दिखा रहा है';

  @override
  String get homeFarmHealth => 'समग्र खेत का स्वास्थ्य';

  @override
  String get homeSensors => 'लाइव सेंसर';

  @override
  String get homeTemperature => 'तापमान';

  @override
  String get homeHumidity => 'नमी';

  @override
  String get homeLiveSensors => 'लाइव सेंसर';

  @override
  String get homeNoSensorData => 'कोई सेंसर डेटा नहीं।';

  @override
  String get homeWeatherUnavailable => 'मौसम अनुपलब्ध';

  @override
  String get homeNoHealthData => 'कोई स्वास्थ्य डेटा नहीं।';

  @override
  String get homeOverallScore => 'कुल स्कोर';

  @override
  String get homeScanned => 'स्कैन किया गया';

  @override
  String get homeInfected => 'संक्रमित';

  @override
  String get homeAvgRisk => 'औसत जोखिम';

  @override
  String get homeFailedLoadHealth => 'स्वास्थ्य डेटा लोड करने में विफल';

  @override
  String get homeQuickActions => 'त्वरित कार्रवाइयां';

  @override
  String get homeScanCrop => 'फसल स्कैन करें';

  @override
  String get homeAskGemma => 'Gemma से पूछें';

  @override
  String get twinLiveView => 'लाइव दृश्य';

  @override
  String get twinPredictive => 'भविष्य कहनेवाला विश्लेषिकी (अगले 7 दिन)';

  @override
  String get twinSimulate => 'ट्विन का अनुकरण करें';

  @override
  String get twinHealthHistory => 'स्वास्थ्य इतिहास';

  @override
  String get villageDashboard => 'ग्राम खुफिया';

  @override
  String get villageSummary => 'जिला सारांश';

  @override
  String get villageAlerts => 'सक्रिय प्रकोप और अलर्ट';

  @override
  String get chatGemma => 'Gemma AI सहायक';

  @override
  String get chatHint => 'अपने खेत या बीमारियों के बारे में पूछें...';

  @override
  String get chatOffline =>
      'पूर्ण गोपनीयता के लिए Gemma आपके डिवाइस पर स्थानीय रूप से चल रहा है।';

  @override
  String get settingsProfile => 'उपयोगकर्ता प्रोफ़ाइल';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsLocation => 'स्थान (शहर)';

  @override
  String get settingsConnection => 'बैकएंड कनेक्शन';

  @override
  String get btnSave => 'सेटिंग्स सहेजें';

  @override
  String get settingsSaved => 'सेटिंग्स सफलतापूर्वक सहेजी गईं';
}
