import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('te')];

  /// No description provided for @appName.
  ///
  /// In te, this message translates to:
  /// **'EasySave'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In te, this message translates to:
  /// **'మీ సులభమైన సేవ్ యాప్'**
  String get appTagline;

  /// No description provided for @saveContactLabel.
  ///
  /// In te, this message translates to:
  /// **'కొత్త నంబర్ దాచుకోండి'**
  String get saveContactLabel;

  /// No description provided for @saveContactSub.
  ///
  /// In te, this message translates to:
  /// **'కొత్త నంబర్ రాసుకోవడానికి'**
  String get saveContactSub;

  /// No description provided for @sharePhotoLabel.
  ///
  /// In te, this message translates to:
  /// **'ఫోటో పంపండి'**
  String get sharePhotoLabel;

  /// No description provided for @sharePhotoSub.
  ///
  /// In te, this message translates to:
  /// **'వాట్సాప్ లో ఫోటో పంపండి'**
  String get sharePhotoSub;

  /// No description provided for @enterNumber.
  ///
  /// In te, this message translates to:
  /// **'నంబర్ ఎంటర్ చేయండి'**
  String get enterNumber;

  /// No description provided for @nextButton.
  ///
  /// In te, this message translates to:
  /// **'తర్వాత'**
  String get nextButton;

  /// No description provided for @speakName.
  ///
  /// In te, this message translates to:
  /// **'పేరు చెప్పండి'**
  String get speakName;

  /// No description provided for @pressMicPrompt.
  ///
  /// In te, this message translates to:
  /// **'పై బటన్ నొక్కి పేరు చెప్పండి'**
  String get pressMicPrompt;

  /// No description provided for @listeningLabel.
  ///
  /// In te, this message translates to:
  /// **'వింటున్నాను...'**
  String get listeningLabel;

  /// No description provided for @hearingLabel.
  ///
  /// In te, this message translates to:
  /// **'విన్నది: '**
  String get hearingLabel;

  /// No description provided for @isCorrectQuestion.
  ///
  /// In te, this message translates to:
  /// **'ఇది కరెక్టేనా?'**
  String get isCorrectQuestion;

  /// No description provided for @yesButton.
  ///
  /// In te, this message translates to:
  /// **'అవును'**
  String get yesButton;

  /// No description provided for @tryAgainButton.
  ///
  /// In te, this message translates to:
  /// **'మళ్ళీ చెప్పండి'**
  String get tryAgainButton;

  /// No description provided for @typeWithKeyboard.
  ///
  /// In te, this message translates to:
  /// **'కీబోర్డ్ తో టైప్ చేయండి'**
  String get typeWithKeyboard;

  /// No description provided for @confirmLabel.
  ///
  /// In te, this message translates to:
  /// **'సరిచూసుకోండి'**
  String get confirmLabel;

  /// No description provided for @saveButton.
  ///
  /// In te, this message translates to:
  /// **'సేవ్ చేయండి'**
  String get saveButton;

  /// No description provided for @savedSuccess.
  ///
  /// In te, this message translates to:
  /// **'సేవ్ అయింది!'**
  String get savedSuccess;

  /// No description provided for @backButton.
  ///
  /// In te, this message translates to:
  /// **'వెనక్కి'**
  String get backButton;

  /// No description provided for @goHome.
  ///
  /// In te, this message translates to:
  /// **'హోమ్ కి వెళ్ళండి'**
  String get goHome;

  /// No description provided for @choosePhoto.
  ///
  /// In te, this message translates to:
  /// **'ఫోటో ఎంచుకోండి'**
  String get choosePhoto;

  /// No description provided for @recentPhotos.
  ///
  /// In te, this message translates to:
  /// **'కొత్త ఫోటోలు'**
  String get recentPhotos;

  /// No description provided for @sendThisPhoto.
  ///
  /// In te, this message translates to:
  /// **'ఈ ఫోటో పంపండి'**
  String get sendThisPhoto;

  /// No description provided for @whoToSend.
  ///
  /// In te, this message translates to:
  /// **'ఎవరికి పంపించాలి?'**
  String get whoToSend;

  /// No description provided for @whatsappWillSend.
  ///
  /// In te, this message translates to:
  /// **'WhatsApp లో పంపిస్తాము'**
  String get whatsappWillSend;

  /// No description provided for @whatsappNotInstalled.
  ///
  /// In te, this message translates to:
  /// **'WhatsApp ఇన్స్టాల్ అయిలేదు'**
  String get whatsappNotInstalled;

  /// No description provided for @installWhatsapp.
  ///
  /// In te, this message translates to:
  /// **'WhatsApp ఇన్స్టాల్ చేయండి'**
  String get installWhatsapp;

  /// No description provided for @saveContactFirst.
  ///
  /// In te, this message translates to:
  /// **'ముందు నంబర్ సేవ్ చేయండి'**
  String get saveContactFirst;

  /// No description provided for @noPhotosFound.
  ///
  /// In te, this message translates to:
  /// **'ఫోటోలు దొరకలేదు'**
  String get noPhotosFound;

  /// No description provided for @generalErrorMessage.
  ///
  /// In te, this message translates to:
  /// **'తప్పు జరిగింది, మళ్ళీ ప్రయత్నించండి'**
  String get generalErrorMessage;

  /// No description provided for @speechNotRecognized.
  ///
  /// In te, this message translates to:
  /// **'అర్థం కాలేదు, మళ్ళీ చెప్పండి'**
  String get speechNotRecognized;

  /// No description provided for @permissionContactsExplanation.
  ///
  /// In te, this message translates to:
  /// **'మీ ఫోన్ లోని కాంటాక్ట్స్ చూడడానికి అనుమతి అడుగుతున్నాము'**
  String get permissionContactsExplanation;

  /// No description provided for @permissionWriteExplanation.
  ///
  /// In te, this message translates to:
  /// **'కొత్త నంబర్లు సేవ్ చేయడానికి అనుమతి అడుగుతున్నాము'**
  String get permissionWriteExplanation;

  /// No description provided for @permissionPhotosExplanation.
  ///
  /// In te, this message translates to:
  /// **'ఫోటోలు చూడటానికి అనుమతి అడుగుతున్నాం'**
  String get permissionPhotosExplanation;

  /// No description provided for @permissionMicExplanation.
  ///
  /// In te, this message translates to:
  /// **'మీ పేరు వినడానికి మైక్ అనుమతి అడుగుతున్నాం'**
  String get permissionMicExplanation;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In te, this message translates to:
  /// **'అనుమతి ఇవ్వకపోతే ఇది పని చేయదు'**
  String get permissionDeniedMessage;

  /// No description provided for @openSettings.
  ///
  /// In te, this message translates to:
  /// **'సెట్టింగ్స్ తెరవండి'**
  String get openSettings;

  /// No description provided for @teluguSpeechMissing.
  ///
  /// In te, this message translates to:
  /// **'తెలుగు వాయిస్ ప్యాక్ డౌన్లోడ్ చేయండి'**
  String get teluguSpeechMissing;

  /// No description provided for @viewMyContacts.
  ///
  /// In te, this message translates to:
  /// **'నా ఫోన్ నంబర్లు'**
  String get viewMyContacts;

  /// No description provided for @viewMyContactsSub.
  ///
  /// In te, this message translates to:
  /// **'ఫోన్ బుక్ చూడడానికి, మార్చడానికి'**
  String get viewMyContactsSub;

  /// No description provided for @searchContactsHint.
  ///
  /// In te, this message translates to:
  /// **'ఇక్కడ పేరు టైప్ చేసి వెతకండి...'**
  String get searchContactsHint;

  /// No description provided for @contactDetailsTitle.
  ///
  /// In te, this message translates to:
  /// **'పరిచయం వివరాలు'**
  String get contactDetailsTitle;

  /// No description provided for @callNowButton.
  ///
  /// In te, this message translates to:
  /// **'ఫోన్ చేయండి'**
  String get callNowButton;

  /// No description provided for @renameButton.
  ///
  /// In te, this message translates to:
  /// **'పేరు మార్చండి'**
  String get renameButton;

  /// No description provided for @deleteButton.
  ///
  /// In te, this message translates to:
  /// **'తీసేయండి'**
  String get deleteButton;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In te, this message translates to:
  /// **'డిలీట్ చేయాలా?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In te, this message translates to:
  /// **'మీరు నిజంగా నిశ్చయంగా డిలీట్ చేయాలనుకుంటున్నారా?'**
  String get deleteConfirmMessage;

  /// No description provided for @editContactTitle.
  ///
  /// In te, this message translates to:
  /// **'వివరాలు మార్చండి'**
  String get editContactTitle;

  /// No description provided for @editNameLabel.
  ///
  /// In te, this message translates to:
  /// **'పేరు'**
  String get editNameLabel;

  /// No description provided for @editPhoneLabel.
  ///
  /// In te, this message translates to:
  /// **'ఫోన్ నంబర్'**
  String get editPhoneLabel;

  /// No description provided for @contactUpdatedSuccess.
  ///
  /// In te, this message translates to:
  /// **'వివరాలు మార్చబడ్డాయి!'**
  String get contactUpdatedSuccess;

  /// No description provided for @contactDeletedSuccess.
  ///
  /// In te, this message translates to:
  /// **'పరిచయం తీసివేయబడింది!'**
  String get contactDeletedSuccess;

  /// No description provided for @cancelButton.
  ///
  /// In te, this message translates to:
  /// **'రద్దు చేయి'**
  String get cancelButton;

  /// No description provided for @recentCallsTitle.
  ///
  /// In te, this message translates to:
  /// **'వచ్చిన ఫోన్ కాల్స్'**
  String get recentCallsTitle;

  /// No description provided for @noCallLogs.
  ///
  /// In te, this message translates to:
  /// **'ఫోన్ కాల్స్ ఏమీ లేవు'**
  String get noCallLogs;

  /// No description provided for @callFailed.
  ///
  /// In te, this message translates to:
  /// **'ఫోన్ చేయడం కుదరలేదు'**
  String get callFailed;

  /// No description provided for @callPermissionNeeded.
  ///
  /// In te, this message translates to:
  /// **'ఫోన్ చేయడానికి అనుమతి ఇవ్వాలి'**
  String get callPermissionNeeded;

  /// No description provided for @permissionRequired.
  ///
  /// In te, this message translates to:
  /// **'అనుమతి ఇవ్వండి'**
  String get permissionRequired;

  /// No description provided for @callLogPermissionExplanation.
  ///
  /// In te, this message translates to:
  /// **'ఇక్కడ మీకు వచ్చిన ఫోన్ కాల్స్ చూసుకోవడానికి మరియు ఫోన్ చేయడానికి అనుమతి ఇవ్వండి.'**
  String get callLogPermissionExplanation;

  /// No description provided for @grantPermission.
  ///
  /// In te, this message translates to:
  /// **'అనుమతి ఇవ్వండి'**
  String get grantPermission;

  /// No description provided for @saveCallText.
  ///
  /// In te, this message translates to:
  /// **'సేవ్ చేసుకోండి'**
  String get saveCallText;

  /// No description provided for @unsavedNumber.
  ///
  /// In te, this message translates to:
  /// **'సేవ్ చేయని నంబర్'**
  String get unsavedNumber;

  /// No description provided for @settingsTitle.
  ///
  /// In te, this message translates to:
  /// **'సెట్టింగ్స్ & సమాచారం'**
  String get settingsTitle;

  /// No description provided for @developerCredits.
  ///
  /// In te, this message translates to:
  /// **'Developed by Santosh Reddy'**
  String get developerCredits;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In te, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyText.
  ///
  /// In te, this message translates to:
  /// **'EasySave is committed to protecting your privacy. This application operates entirely offline under your direct control. We do not collect, store, transmit, or share any personal data, contacts, call logs, or photos. All data processing occurs locally on your device, ensuring complete security and absolute confidentiality.'**
  String get privacyPolicyText;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In te, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// No description provided for @termsOfServiceText.
  ///
  /// In te, this message translates to:
  /// **'By using EasySave, you agree that all contact directories, call histories, and media transmission tools are managed exclusively offline on your local device. The application is provided on an \'as-is\' and \'as-available\' basis without any warranties. There are no remote database connections, analytics tracking, or third-party cloud integrations.'**
  String get termsOfServiceText;

  /// No description provided for @closeButton.
  ///
  /// In te, this message translates to:
  /// **'మూసివేయి'**
  String get closeButton;
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
      <String>['te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
