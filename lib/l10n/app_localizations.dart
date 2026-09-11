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
  /// **'కొత్త నంబర్ సేవ్ చేయండి'**
  String get saveContactLabel;

  /// No description provided for @saveContactSub.
  ///
  /// In te, this message translates to:
  /// **'కొత్త నంబర్ సేవ్ చేసుకోవడానికి'**
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
  /// **'ఫోన్ నంబర్ ఇవ్వండి'**
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
  /// **'మైక్ నొక్కి పేరు చెప్పండి'**
  String get pressMicPrompt;

  /// No description provided for @listeningLabel.
  ///
  /// In te, this message translates to:
  /// **'వింటున్నాము...'**
  String get listeningLabel;

  /// No description provided for @hearingLabel.
  ///
  /// In te, this message translates to:
  /// **'మీరు చెప్పిన పేరు: '**
  String get hearingLabel;

  /// No description provided for @isCorrectQuestion.
  ///
  /// In te, this message translates to:
  /// **'ఇది సరిగ్గా ఉందా?'**
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
  /// **'గ్యాలరీ ఫోటోలు'**
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
  /// **'వాట్సాప్ లో పంపిస్తాము'**
  String get whatsappWillSend;

  /// No description provided for @whatsappNotInstalled.
  ///
  /// In te, this message translates to:
  /// **'వాట్సాప్ ఇన్స్టాల్ అయిలేదు'**
  String get whatsappNotInstalled;

  /// No description provided for @installWhatsapp.
  ///
  /// In te, this message translates to:
  /// **'వాట్సాప్ ఇన్స్టాల్ చేయండి'**
  String get installWhatsapp;

  /// No description provided for @saveContactFirst.
  ///
  /// In te, this message translates to:
  /// **'ముందుగా నంబర్ సేవ్ చేయండి'**
  String get saveContactFirst;

  /// No description provided for @noPhotosFound.
  ///
  /// In te, this message translates to:
  /// **'ఫోటోలు ఏమీ లేవు'**
  String get noPhotosFound;

  /// No description provided for @generalErrorMessage.
  ///
  /// In te, this message translates to:
  /// **'సమస్య వచ్చింది, మళ్ళీ ప్రయత్నించండి'**
  String get generalErrorMessage;

  /// No description provided for @speechNotRecognized.
  ///
  /// In te, this message translates to:
  /// **'అర్థం కాలేదు, మళ్ళీ చెప్పండి'**
  String get speechNotRecognized;

  /// No description provided for @permissionContactsExplanation.
  ///
  /// In te, this message translates to:
  /// **'మీ ఫోన్ లోని కాంటాక్ట్స్ చూడటానికి అనుమతి కావాలి'**
  String get permissionContactsExplanation;

  /// No description provided for @permissionWriteExplanation.
  ///
  /// In te, this message translates to:
  /// **'కొత్త నంబర్లు సేవ్ చేయడానికి అనుమతి కావాలి'**
  String get permissionWriteExplanation;

  /// No description provided for @permissionPhotosExplanation.
  ///
  /// In te, this message translates to:
  /// **'ఫోటోలు పంపడానికి అనుమతి కావాలి'**
  String get permissionPhotosExplanation;

  /// No description provided for @permissionMicExplanation.
  ///
  /// In te, this message translates to:
  /// **'పేరు వినడానికి మైక్రోఫోన్ అనుమతి కావాలి'**
  String get permissionMicExplanation;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In te, this message translates to:
  /// **'అనుమతి ఇవ్వకపోతే ఈ సదుపాయం పని చేయదు'**
  String get permissionDeniedMessage;

  /// No description provided for @openSettings.
  ///
  /// In te, this message translates to:
  /// **'సెట్టింగ్స్ తెరవండి'**
  String get openSettings;

  /// No description provided for @teluguSpeechMissing.
  ///
  /// In te, this message translates to:
  /// **'తెలుగు వాయిస్ ప్యాక్ డౌన్లోడ్ చేసుకోండి'**
  String get teluguSpeechMissing;

  /// No description provided for @viewMyContacts.
  ///
  /// In te, this message translates to:
  /// **'నా కాంటాక్ట్స్'**
  String get viewMyContacts;

  /// No description provided for @viewMyContactsSub.
  ///
  /// In te, this message translates to:
  /// **'ఫోన్ బుక్ చూడడానికి, మాట్లాడడానికి'**
  String get viewMyContactsSub;

  /// No description provided for @searchContactsHint.
  ///
  /// In te, this message translates to:
  /// **'పేరు లేదా నంబర్ వెతకండి...'**
  String get searchContactsHint;

  /// No description provided for @contactDetailsTitle.
  ///
  /// In te, this message translates to:
  /// **'కాంటాక్ట్ వివరాలు'**
  String get contactDetailsTitle;

  /// No description provided for @callNowButton.
  ///
  /// In te, this message translates to:
  /// **'కాల్ చేయండి'**
  String get callNowButton;

  /// No description provided for @whatsappChatButton.
  ///
  /// In te, this message translates to:
  /// **'వాట్సాప్ మెసేజ్'**
  String get whatsappChatButton;

  /// No description provided for @renameButton.
  ///
  /// In te, this message translates to:
  /// **'పేరు మార్చండి'**
  String get renameButton;

  /// No description provided for @deleteButton.
  ///
  /// In te, this message translates to:
  /// **'డిలీట్ చేయండి'**
  String get deleteButton;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In te, this message translates to:
  /// **'డిలీట్ చేయాలా?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In te, this message translates to:
  /// **'ఈ కాంటాక్ట్‌ను డిలీట్ చేయాలనుకుంటున్నారా?'**
  String get deleteConfirmMessage;

  /// No description provided for @editContactTitle.
  ///
  /// In te, this message translates to:
  /// **'వివరాలు మార్చండి'**
  String get editContactTitle;

  /// No description provided for @addContactTitle.
  ///
  /// In te, this message translates to:
  /// **'కొత్త కాంటాక్ట్'**
  String get addContactTitle;

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
  /// **'వివరాలు సేవ్ అయ్యాయి!'**
  String get contactUpdatedSuccess;

  /// No description provided for @contactDeletedSuccess.
  ///
  /// In te, this message translates to:
  /// **'కాంటాక్ట్ డిలీట్ అయింది!'**
  String get contactDeletedSuccess;

  /// No description provided for @cancelButton.
  ///
  /// In te, this message translates to:
  /// **'రద్దు'**
  String get cancelButton;

  /// No description provided for @recentCallsTitle.
  ///
  /// In te, this message translates to:
  /// **'ఇటీవలి కాల్స్'**
  String get recentCallsTitle;

  /// No description provided for @viewAllCalls.
  ///
  /// In te, this message translates to:
  /// **'అన్నీ చూడండి'**
  String get viewAllCalls;

  /// No description provided for @allCalls.
  ///
  /// In te, this message translates to:
  /// **'అన్నీ'**
  String get allCalls;

  /// No description provided for @missedCalls.
  ///
  /// In te, this message translates to:
  /// **'మిస్డ్ కాల్స్'**
  String get missedCalls;

  /// No description provided for @incomingCall.
  ///
  /// In te, this message translates to:
  /// **'వచ్చిన కాల్'**
  String get incomingCall;

  /// No description provided for @outgoingCall.
  ///
  /// In te, this message translates to:
  /// **'చేసిన కాల్'**
  String get outgoingCall;

  /// No description provided for @missedCall.
  ///
  /// In te, this message translates to:
  /// **'మిస్డ్ కాల్'**
  String get missedCall;

  /// No description provided for @rejectedCall.
  ///
  /// In te, this message translates to:
  /// **'కట్ చేసిన కాల్'**
  String get rejectedCall;

  /// No description provided for @noCallLogs.
  ///
  /// In te, this message translates to:
  /// **'కాల్స్ ఏమీ లేవు'**
  String get noCallLogs;

  /// No description provided for @callFailed.
  ///
  /// In te, this message translates to:
  /// **'కాల్ చేయడం కుదరలేదు'**
  String get callFailed;

  /// No description provided for @callPermissionNeeded.
  ///
  /// In te, this message translates to:
  /// **'కాల్ చేయడానికి అనుమతి ఇవ్వాలి'**
  String get callPermissionNeeded;

  /// No description provided for @permissionRequired.
  ///
  /// In te, this message translates to:
  /// **'అనుమతి అవసరం'**
  String get permissionRequired;

  /// No description provided for @callLogPermissionExplanation.
  ///
  /// In te, this message translates to:
  /// **'మీ కాల్ హిస్టరీ చూడటానికి మరియు డైరెక్ట్ కాల్ చేయడానికి అనుమతి ఇవ్వండి.'**
  String get callLogPermissionExplanation;

  /// No description provided for @grantPermission.
  ///
  /// In te, this message translates to:
  /// **'అనుమతి ఇవ్వండి'**
  String get grantPermission;

  /// No description provided for @saveCallText.
  ///
  /// In te, this message translates to:
  /// **'సేవ్ చేయండి'**
  String get saveCallText;

  /// No description provided for @unsavedNumber.
  ///
  /// In te, this message translates to:
  /// **'సేవ్ చేయని నంబర్'**
  String get unsavedNumber;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In te, this message translates to:
  /// **'పేస్ట్ చేయండి'**
  String get pasteFromClipboard;

  /// No description provided for @keyboardToggleTooltip.
  ///
  /// In te, this message translates to:
  /// **'కీబోర్డ్ మార్చండి'**
  String get keyboardToggleTooltip;

  /// No description provided for @clearText.
  ///
  /// In te, this message translates to:
  /// **'తుడిచివేయి'**
  String get clearText;

  /// No description provided for @invalidPhoneError.
  ///
  /// In te, this message translates to:
  /// **'సరైన ఫోన్ నంబర్ ఇవ్వండి (7-12 అంకెలు)'**
  String get invalidPhoneError;

  /// No description provided for @invalidNameError.
  ///
  /// In te, this message translates to:
  /// **'పేరు చెప్పండి లేదా టైప్ చేయండి'**
  String get invalidNameError;

  /// No description provided for @contactSavedToast.
  ///
  /// In te, this message translates to:
  /// **'కాంటాక్ట్ విజయవంతంగా సేవ్ అయింది!'**
  String get contactSavedToast;

  /// No description provided for @settingsTitle.
  ///
  /// In te, this message translates to:
  /// **'సెట్టింగ్స్ & సమాచారం'**
  String get settingsTitle;

  /// No description provided for @developerCredits.
  ///
  /// In te, this message translates to:
  /// **'Developed with ❤️ by Santosh Reddy'**
  String get developerCredits;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In te, this message translates to:
  /// **'గోప్యతా విధానం (Privacy Policy)'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyText.
  ///
  /// In te, this message translates to:
  /// **'EasySave మీ గోప్యతను గౌరవిస్తుంది. ఈ యాప్ పూర్తిగా మీ ఫోన్ లోనే పనిచేస్తుంది (100% ఆఫ్‌లైన్). మీ నంబర్లు, కాల్స్, ఫోటోలు ఏ సర్వర్‌కు పంపబడవు. పూర్తి భద్రత మరియు నమ్మకం.'**
  String get privacyPolicyText;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In te, this message translates to:
  /// **'నిబంధనలు (Terms of Service)'**
  String get termsOfServiceTitle;

  /// No description provided for @termsOfServiceText.
  ///
  /// In te, this message translates to:
  /// **'EasySave యాప్‌ను మీ వ్యక్తిగత ఉపయోగం కోసం నేరుగా వాడుకోవచ్చు. ఇది పూర్తిగా ఆఫ్‌లైన్ సాధనం.'**
  String get termsOfServiceText;

  /// No description provided for @closeButton.
  ///
  /// In te, this message translates to:
  /// **'సరే'**
  String get closeButton;

  /// No description provided for @appUpdate.
  ///
  /// In te, this message translates to:
  /// **'యాప్ అప్‌డేట్'**
  String get appUpdate;

  /// No description provided for @checkForUpdates.
  ///
  /// In te, this message translates to:
  /// **'అప్‌డేట్ తనిఖీ చేయండి'**
  String get checkForUpdates;

  /// No description provided for @checkingForUpdates.
  ///
  /// In te, this message translates to:
  /// **'తనిఖీ చేస్తున్నాము...'**
  String get checkingForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In te, this message translates to:
  /// **'మీ యాప్ సరికొత్త వెర్షన్‌లో ఉంది'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In te, this message translates to:
  /// **'కొత్త వెర్షన్ అందుబాటులో ఉంది!'**
  String get updateAvailable;

  /// No description provided for @updateDownloaded.
  ///
  /// In te, this message translates to:
  /// **'అప్‌డేట్ సిద్ధంగా ఉంది. యాప్‌ను రీస్టార్ట్ చేయండి.'**
  String get updateDownloaded;

  /// No description provided for @updateNow.
  ///
  /// In te, this message translates to:
  /// **'ఇప్పుడే అప్‌డేట్ చేయండి'**
  String get updateNow;

  /// No description provided for @restartToUpdate.
  ///
  /// In te, this message translates to:
  /// **'ఇప్పుడే రీస్టార్ట్ చేయండి'**
  String get restartToUpdate;

  /// No description provided for @downloadingUpdate.
  ///
  /// In te, this message translates to:
  /// **'అప్‌డేట్ డౌన్‌లోడ్ అవుతోంది...'**
  String get downloadingUpdate;

  /// No description provided for @updateError.
  ///
  /// In te, this message translates to:
  /// **'అప్‌డేట్ వివరాలు పొందలేకపోయాము. ప్లే స్టోర్‌లో చూడండి.'**
  String get updateError;

  /// No description provided for @openInPlayStore.
  ///
  /// In te, this message translates to:
  /// **'ప్లే స్టోర్‌లో తెరవండి'**
  String get openInPlayStore;

  /// No description provided for @versionLabel.
  ///
  /// In te, this message translates to:
  /// **'ప్రస్తుత వెర్షన్'**
  String get versionLabel;

  /// No description provided for @noContactFoundTitle.
  ///
  /// In te, this message translates to:
  /// **'కాంటాక్ట్ దొరకలేదు'**
  String get noContactFoundTitle;

  /// No description provided for @noContactFoundSubtitle.
  ///
  /// In te, this message translates to:
  /// **'మీరు వెతికిన పేరు లేదా నంబర్‌తో కాంటాక్ట్ లేదు.'**
  String get noContactFoundSubtitle;

  /// No description provided for @saveAsNewContactAction.
  ///
  /// In te, this message translates to:
  /// **'కొత్త కాంటాక్ట్‌గా సేవ్ చేయండి'**
  String get saveAsNewContactAction;

  /// No description provided for @clearSearchAction.
  ///
  /// In te, this message translates to:
  /// **'శోధన క్లియర్ చేయండి'**
  String get clearSearchAction;

  /// No description provided for @similarContactsHeader.
  ///
  /// In te, this message translates to:
  /// **'సారూప్య కాంటాక్ట్స్ (ఇవి కూడా చూడండి)'**
  String get similarContactsHeader;

  /// No description provided for @exactMatchesHeader.
  ///
  /// In te, this message translates to:
  /// **'దొరికిన కాంటాక్ట్స్'**
  String get exactMatchesHeader;

  /// No description provided for @searchTipsTitle.
  ///
  /// In te, this message translates to:
  /// **'సులభమైన సూచనలు:'**
  String get searchTipsTitle;

  /// No description provided for @searchTip1.
  ///
  /// In te, this message translates to:
  /// **'పేరులోని మొదటి 2-3 అక్షరాలను టైప్ చేయండి'**
  String get searchTip1;

  /// No description provided for @searchTip2.
  ///
  /// In te, this message translates to:
  /// **'మైక్రోఫోన్ బటన్ నొక్కి పేరును స్పష్టంగా చెప్పండి'**
  String get searchTip2;

  /// No description provided for @searchRecipientHint.
  ///
  /// In te, this message translates to:
  /// **'ఎవరికి పంపాలో పేరు లేదా నంబర్ వెతకండి...'**
  String get searchRecipientHint;

  /// No description provided for @voiceSearchListeningPrompt.
  ///
  /// In te, this message translates to:
  /// **'పేరు లేదా నంబర్ స్పష్టంగా చెప్పండి...'**
  String get voiceSearchListeningPrompt;

  /// No description provided for @unknownNumber.
  ///
  /// In te, this message translates to:
  /// **'తెలియని నంబర్'**
  String get unknownNumber;

  /// No description provided for @callButtonTooltip.
  ///
  /// In te, this message translates to:
  /// **'కాల్ చేయండి'**
  String get callButtonTooltip;

  /// No description provided for @noRecentCallsSub.
  ///
  /// In te, this message translates to:
  /// **'మీరు చేసిన లేదా వచ్చిన కాల్స్ ఇక్కడ కనిపిస్తాయి.'**
  String get noRecentCallsSub;

  /// No description provided for @noContactsSub.
  ///
  /// In te, this message translates to:
  /// **'మీ ప్రియమైన వారి నంబర్లను సులభంగా సేవ్ చేసుకోండి.'**
  String get noContactsSub;

  /// No description provided for @viewContactsAction.
  ///
  /// In te, this message translates to:
  /// **'కాంటాక్ట్స్ చూడండి'**
  String get viewContactsAction;

  /// No description provided for @callInitiated.
  ///
  /// In te, this message translates to:
  /// **'కాల్ కనెక్ట్ అవుతోంది...'**
  String get callInitiated;
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
