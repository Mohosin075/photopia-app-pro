import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get _isFr => locale.languageCode == 'fr';

  Future<String> translateDynamic(String text) async {
    if (!_isFr) return text;
    return text;
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  String get navHome => tr('navHome');
  String get navMessages => tr('navMessages');
  String get navSearch => tr('navSearch');
  String get navFavorites => tr('navFavorites');
  String get navProfile => tr('navProfile');

  // ── Common actions ────────────────────────────────────────────────────────
  String get save => tr('save');
  String get cancel => tr('cancel');
  String get add => tr('add');
  String get edit => tr('edit');
  String get close => tr('close');
  String get back => tr('back');
  String get clear => tr('clear');
  String get viewAll => tr('viewAll');
  String get viewAllOrders => tr('viewAllOrders');
  String get markAllAsRead => tr('markAllAsRead');
  String get pressBackToExit => tr('pressBackToExit');

  // ── Auth / Account ────────────────────────────────────────────────────────
  String get login => tr('login');
  String get signUp => tr('signUp');
  String get logOut => tr('logOut');
  String get logOutConfirm => tr('logOutConfirm');
  String get switchToProfessional => tr('switchToProfessional');

  // ── Profile ───────────────────────────────────────────────────────────────
  String get profile => tr('profile');
  String get editProfile => tr('editProfile');
  String get language => tr('language');
  String get selectLanguage => tr('selectLanguage');
  String get orderHistory => tr('orderHistory');
  String get notifications => tr('notifications');
  String get privacyPolicy => tr('privacyPolicy');
  String get privacySecurity => tr('privacySecurity');
  String get helpAndSupport => tr('helpAndSupport');
  String get settings => tr('settings');
  String get recentOrders => tr('recentOrders');
  String get noRecentOrders => tr('noRecentOrders');

  // ── Notifications ─────────────────────────────────────────────────────────
  String get noNotificationsAvailable => tr('noNotificationsAvailable');
  String unread(int count) => tr('unread', args: [count.toString()]);

  // ── Search / Categories ───────────────────────────────────────────────────
  String get browseCategories => tr('browseCategories');
  String get searchResults => tr('searchResults');
  String get noCategoriesFound => tr('noCategoriesFound');
  String get noSubcategoriesFound => tr('noSubcategoriesFound');
  String get noServicesFound => tr('noServicesFound');
  String get backToCategories => tr('backToCategories');
  String get categories => tr('categories');
  String get search => tr('search');
  String get searchHint => tr('searchHint');
  String get location => tr('location');
  String get searchLocationHint => tr('searchLocationHint');
  String radius(int km) => tr('radius', args: [km.toString()]);
  String budget(int start, int end) => tr('budget', args: [start.toString(), end.toString()]);
  String get typeOfService => tr('typeOfService');
  String get equipmentUsed => tr('equipmentUsed');
  String get applyFilters => tr('applyFilters');
  String get clearAll => tr('clearAll');
  String get recentSearches => tr('recentSearches');
  String get trendingCategories => tr('trendingCategories');
  String get searchResultsFor => tr('searchResultsFor');

  // ── Provider Profile ──────────────────────────────────────────────────────
  String get aboutMe => tr('aboutMe');
  String get languages => tr('languages');
  String get specializations => tr('specializations');
  String get portfolio => tr('portfolio');
  String get clientReviews => tr('clientReviews');
  String get noReviewsYet => tr('noReviewsYet');
  String get completedBookingsWillAppear => tr('completedBookingsWillAppear');
  String get rating => tr('rating');
  String get reviewsLabel => tr('reviewsLabel');
  String get responseRate => tr('responseRate');
  String get projects => tr('projects');
  String get documents => tr('documents');
  String get addPhoto => tr('addPhoto');
  String get selectALanguage => tr('selectALanguage');
  String get noDocumentsAdded => tr('noDocumentsAdded');
  String get selectLanguageToAdd => tr('selectLanguageToAdd');
  String get enterSpecialization => tr('enterSpecialization');
  String addTitle(String title) => tr('addTitle', args: [title]);

  // ── Home Page ─────────────────────────────────────────────────────────────
  String get originalProjects => tr('originalProjects');
  String get recentlyViewed => tr('recentlyViewed');
  String get ideasForProject => tr('ideasForProject');
  String get getInspired => tr('getInspired');
  String get superPros => tr('superPros');
  String get availableRightNow => tr('availableRightNow');
  String get nearYou => tr('nearYou');
  String get popularCategories => tr('popularCategories');
  String get mainCategories => tr('mainCategories');
  String get findYourStyle => tr('findYourStyle');
  String get trendingProjects => tr('trendingProjects');
  String get trendingThisWeek => tr('trendingThisWeek');
  String get unableToLoadHome => tr('unableToLoadHome');
  String get tryAgain => tr('tryAgain');
  String get noData => tr('noData');

  // ── Messages ──────────────────────────────────────────────────────────────
  String get noMessagesYet => tr('noMessagesYet');
  String get noMessagesDesc => tr('noMessagesDesc');
  String get searchConversations => tr('searchConversations');

  // ── Favorites ─────────────────────────────────────────────────────────────
  String favoritePostsCount(int count) => tr('favoritePostsCount', args: [count.toString()]);
  String favoriteProvidersCount(int count) => tr('favoriteProvidersCount', args: [count.toString()]);
  String get noFavoritePosts => tr('noFavoritePosts');
  String get noFavoriteProviders => tr('noFavoriteProviders');
  
  // ── Provider Navigation ───────────────────────────────────────────────────
  String get providerNavOrders => tr('providerNavOrders');
  String get providerNavCalendar => tr('providerNavCalendar');
  String get providerNavListing => tr('providerNavListing');
  String get providerNavMenu => tr('providerNavMenu');

  // ── Provider Overview / Dashboard ─────────────────────────────────────────
  String get myListings => tr('myListings');
  String get create => tr('create');
  String get active => tr('active');
  String get drafts => tr('drafts');
  String get past => tr('past');
  String noListingsFound(String status) => tr('noListingsFound', args: [status]);
  String get noTitle => tr('noTitle');
  String get noCategory => tr('noCategory');
  String viewsCount(int count) => tr('viewsCount', args: [count.toString()]);
  String bookingsCount(int count) => tr('bookingsCount', args: [count.toString()]);
  String get viewBtn => tr('viewBtn');
  String get editBtn => tr('editBtn');
  String get deleteConfirmation => tr('deleteConfirmation');
  String get areYouSureDelete => tr('areYouSureDelete');
  String get serviceDeletedSuccess => tr('serviceDeletedSuccess');
  String get deleteFailed => tr('deleteFailed');
  String get yes => tr('yes');
  String get no => tr('no');
  String get overallStatistics => tr('overallStatistics');
  String get total => tr('total');
  String get profilePhotoRequired => tr('profilePhotoRequired');
  String get profilePhotoRequiredDesc => tr('profilePhotoRequiredDesc');
  String get later => tr('later');
  
  // ── Provider Menu ─────────────────────────────────────────────────────────
  String get paymentsTransactions => tr('paymentsTransactions');
  String get detailedStatistics => tr('detailedStatistics');
  String get failedToContactAdmin => tr('failedToContactAdmin');
  String get switchToClient => tr('switchToClient');
  String get viewPublicProfile => tr('viewPublicProfile');
  String get bookingsTitle => tr('bookingsTitle');
  String bookingsThisWeek(int count) => tr('bookingsThisWeek', args: [count.toString()]);
  String get revenueTitle => tr('revenueTitle');
  String revenueVsLastMonth(num percent) => tr('revenueVsLastMonth', args: [percent.toString()]);
  String get profileViewsTitle => tr('profileViewsTitle');
  String get thisWeek => tr('thisWeek');
  String reviewCount(int count) => tr('reviewCount', args: [count.toString()]);
  String get premiumMember => tr('premiumMember');
  String get premiumPrice => tr('premiumPrice');
  String get premiumBenefits => tr('premiumBenefits');
  String get manageSubscription => tr('manageSubscription');

  // ── Provider Orders ───────────────────────────────────────────────────────
  String get tabToday => tr('tabToday');
  String get tabUpcoming => tr('tabUpcoming');
  String get tabPending => tr('tabPending');
  String get todaysBookings => tr('todaysBookings');
  String get noBookingsRightNow => tr('noBookingsRightNow');
  String get unknownClient => tr('unknownClient');
  String get unknownService => tr('unknownService');
  String get locationNA => tr('locationNA');
  String get notAvailable => tr('notAvailable');
  String get upcomingBookings => tr('upcomingBookings');
  String get noUpcomingBookings => tr('noUpcomingBookings');
  String get pendingApproval => tr('pendingApproval');
  String requestsCount(int count) => tr('requestsCount', args: [count.toString()]);
  String get noPendingRequests => tr('noPendingRequests');
  String get requestedRecently => tr('requestedRecently');
  String get viewDetails => tr('viewDetails');
  String get contactBtn => tr('contactBtn');
  String get detailsBtn => tr('detailsBtn');
  String get declineBtn => tr('declineBtn');
  String get acceptBtn => tr('acceptBtn');
  String get viewFullDetails => tr('viewFullDetails');
  String get clientInfoNotAvailable => tr('clientInfoNotAvailable');
  String get doYouWantToAccept => tr('doYouWantToAccept');
  String get doYouWantToDecline => tr('doYouWantToDecline');
  String get orderAcceptedSuccess => tr('orderAcceptedSuccess');
  String get orderDeclinedSuccess => tr('orderDeclinedSuccess');
  String get orderStatusUpdateFailed => tr('orderStatusUpdateFailed');

  // ── Provider Calendar ─────────────────────────────────────────────────────
  String get calendarAvailability => tr('calendarAvailability');
  String get viewWeek => tr('viewWeek');
  String get viewMonth => tr('viewMonth');
  String get viewYear => tr('viewYear');
  String get monthlySchedule => tr('monthlySchedule');
  String get noBookingsForDate => tr('noBookingsForDate');
  String get defaultBookingTitle => tr('defaultBookingTitle');
  String get defaultClientName => tr('defaultClientName');
  String get weeklyOverview => tr('weeklyOverview');
  String get upcomingThisWeek => tr('upcomingThisWeek');
  String get statusOn => tr('statusOn');
  String get statusOff => tr('statusOff');

  // ── Provider Statistics ───────────────────────────────────────────────────
  String get statisticsTitle => tr('statisticsTitle');
  String get monthlyRevenue => tr('monthlyRevenue');
  String vsLastMonth(num percent) => tr('vsLastMonth', args: [percent >= 0 ? '+' : '', percent.toString()]);
  String get viewsVsCategoryAvg => tr('viewsVsCategoryAvg');
  String get yourViews => tr('yourViews');
  String get categoryAverage => tr('categoryAverage');
  String performingAboveAvg(num percent) => _isFr ? 'Vous performez $percent% au-dessus de la moyenne' : 'You\'re performing $percent% above category average';
  String performingBelowAvg(num percent) => _isFr ? 'Vous performez $percent% en dessous de la moyenne' : 'You\'re performing $percent% below category average';
  String get ratingVsCategoryAvg => tr('ratingVsCategoryAvg');
  String get yourRating => tr('yourRating');
  String ratingHigherThanProviders(num percent) => tr('ratingHigherThanProviders', args: [percent.toString()]);
  String get profileViewsByRegion => tr('profileViewsByRegion');
  String get noRegionalData => tr('noRegionalData');
  String get totalViews => tr('totalViews');
  String get revenueAnalyticsTitle => tr('revenueAnalyticsTitle');
  String get currentMonth => tr('currentMonth');
  String vsPreviousMonth(num amount) => tr('vsPreviousMonth', args: [amount.toString()]);
  String get avgPerPeriod => tr('avgPerPeriod');
  String get bestPerforming => tr('bestPerforming');
  String get deepBusinessInsights => tr('deepBusinessInsights');
  String get conversionRate => tr('conversionRate');
  String get repeatRate => tr('repeatRate');
  String get mostViewedProject => tr('mostViewedProject');
  String get unlockInsights => tr('unlockInsights');
  String get upgradeSubscriptionDesc => tr('upgradeSubscriptionDesc');
  String get premiumFeature1 => tr('premiumFeature1');
  String get premiumFeature2 => tr('premiumFeature2');
  String get premiumFeature3 => tr('premiumFeature3');
  String get premiumFeature4 => tr('premiumFeature4');
  String get upgradeToPremium => tr('upgradeToPremium');
  String get exportFullReport => tr('exportFullReport');
  String get exportingBtn => tr('exportingBtn');
  String reportSavedTo(String path) => tr('reportSavedTo', args: [path]);
  String get filterWeek => tr('filterWeek');
  String get filterMonth => tr('filterMonth');
  String get filterQuarter => tr('filterQuarter');
  String get filterYear => tr('filterYear');

  // ── Provider Wallet ───────────────────────────────────────────────────────
  String get walletTitle => tr('walletTitle');
  String get thisMonth => tr('thisMonth');
  String get lastMonth => tr('lastMonth');
  String get allTransactions => tr('allTransactions');
  String get filterReceived => tr('filterReceived');
  String get filterUpcoming => tr('filterUpcoming');
  String get statusCompleted => tr('statusCompleted');
  String get statusPaidOut => tr('statusPaidOut');
  String get totalBalance => tr('totalBalance');
  String get balanceAvailable => tr('balanceAvailable');
  String get balancePending => tr('balancePending');
  String get requestPayout => tr('requestPayout');
  String get invoiceBtn => tr('invoiceBtn');

  // ── Provider Profile (extra) ──────────────────────────────────────────────
  String get profileTitle => tr('profileTitle');
  String get fullNameHint => tr('fullNameHint');
  String get bioTaglineHint => tr('bioTaglineHint');
  String get ratingLabel => tr('ratingLabel');
  String get responseRateLabel => tr('responseRateLabel');
  String get projectsLabel => tr('projectsLabel');
  String get aboutMeTitle => tr('aboutMeTitle');
  String get specializationsTitle => tr('specializationsTitle');
  String get languagesTitle => tr('languagesTitle');
  String get portfolioTitle => tr('portfolioTitle');
  String portfolioCount(int count) => tr('portfolioCount', args: [count.toString()]);
  String get addPhotoBtn => tr('addPhotoBtn');
  String get clientReviewsTitle => tr('clientReviewsTitle');
  String get completedBookingsWillAppearHere => tr('completedBookingsWillAppearHere');
  String get anonymous => tr('anonymous');
  String get enterSpecializationHint => tr('enterSpecializationHint');
  String get selectLanguageHint => tr('selectLanguageHint');
  String get selectLanguageDropdownHint => tr('selectLanguageDropdownHint');
  String get exPortraitPhotography => tr('exPortraitPhotography');
  String get cancelBtn => tr('cancelBtn');
  String get addBtn => tr('addBtn');
  String get documentsTitle => tr('documentsTitle');
  String get couldNotOpenDocument => tr('couldNotOpenDocument');
  String get profileUpdatedSuccess => tr('profileUpdatedSuccess');
  String itemsFailedToDelete(String error) => tr('itemsFailedToDelete', args: [error]);
  String get updateFailed => tr('updateFailed');

  // ── Client Order History ──────────────────────────────────────────────────
  String get orderHistoryTitle => tr('orderHistoryTitle');
  String get filterAllOrders => tr('filterAllOrders');
  String get statusCancelled => tr('statusCancelled');
  String get noOrdersFound => tr('noOrdersFound');
  String get serviceTitleDefault => tr('serviceTitleDefault');
  String get standardPackageDefault => tr('standardPackageDefault');
  String get providerNameDefault => tr('providerNameDefault');
  String get locationNotSet => tr('locationNotSet');

  // ── Authentication ──────────────────────────────────────────────────────────────
  String get logInToContinue => tr('logInToContinue');
  String get emailLabel => tr('emailLabel');
  String get emailHint => tr('emailHint');
  String get passwordLabel => tr('passwordLabel');
  String get forgotPassword => tr('forgotPassword');
  String get loginBtn => tr('loginBtn');
  String get loginSuccessful => tr('loginSuccessful');
  String get loginFailed => tr('loginFailed');
  String get validEmailPasswordRequired => tr('validEmailPasswordRequired');
  String get orContinueWith => tr('orContinueWith');
  String get noAccount => tr('noAccount');
  String get signUpLink => tr('signUpLink');
  String get createAccount => tr('createAccount');
  String get nameLabel => tr('nameLabel');
  String get signUpBtn => tr('signUpBtn');
  String get fillAllFields => tr('fillAllFields');
  String get registrationFailed => tr('registrationFailed');
  String get accountAlreadyExists => tr('accountAlreadyExists');
  String get alreadyHaveAccount => tr('alreadyHaveAccount');
  String get logInLink => tr('logInLink');
  String get forgotPasswordTitle => tr('forgotPasswordTitle');
  String get forgotPasswordSubtitle => tr('forgotPasswordSubtitle');
  String get sendBtn => tr('sendBtn');
  String get somethingWentWrong => tr('somethingWentWrong');
  String get didntReceiveCode => tr('didntReceiveCode');
  String get resendAgain => tr('resendAgain');
  String get otpVerificationTitle => tr('otpVerificationTitle');
  String get codeSubmit => tr('codeSubmit');
  String enterCodeSentTo(String email) => tr('enterCodeSentTo', args: [email]);
  String get submitBtn => tr('submitBtn');
  String get verificationSuccessful => tr('verificationSuccessful');
  String get verificationFailed => tr('verificationFailed');
  String get newPasswordTitle => tr('newPasswordTitle');
  String get newPasswordLabel => tr('newPasswordLabel');
  String get confirmPasswordLabel => tr('confirmPasswordLabel');
  String get passwordResetSuccess => tr('passwordResetSuccess');
  String get failedToResetPassword => tr('failedToResetPassword');

  // ── Onboarding / Role Selection ─────────────────────────────────────────────────
  String get howToUsePhotopia => tr('howToUsePhotopia');
  String get selectRoleToStart => tr('selectRoleToStart');
  String get roleClient => tr('roleClient');
  String get roleClientSubtitle => tr('roleClientSubtitle');
  String get roleProfessional => tr('roleProfessional');
  String get roleProfessionalSubtitle => tr('roleProfessionalSubtitle');

  // ── Service Details ────────────────────────────────────────────────────────
  String get serviceDetailsTitle => tr('serviceDetailsTitle');
  String get noDescriptionAvailable => tr('noDescriptionAvailable');
  String get providerLabel => tr('providerLabel');
  String get professional => tr('professional');
  String get responseTimeLabel => tr('responseTimeLabel');
  String get completedProjectsLabel => tr('completedProjectsLabel');
  String get aboutLabel => tr('aboutLabel');
  String get equipmentLabel => tr('equipmentLabel');
  String get messageBtn => tr('messageBtn');
  String get viewProfileBtn => tr('viewProfileBtn');
  String get bookNowBtn => tr('bookNowBtn');
  String reviewsCount(int count, double rating) => tr('reviewsCount', args: [rating.toString(), count.toString()]);

  // ── Mode Transition ────────────────────────────────────────────────────────
  String get switchingToProfessional => tr('switchingToProfessional');
  String get switchingToClient => tr('switchingToClient');
  String get failedToSwitchMode => tr('failedToSwitchMode');

  // ── Settings Screen ────────────────────────────────────────────────────
  String get settingsAccount => tr('settingsAccount');
  String get settingsPaymentMethod => tr('settingsPaymentMethod');
  String get settingsChangePassword => tr('settingsChangePassword');
  String get settingsAppearance => tr('settingsAppearance');
  String get settingsDarkMode => tr('settingsDarkMode');
  String get settingsLegal => tr('settingsLegal');
  String get settingsTermsOfService => tr('settingsTermsOfService');
  String get settingsHelpSupport => tr('settingsHelpSupport');
  String get settingsContact => tr('settingsContact');
  String get settingsContactSubtitle => tr('settingsContactSubtitle');
  String get settingsFaq => tr('settingsFaq');
  String get settingsFaqSubtitle => tr('settingsFaqSubtitle');
  String get settingsData => tr('settingsData');
  String get settingsDownloadData => tr('settingsDownloadData');
  String get settingsDangerZone => tr('settingsDangerZone');
  String get settingsDeactivateAccount => tr('settingsDeactivateAccount');
  String get settingsDeactivateConfirm => tr('settingsDeactivateConfirm');
  String get settingsDeactivate => tr('settingsDeactivate');
  String get settingsDeleteAccount => tr('settingsDeleteAccount');
  String get settingsDeleteConfirm => tr('settingsDeleteConfirm');
  String get settingsDelete => tr('settingsDelete');
  String get comingSoon => tr('comingSoon');
  
  // Extra keys for profile
  String get loading => tr('loading');
  String get detectingLocation => tr('detectingLocation');
  String get customLocation => tr('customLocation');
  String get unknownProvider => tr('unknownProvider');
  String get performanceStats => tr('performanceStats');
  String get deliveryLabel => tr('deliveryLabel');
  String get satisfactionLabel => tr('satisfactionLabel');
  String get availableForTravel => tr('availableForTravel');
  String get experience => tr('experience');
  String get education => tr('education');
  String get serviceArea => tr('serviceArea');
  String get cropProfilePicture => tr('cropProfilePicture');
  String get cropCoverPhoto => tr('cropCoverPhoto');
  String get enterNameHint => tr('enterNameHint');

  // Booking Confirmation Screen Localizations
  String stepXofY(String current, String total) => tr('stepXofY', args: [current, total]);
  String get selectDateAndTime => tr('selectDateAndTime');
  String get choosePreferredDateTimeSlot => tr('choosePreferredDateTimeSlot');
  String get timeSlots => tr('timeSlots');
  String get fullDay => tr('fullDay');
  String get availableDates => tr('availableDates');
  String get timeSlot => tr('timeSlot');
  String get locationDetails => tr('locationDetails');
  String get whereSessionTakePlace => tr('whereSessionTakePlace');
  String get locationAddress => tr('locationAddress');
  String get enterOrDetectLocation => tr('enterOrDetectLocation');
  String get specialRequestsOptional => tr('specialRequestsOptional');
  String get specialRequestsHint => tr('specialRequestsHint');
  String get selectAddons => tr('selectAddons');
  String get customizeBookingAddons => tr('customizeBookingAddons');
  String get reviewBooking => tr('reviewBooking');
  String get confirmBookingDetails => tr('confirmBookingDetails');
  String get depositRequiredToConfirm => tr('depositRequiredToConfirm');
  String get howDepositBillingWorks => tr('howDepositBillingWorks');
  String get payment => tr('payment');
  String get secureBookingPartialPayment => tr('secureBookingPartialPayment');
  String get completeBookingPayment => tr('completeBookingPayment');
  String get bookingConfirmed => tr('bookingConfirmed');
  String get bookingConfirmedSubtitle => tr('bookingConfirmedSubtitle');
  String get continueBtn => tr('continueBtn');
  String get payAndConfirm => tr('payAndConfirm');
  String payDepositAndConfirm(String amount) => tr('payDepositAndConfirm', args: [amount]);
  String get pleaseSelectDateFirst => tr('pleaseSelectDateFirst');
  String get pleaseSelectTimeSlot => tr('pleaseSelectTimeSlot');
  String get pleaseProvideLocationAddress => tr('pleaseProvideLocationAddress');
  String get pleaseLogInToContinue => tr('pleaseLogInToContinue');
  String get missingBookingDetails => tr('missingBookingDetails');
  String depositExplanation(String percent, String symbol, String amount, String balanceSymbol, String balanceAmount) =>
      tr('depositExplanation', args: [percent, symbol, amount, balanceSymbol, balanceAmount]);
  String depositStep1Explanation(String symbol, String amount, String percent) =>
      tr('depositStep1Explanation', args: [symbol, amount, percent]);
  String get depositStep2Explanation => tr('depositStep2Explanation');
  String depositStep3Explanation(String symbol, String amount) =>
      tr('depositStep3Explanation', args: [symbol, amount]);
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ── Extension for easy access anywhere ───────────────────────────────────────

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizations(const Locale('en'));
}
