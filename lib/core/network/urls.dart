class Urls {
  //live url -https://mohosin5003.binarybards.online
  static const String _rootUrl = 'http://10.10.26.173:5003';
  static const String baseUrl = '$_rootUrl/uploads';
  //local url - http://10.10.7.50:4003
  //authentication API
  static const String signUp = '$_rootUrl/api/v1/auth/signup';
  static const String signIn = '$_rootUrl/api/v1/auth/login';
  static const String logOut = '$_rootUrl/api/v1/auth/logout';
  static const String refreshToken = '$_rootUrl/api/v1/auth/refresh-token';
  static const String verifyOtp = '$_rootUrl/api/v1/auth/verify-account';
  static const String forgotPassword = '$_rootUrl/api/v1/auth/forget-password';
  static const String resetPassword = '$_rootUrl/api/v1/auth/reset-password';
  static const String changePassword = '$_rootUrl/api/v1/auth/change-password';
  static const String deleteAccount = '$_rootUrl/api/v1/auth/delete-account';
  static const String deactivateProfile = '$_rootUrl/api/v1/users/deactivate-profile';
  //user profile api
  static const String userProfile = '$_rootUrl/api/v1/users/profile';
  static String getUserById(String id) => '$_rootUrl/api/v1/users/$id';
  static const String updateUserProfile =
      '$_rootUrl/api/v1/users/profile'; // PATCH FOR UPDATE PROFILE
  static const String subscriptionPlans = '$_rootUrl/api/v1/subscription/plans';
  static const String createSubscription =
      '$_rootUrl/api/v1/subscription/create';

  //Role api
  static const String role = '$_rootUrl/api/v1/users/switch-role';

  //provider

  //** serivce api */
  static const String service = '$_rootUrl/api/v1/services';
  static const String professionalProfile =
      '$_rootUrl/api/v1/professional-profiles';
  static const String professionalProfileUpdate =
      '$_rootUrl/api/v1/professional-profile';
  static const String removeProfProfileItems =
      '$_rootUrl/api/v1/professional-profiles/remove-items';
  static String updateService(String id) => '$_rootUrl/api/v1/services/$id';
  static String deleteService(String id) => '$_rootUrl/api/v1/services/$id';
  static String toggleServiceStatus(String id) =>
      '$_rootUrl/api/v1/services/$id/status';
  static String getServicesByProvider(String providerId) =>
      '$_rootUrl/api/v1/services/provider/$providerId';
  //Calender and availibility
  static const String calenderSettings = '$_rootUrl/api/v1/availability';
  //get provider availibility
  static String getProviderAvailability(String providerId) =>
      '$_rootUrl/api/v1/availability/$providerId';
  static String getMonthCalendar(String providerId, int month, int year) =>
      '$_rootUrl/api/v1/availability/calendar/$providerId?month=$month&year=$year';
  static String getTimeSlots(String providerId, String date, int duration) =>
      '$_rootUrl/api/v1/availability/slots/$providerId?date=$date&duration=$duration';

  static const String myListingApi = '$_rootUrl/api/v1/services/my/services';
  static const String getPrivacyPolicy =
      '$_rootUrl/api/v1/public/privacy-policy';
  static String getSingleList(String id) => '$_rootUrl/api/v1/services/$id';
  static String getMyOrders({String? filterType, String? status}) {
    String url = '$_rootUrl/api/v1/booking/my-bookings';
    List<String> queries = [];
    if (filterType != null) queries.add('filterType=$filterType');
    if (status != null) queries.add('status=$status');
    if (queries.isNotEmpty) {
      url += '?${queries.join('&')}';
    }
    return url;
  }

  static String getSingleBooking(String id) => '$_rootUrl/api/v1/booking/$id';
  static String getBookingsByDate(String date) =>
      '$_rootUrl/api/v1/booking/my-bookings-by-date?date=$date';

  //--------------------------------------User site api----------------------------------------------------------

  //** user service */
  static const String userService = '';
  static const String home = '$_rootUrl/api/v1/home';
  static const String inspiration = '$_rootUrl/api/v1/inspiration';

  static const String getMyNotification = '$_rootUrl/api/v1/notifications/my';
  static const String getNotificationStats =
      '$_rootUrl/api/v1/notifications/stats';
  static const String markAllNotificationsAsRead =
      '$_rootUrl/api/v1/notifications/read-all';
  static String markSingleNotificationAsRead(String id) =>
      '$_rootUrl/api/v1/notifications/$id/read';

  //get all service from provider
  static const String getAllservice = '$_rootUrl/api/v1/services';
  //toggle fav api
  static const String toggleFav = "$_rootUrl/api/v1/favourite/toggle";
  static const String getFavorites = "$_rootUrl/api/v1/favourite/my-favourites";
  //** category api */
  static const String categories = '$_rootUrl/api/v1/category';
  static const String popularCategories =
      '$_rootUrl/api/v1/category/popular-categories';

  //** review api */
  static String getReviewsByProvider(String providerId) =>
      '$_rootUrl/api/v1/review/provider/$providerId';

  //** wallet api */
  static const String myWallet = '$_rootUrl/api/v1/wallet/my-wallet';
  static const String createWithdrawal = '$_rootUrl/api/v1/withdrawal';

  //** chat api */
  static const String chat = '$_rootUrl/api/v1/chat';
  static String getMessages(String chatId) =>
      '$_rootUrl/api/v1/message/$chatId';
  static const String sendMessage = '$_rootUrl/api/v1/message';
  static String createChat(String otherUserId) =>
      '$_rootUrl/api/v1/chat/$otherUserId';
  static const String contactAdmin = '$_rootUrl/api/v1/chat/contact-admin';

  static const String statistics =
      '$_rootUrl/api/v1/professional-profiles/statistics';
  static const String statisticsExport =
      '$_rootUrl/api/v1/professional-profiles/statistics/export';

  //** payment api */
  static const String createCheckoutSession =
      '$_rootUrl/api/v1/payment/create-checkout-session';
  static const String createPaymentIntent =
      '$_rootUrl/api/v1/payment/create-payment-intent';
  static const String myPayments = '$_rootUrl/api/v1/payment/my-payments';
  static const String createSetupIntent =
      '$_rootUrl/api/v1/payment/create-setup-intent';
  static const String paymentMethods = '$_rootUrl/api/v1/payment/methods';
  static String setDefaultPaymentMethod(String id) =>
      '$_rootUrl/api/v1/payment/methods/$id/default';
  static String deletePaymentMethod(String id) =>
      '$_rootUrl/api/v1/payment/methods/$id';

  static const String createBooking = '$_rootUrl/api/v1/booking';
  static const String calculateBookingPrice =
      '$_rootUrl/api/v1/booking/calculate-price';

  static String updateBookingStatus(String id) =>
      '$_rootUrl/api/v1/booking/$id/status';

  static String modifyOffer(String id) =>
      '$_rootUrl/api/v1/booking/$id/modify-offer';
  static String payBalance(String id) =>
      '$_rootUrl/api/v1/booking/$id/pay-balance';

  //public api
  static const String termsAndConditions =
      '$_rootUrl/api/v1/public/terms-and-condition';

  // Stripe Connect api
  static const String stripeConnectStatus =
      '$_rootUrl/api/v1/users/stripe-connect-status';
  static const String stripeOnboarding =
      '$_rootUrl/api/v1/users/stripe-connect-onboarding';

  // Location API (Backend)
  static const String locationSearch = '$_rootUrl/api/v1/locations/search';
  static const String locationGeocode = '$_rootUrl/api/v1/locations/geocode';
}
