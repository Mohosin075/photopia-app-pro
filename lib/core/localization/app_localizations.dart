import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get _isEs => locale.languageCode == 'es';

  Future<String> translateDynamic(String text) async {
    if (!_isEs) return text;
    return text;
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  String get navHome => _isEs ? 'Accueil' : 'Home';
  String get navMessages => 'Messages';
  String get navSearch => _isEs ? 'Rechercher' : 'Search';
  String get navFavorites => _isEs ? 'Favoris' : 'Favorites';
  String get navProfile => _isEs ? 'Profil' : 'Profile';

  // ── Common actions ────────────────────────────────────────────────────────
  String get save => _isEs ? 'Enregistrer' : 'Save';
  String get cancel => _isEs ? 'Annuler' : 'Cancel';
  String get add => _isEs ? 'Ajouter' : 'Add';
  String get edit => _isEs ? 'Modifier' : 'Edit';
  String get close => _isEs ? 'Fermer' : 'Close';
  String get back => _isEs ? 'Retour' : 'Back';
  String get clear => _isEs ? 'Effacer' : 'Clear';
  String get viewAll => _isEs ? 'Voir tout' : 'View All';
  String get viewAllOrders =>
      _isEs ? 'Voir toutes les commandes' : 'View All Orders';
  String get markAllAsRead =>
      _isEs ? 'Tout marquer comme lu' : 'Mark all as read';
  String get pressBackToExit =>
      _isEs ? 'Appuyez à nouveau pour quitter' : 'Press back again to exit';

  // ── Auth / Account ────────────────────────────────────────────────────────
  String get login => _isEs ? 'Connexion' : 'Login';
  String get signUp => _isEs ? "S'inscrire" : 'Sign Up';
  String get logOut => _isEs ? 'Déconnexion' : 'Log Out';
  String get logOutConfirm => _isEs
      ? 'Êtes-vous sûr de vouloir vous déconnecter ?'
      : 'Are you sure you want to log out of your account?';
  String get switchToProfessional =>
      _isEs ? 'Passer en professionnel' : 'Switch to Professional';

  // ── Profile ───────────────────────────────────────────────────────────────
  String get profile => _isEs ? 'Profil' : 'Profile';
  String get editProfile => _isEs ? 'Modifier le profil' : 'Edit Profile';
  String get language => _isEs ? 'Langue' : 'Language';
  String get selectLanguage =>
      _isEs ? 'Sélectionner la langue' : 'Select Language';
  String get orderHistory =>
      _isEs ? 'Historique des commandes' : 'Order History';
  String get notifications => _isEs ? 'Notifications' : 'Notifications';
  String get privacyPolicy =>
      _isEs ? 'Politique de confidentialité' : 'Privacy Policy';
  String get helpAndSupport => _isEs ? 'Aide & Support' : 'Help & Support';
  String get settings => _isEs ? 'Paramètres' : 'Settings';
  String get recentOrders =>
      _isEs ? 'Commandes récentes' : 'Recent Orders';
  String get noRecentOrders =>
      _isEs ? 'Aucune commande récente' : 'No recent orders';

  // ── Notifications ─────────────────────────────────────────────────────────
  String get noNotificationsAvailable =>
      _isEs ? 'Aucune notification disponible.' : 'No notifications available.';
  String unread(int count) => _isEs ? '$count non lus' : '$count unread';

  // ── Search / Categories ───────────────────────────────────────────────────
  String get browseCategories =>
      _isEs ? 'Parcourir les catégories' : 'Browse Categories';
  String get searchResults =>
      _isEs ? 'Résultats de recherche' : 'Search Results';
  String get noCategoriesFound =>
      _isEs ? 'Aucune catégorie trouvée' : 'No categories found';
  String get noSubcategoriesFound => _isEs
      ? 'Aucune sous-catégorie trouvée'
      : 'No subcategories found for this category';
  String get noServicesFound =>
      _isEs ? 'Aucun service trouvé' : 'No services found';
  String get backToCategories =>
      _isEs ? 'Retour aux catégories' : 'Back to Categories';
  String get categories => _isEs ? 'Catégories' : 'Categories';

  // ── Provider Profile ──────────────────────────────────────────────────────
  String get aboutMe => _isEs ? 'À propos de moi' : 'About Me';
  String get languages => _isEs ? 'Langues' : 'Languages';
  String get specializations =>
      _isEs ? 'Spécialisations' : 'Specializations';
  String get portfolio => _isEs ? 'Portfolio' : 'Portfolio';
  String get clientReviews => _isEs ? 'Avis clients' : 'Client Reviews';
  String get noReviewsYet =>
      _isEs ? "Aucun avis pour l'instant" : 'No reviews yet';
  String get completedBookingsWillAppear => _isEs
      ? 'Les réservations terminées apparaîtront ici'
      : 'Completed bookings will appear here';
  String get rating => _isEs ? 'Note' : 'Rating';
  String get reviewsLabel => _isEs ? 'Avis' : 'Reviews';
  String get responseRate => _isEs ? 'Réponse' : 'Response\nRate';
  String get projects => _isEs ? 'Projets' : 'Projects';
  String get documents => _isEs ? 'Documents' : 'Documents';
  String get addPhoto => _isEs ? 'Ajouter une photo' : 'Add Photo';
  String get selectALanguage =>
      _isEs ? 'Sélectionner une langue' : 'Select a language';
  String get noDocumentsAdded =>
      _isEs ? 'Aucun document ajouté.' : 'No documents added yet.';
  String get selectLanguageToAdd => _isEs
      ? 'Sélectionnez une langue à ajouter à votre profil.'
      : 'Select a language to add to your profile.';
  String get enterSpecialization => _isEs
      ? 'Saisissez la spécialisation à ajouter.'
      : 'Enter the specialization you want to add.';
  String addTitle(String title) => _isEs ? 'Ajouter $title' : 'Add $title';

  // ── Home Page ─────────────────────────────────────────────────────────────
  String get originalProjects => _isEs ? 'Projets originaux' : 'Original Projects';
  String get recentlyViewed => _isEs ? 'Récemment consultés' : 'Recently Viewed';
  String get getInspired => _isEs ? 'Laissez-vous inspirer' : 'Get Inspired';
  String get superPros => _isEs ? 'Super Pros' : 'Super Pros';
  String get availableRightNow => _isEs ? 'Disponible en ce moment' : 'Available Right Now';
  String get unableToLoadHome => _isEs ? 'Impossible de charger l\'accueil' : 'Unable to load home';
  String get tryAgain => _isEs ? 'Réessayer' : 'Try Again';
  String get noData => _isEs ? 'Aucune donnée' : 'No Data';

  // ── Messages ──────────────────────────────────────────────────────────────
  String get noMessagesYet => _isEs ? 'Aucun message pour le moment' : 'No Messages Yet';
  String get noMessagesDesc => _isEs 
      ? 'Lorsque vous commencez une conversation, elle apparaîtra ici. Commencez à explorer pour vous connecter !' 
      : 'When you start a conversation, it will appear here. Start exploring to connect!';
  String get searchConversations => _isEs ? 'Rechercher des conversations...' : 'Search conversations...';

  // ── Favorites ─────────────────────────────────────────────────────────────
  String favoritePostsCount(int count) => _isEs ? 'Annonces ($count)' : 'Posts ($count)';
  String favoriteProvidersCount(int count) => _isEs ? 'Prestataires ($count)' : 'Providers ($count)';
  String get noFavoritePosts => _isEs ? 'Aucune annonce favorite pour le moment' : 'No favorite posts yet';
  String get noFavoriteProviders => _isEs ? 'Aucun prestataire favori pour le moment' : 'No favorite providers yet';
  
  // ── Provider Navigation ───────────────────────────────────────────────────
  String get providerNavOrders => _isEs ? 'Commandes' : 'Orders';
  String get providerNavCalendar => _isEs ? 'Calendrier' : 'Calendar';
  String get providerNavListing => _isEs ? 'Annonces' : 'Listing';
  String get providerNavMenu => _isEs ? 'Menu' : 'Menu';

  // ── Provider Overview / Dashboard ─────────────────────────────────────────
  String get myListings => _isEs ? 'Mes annonces' : 'My Listings';
  String get create => _isEs ? 'Créer' : 'Create';
  String get active => _isEs ? 'Actif' : 'Active';
  String get drafts => _isEs ? 'Brouillons' : 'Drafts';
  String get past => _isEs ? 'Passé' : 'Past';
  String noListingsFound(String status) => _isEs ? 'Aucune annonce $status trouvée' : 'No $status listings found';
  String get noTitle => _isEs ? 'Sans titre' : 'No Title';
  String get noCategory => _isEs ? 'Aucune catégorie' : 'No Category';
  String viewsCount(int count) => _isEs ? '$count vues' : '$count views';
  String bookingsCount(int count) => _isEs ? '$count réservations' : '$count bookings';
  String get viewBtn => _isEs ? 'Voir' : 'View';
  String get editBtn => _isEs ? 'Modifier' : 'Edit';
  String get deleteConfirmation => _isEs ? 'Confirmation de suppression' : 'Delete Confirmation';
  String get areYouSureDelete => _isEs ? 'Êtes-vous sûr de vouloir supprimer ceci ?' : 'Are you sure you want to delete this?';
  String get serviceDeletedSuccess => _isEs ? 'Service supprimé avec succès' : 'Service deleted successfully';
  String get deleteFailed => _isEs ? 'Échec de la suppression' : 'Delete failed';
  String get yes => _isEs ? 'Oui' : 'Yes';
  String get no => _isEs ? 'Non' : 'No';
  String get overallStatistics => _isEs ? 'Statistiques globales' : 'Overall Statistics';
  String get total => _isEs ? 'Total' : 'Total';
  String get profilePhotoRequired => _isEs ? 'Photo de profil requise' : 'Profile Photo Required';
  String get profilePhotoRequiredDesc => _isEs 
      ? 'Vous devez ajouter une photo de profil avant de pouvoir créer une annonce. Les clients font confiance aux créateurs qu\'ils peuvent voir !' 
      : 'You need to add a profile photo before you can create a service listing. Clients trust creators they can see!';
  String get later => _isEs ? 'Plus tard' : 'Later';
  
  // ── Provider Menu ─────────────────────────────────────────────────────────
  String get paymentsTransactions => _isEs ? 'Paiements & Transactions' : 'Payments & Transactions';
  String get detailedStatistics => _isEs ? 'Statistiques détaillées' : 'Detailed Statistics';
  String get failedToContactAdmin => _isEs ? 'Échec de la connexion avec l\'admin' : 'Failed to contact admin';
  String get switchToClient => _isEs ? 'Passer en mode client' : 'Switch to Client';
  String get viewPublicProfile => _isEs ? 'Voir le profil public' : 'View Public Profile';
  String get bookingsTitle => _isEs ? 'Réservations' : 'Bookings';
  String bookingsThisWeek(int count) => _isEs ? '+$count cette semaine' : '+$count this week';
  String get revenueTitle => _isEs ? 'Revenus' : 'Revenue';
  String revenueVsLastMonth(num percent) => _isEs ? '+$percent% vs mois dernier' : '+$percent% vs last month';
  String get profileViewsTitle => _isEs ? 'Vues du profil' : 'Profile Views';
  String get thisWeek => _isEs ? 'cette semaine' : 'this week';
  String reviewCount(int count) => _isEs ? '$count avis' : '$count reviews';
  String get premiumMember => _isEs ? 'Membre Premium' : 'Premium Member';
  String get premiumPrice => _isEs ? '€10/mois' : '€10/month';
  String get premiumBenefits => _isEs ? 'Classement prioritaire • Analyses avancées • Badge premium' : 'Priority search placement • Extended analytics • Premium badge';
  String get manageSubscription => _isEs ? 'Gérer l\'abonnement' : 'Manage Subscription';

  // ── Provider Orders ───────────────────────────────────────────────────────
  String get tabToday => _isEs ? 'Aujourd\'hui' : 'Today';
  String get tabUpcoming => _isEs ? 'À venir' : 'Upcoming';
  String get tabPending => _isEs ? 'En attente' : 'Pending';
  String get todaysBookings => _isEs ? 'Réservations du jour' : 'Today\'s Bookings';
  String get noBookingsRightNow => _isEs ? 'Aucune réservation pour le moment' : 'No bookings right now';
  String get unknownClient => _isEs ? 'Client inconnu' : 'Unknown Client';
  String get unknownService => _isEs ? 'Service inconnu' : 'Unknown Service';
  String get locationNA => _isEs ? 'Emplacement N/D' : 'Location N/A';
  String get notAvailable => _isEs ? 'N/D' : 'N/A';
  String get upcomingBookings => _isEs ? 'Réservations à venir' : 'Upcoming Bookings';
  String get noUpcomingBookings => _isEs ? 'Aucune réservation à venir' : 'No upcoming bookings';
  String get pendingApproval => _isEs ? 'En attente d\'approbation' : 'Pending Approval';
  String requestsCount(int count) => _isEs ? '$count demandes' : '$count requests';
  String get noPendingRequests => _isEs ? 'Aucune demande en attente' : 'No pending requests';
  String get requestedRecently => _isEs ? 'Demandé récemment' : 'Requested recently';
  String get viewDetails => _isEs ? 'Voir les détails' : 'View Details';
  String get contactBtn => _isEs ? 'Contacter' : 'Contact';
  String get detailsBtn => _isEs ? 'Détails' : 'Details';
  String get declineBtn => _isEs ? 'Refuser' : 'Decline';
  String get acceptBtn => _isEs ? 'Accepter' : 'Accept';
  String get viewFullDetails => _isEs ? 'Voir tous les détails' : 'View Full Details';
  String get clientInfoNotAvailable => _isEs ? 'Informations client non disponibles' : 'Client information not available';
  String get doYouWantToAccept => _isEs ? 'Voulez-vous accepter ceci ?' : 'Do you want to accept this?';
  String get doYouWantToDecline => _isEs ? 'Voulez-vous refuser ceci ?' : 'Do you want to decline this?';
  String get orderAcceptedSuccess => _isEs ? 'Commande acceptée avec succès !' : 'Order accepted successfully!';
  String get orderDeclinedSuccess => _isEs ? 'Commande refusée avec succès !' : 'Order declined successfully!';
  String get orderStatusUpdateFailed => _isEs ? 'Échec de la mise à jour du statut' : 'Failed to update order status';

  // ── Provider Calendar ─────────────────────────────────────────────────────
  String get calendarAvailability => _isEs ? 'Calendrier et Disponibilités' : 'Calendar & Availability';
  String get viewWeek => _isEs ? 'Semaine' : 'Week';
  String get viewMonth => _isEs ? 'Mois' : 'Month';
  String get viewYear => _isEs ? 'Année' : 'Year';
  String get monthlySchedule => _isEs ? 'Planning mensuel' : 'Monthly Schedule';
  String get noBookingsForDate => _isEs ? 'Aucune réservation pour cette date' : 'No bookings for this date';
  String get defaultBookingTitle => _isEs ? 'Réservation' : 'Booking';
  String get defaultClientName => _isEs ? 'Client' : 'Client';
  String get weeklyOverview => _isEs ? 'Aperçu hebdomadaire' : 'Weekly Overview';
  String get upcomingThisWeek => _isEs ? 'À venir cette semaine' : 'Upcoming this week';
  String get statusOn => _isEs ? 'ON' : 'ON';
  String get statusOff => _isEs ? 'OFF' : 'OFF';

  // ── Provider Statistics ───────────────────────────────────────────────────
  String get statisticsTitle => _isEs ? 'Statistiques' : 'Statistics';
  String get monthlyRevenue => _isEs ? 'Revenu mensuel' : 'Monthly Revenue';
  String vsLastMonth(num percent) => _isEs ? '${percent >= 0 ? "+" : ""}$percent% vs mois dernier' : '${percent >= 0 ? "+" : ""}$percent% vs last month';
  String get viewsVsCategoryAvg => _isEs ? 'Vues vs Moyenne de la catégorie' : 'Views vs Category Average';
  String get yourViews => _isEs ? 'Vos vues' : 'Your Views';
  String get categoryAverage => _isEs ? 'Moyenne de la catégorie' : 'Category Average';
  String performingAboveAvg(num percent) => _isEs ? 'Vous performez $percent% au-dessus de la moyenne' : 'You\'re performing $percent% above category average';
  String performingBelowAvg(num percent) => _isEs ? 'Vous performez $percent% en dessous de la moyenne' : 'You\'re performing $percent% below category average';
  String get ratingVsCategoryAvg => _isEs ? 'Note vs Moyenne de la catégorie' : 'Rating vs Category Average';
  String get yourRating => _isEs ? 'Votre note' : 'Your Rating';
  String ratingHigherThanProviders(num percent) => _isEs ? 'Votre note est $percent% supérieure aux autres' : 'Your rating is $percent% higher than similar providers';
  String get profileViewsByRegion => _isEs ? 'Vues par région' : 'Profile Views by Region';
  String get noRegionalData => _isEs ? 'Aucune donnée régionale' : 'No regional data available';
  String get totalViews => _isEs ? 'Vues totales' : 'Total Views';
  String get revenueAnalyticsTitle => _isEs ? 'Analyses des revenus' : 'Revenue Analytics';
  String get currentMonth => _isEs ? 'Mois en cours' : 'Current Month';
  String vsPreviousMonth(num amount) => _isEs ? 'vs mois précédent: €$amount' : 'vs previous month: €$amount';
  String get avgPerPeriod => _isEs ? 'Moyenne par période' : 'Average per period';
  String get bestPerforming => _isEs ? 'Meilleure performance' : 'Best performing';
  String get deepBusinessInsights => _isEs ? 'Analyses commerciales approfondies' : 'Deep Business Insights';
  String get conversionRate => _isEs ? 'Taux de conversion' : 'Conversion Rate';
  String get repeatRate => _isEs ? 'Taux de répétition' : 'Repeat Rate';
  String get mostViewedProject => _isEs ? 'Projet le plus vu' : 'Most Viewed Project';
  String get unlockInsights => _isEs ? 'Débloquer les analyses' : 'Unlock Insights';
  String get upgradeSubscriptionDesc => _isEs 
      ? 'Améliorez votre abonnement pour accéder aux analyses avancées incluant :' 
      : 'Upgrade your subscription to get access to advanced business analytics including:';
  String get premiumFeature1 => _isEs ? 'Suivi régional détaillé' : 'Deep regional profile view tracking';
  String get premiumFeature2 => _isEs ? 'Répartition hebdomadaire' : 'Weekly revenue breakdowns';
  String get premiumFeature3 => _isEs ? 'Taux de conversion' : 'Business Conversion rates';
  String get premiumFeature4 => _isEs ? 'Analyses de la valeur moyenne' : 'Average order value analytics';
  String get upgradeToPremium => _isEs ? 'Passer à Premium' : 'Upgrade to Premium';
  String get exportFullReport => _isEs ? 'Exporter le rapport' : 'Export Full Report';
  String get exportingBtn => _isEs ? 'Exportation...' : 'Exporting...';
  String reportSavedTo(String path) => _isEs ? 'Rapport enregistré sous : $path' : 'Report saved to: $path';
  String get filterWeek => _isEs ? 'Semaine' : 'Week';
  String get filterMonth => _isEs ? 'Mois' : 'Month';
  String get filterQuarter => _isEs ? 'Trimestre' : 'Quarter';
  String get filterYear => _isEs ? 'Année' : 'Year';

  // ── Provider Wallet ───────────────────────────────────────────────────────
  String get walletTitle => _isEs ? 'Portefeuille' : 'Wallet';
  String get thisMonth => _isEs ? 'Ce mois-ci' : 'This Month';
  String get lastMonth => _isEs ? 'Mois dernier' : 'Last Month';
  String get allTransactions => _isEs ? 'Toutes les transactions' : 'All Transactions';
  String get filterReceived => _isEs ? 'Reçu' : 'Received';
  String get filterUpcoming => _isEs ? 'À venir' : 'Upcoming';
  String get statusCompleted => _isEs ? 'Terminé' : 'Completed';
  String get statusPaidOut => _isEs ? 'Payé' : 'Paid Out';
  String get totalBalance => _isEs ? 'Solde total' : 'Total Balance';
  String get balanceAvailable => _isEs ? 'Disponible' : 'Available';
  String get balancePending => _isEs ? 'En attente' : 'Pending';
  String get requestPayout => _isEs ? 'Demander un paiement' : 'Request Payout';
  String get invoiceBtn => _isEs ? 'Facture' : 'Invoice';

  // ── Provider Profile (extra) ──────────────────────────────────────────────
  String get profileTitle => _isEs ? 'Profil' : 'Profile';
  String get fullNameHint => _isEs ? 'Nom complet' : 'Full Name';
  String get bioTaglineHint => _isEs ? 'Slogan (ex: Photographe de mariage)' : 'Bio Tagline (e.g. Wedding Photographer)';
  String get ratingLabel => _isEs ? 'Note' : 'Rating';
  String get responseRateLabel => _isEs ? 'Taux de\nRéponse' : 'Response\nRate';
  String get projectsLabel => _isEs ? 'Projets' : 'Projects';
  String get aboutMeTitle => _isEs ? 'À propos de moi' : 'About Me';
  String get specializationsTitle => _isEs ? 'Spécialisations' : 'Specializations';
  String get languagesTitle => _isEs ? 'Langues' : 'Languages';
  String get portfolioTitle => _isEs ? 'Portfolio' : 'Portfolio';
  String portfolioCount(int count) => _isEs ? 'Portfolio ($count)' : 'Portfolio ($count)';
  String get addPhotoBtn => _isEs ? 'Ajouter' : 'Add Photo';
  String get clientReviewsTitle => _isEs ? 'Avis clients' : 'Client Reviews';
  String get completedBookingsWillAppearHere => _isEs ? 'Les réservations terminées apparaîtront ici' : 'Completed bookings will appear here';
  String get anonymous => _isEs ? 'Anonyme' : 'Anonymous';
  String get enterSpecializationHint => _isEs ? 'Entrez la spécialisation à ajouter.' : 'Enter the specialization you want to add.';
  String get selectLanguageHint => _isEs ? 'Sélectionnez une langue à ajouter à votre profil.' : 'Select a language to add to your profile.';
  String get selectLanguageDropdownHint => _isEs ? 'Sélectionner une langue' : 'Select a language';
  String get exPortraitPhotography => _isEs ? 'ex: Photographie de portrait' : 'e.g. Portrait Photography';
  String get cancelBtn => _isEs ? 'Annuler' : 'Cancel';
  String get addBtn => _isEs ? 'Ajouter' : 'Add';
  String get documentsTitle => _isEs ? 'Documents' : 'Documents';
  String get couldNotOpenDocument => _isEs ? 'Impossible d\'ouvrir le document' : 'Could not open document';
  String get profileUpdatedSuccess => _isEs ? 'Profil mis à jour avec succès' : 'Profile updated successfully';
  String itemsFailedToDelete(String error) => _isEs ? 'Échec de la suppression de certains éléments : $error' : 'Some items failed to delete: $error';
  String get updateFailed => _isEs ? 'Échec de la mise à jour' : 'Update failed';

  // ── Client Order History ──────────────────────────────────────────────────
  String get orderHistoryTitle => _isEs ? 'Historique des commandes' : 'Order History';
  String get filterAllOrders => _isEs ? 'Toutes les commandes' : 'All Orders';
  String get statusCancelled => _isEs ? 'Annulé' : 'Cancelled';
  String get noOrdersFound => _isEs ? 'Aucune commande trouvée' : 'No orders found';
  String get serviceTitleDefault => _isEs ? 'Titre du service' : 'Service Title';
  String get standardPackageDefault => _isEs ? 'Forfait standard' : 'Standard Package';
  String get providerNameDefault => _isEs ? 'Nom du prestataire' : 'Provider Name';
  String get locationNotSet => _isEs ? 'Lieu non défini' : 'Location not set';

  // ── Authentication ──────────────────────────────────────────────────────────────
  String get logInToContinue => _isEs ? 'Connectez-vous pour continuer' : 'Log in to continue';
  String get emailLabel => _isEs ? 'E-mail' : 'Email';
  String get emailHint => 'your@email.com';
  String get passwordLabel => _isEs ? 'Mot de passe' : 'Password';
  String get forgotPassword => _isEs ? 'Mot de passe oublié ?' : 'Forget Password?';
  String get loginBtn => _isEs ? 'Connexion' : 'Login';
  String get loginSuccessful => _isEs ? 'Connexion réussie' : 'Login successful';
  String get loginFailed => _isEs ? 'Connexion échouée' : 'Login failed';
  String get validEmailPasswordRequired => _isEs ? 'Veuillez saisir un e-mail et un mot de passe valides' : 'Please enter valid email and password';
  String get orContinueWith => _isEs ? 'OU CONTINUER AVEC' : 'OR CONTINUE WITH';
  String get noAccount => _isEs ? "Vous n'avez pas de compte ? " : "Don't have an account? ";
  String get signUpLink => _isEs ? "S'inscrire" : 'Sign up';
  String get createAccount => _isEs ? 'Créer un compte' : 'Create Account';
  String get nameLabel => _isEs ? 'Nom' : 'Name';
  String get signUpBtn => _isEs ? "S'inscrire" : 'Sign Up';
  String get fillAllFields => _isEs ? 'Veuillez remplir tous les champs correctement' : 'Please fill all fields correctly';
  String get registrationFailed => _isEs ? 'Inscription échouée' : 'Registration failed';
  String get accountAlreadyExists => _isEs ? 'Compte déjà existant. Redirection vers la vérification...' : 'Account already exists. Redirecting to verification...';
  String get alreadyHaveAccount => _isEs ? 'Vous avez déjà un compte ? ' : 'Already have an account? ';
  String get logInLink => _isEs ? 'Se connecter' : 'Log in';
  String get forgotPasswordTitle => _isEs ? 'Mot de passe oublié' : 'Forget Password';
  String get forgotPasswordSubtitle => _isEs ? 'Saisissez votre adresse e-mail et nous vous enverrons des instructions de réinitialisation.' : 'Enter your email address and we will send you a reset instructions.';
  String get sendBtn => _isEs ? 'Envoyer' : 'Send';
  String get somethingWentWrong => _isEs ? 'Une erreur est survenue' : 'Something went wrong';
  String get didntReceiveCode => _isEs ? "Vous n'avez pas reçu le code ?  " : "Didn't receive code?  ";
  String get resendAgain => _isEs ? 'Renvoyer' : 'Resend Again';
  String get otpVerificationTitle => _isEs ? 'Vérification OTP' : 'OTP Verification';
  String get codeSubmit => _isEs ? 'Soumettre le code' : 'Code Submit';
  String enterCodeSentTo(String email) => _isEs ? 'Entrez le code à 6 chiffres envoyé à $email' : 'Enter the 6-Digit code sent to you at $email';
  String get submitBtn => _isEs ? 'Soumettre' : 'Submit';
  String get verificationSuccessful => _isEs ? 'Vérification réussie ! Veuillez vous connecter.' : 'Verification successful! Please log in.';
  String get verificationFailed => _isEs ? 'Échec de la vérification' : 'Verification failed';
  String get newPasswordTitle => _isEs ? 'Nouveau mot de passe' : 'New password';
  String get newPasswordLabel => _isEs ? 'Nouveau mot de passe' : 'New Password';
  String get confirmPasswordLabel => _isEs ? 'Confirmer le mot de passe' : 'Confirmed Password';
  String get passwordResetSuccess => _isEs ? 'Mot de passe réinitialisé avec succès ! Veuillez vous connecter.' : 'Password reset successfully! Please log in.';
  String get failedToResetPassword => _isEs ? 'Échec de la réinitialisation du mot de passe' : 'Failed to reset password';

  // ── Onboarding / Role Selection ─────────────────────────────────────────────────
  String get howToUsePhotopia => _isEs ? 'Comment voulez-vous utiliser Photopia ?' : 'How do you want to use Photopia?';
  String get selectRoleToStart => _isEs ? 'Sélectionnez votre rôle pour commencer' : 'Select your role to get started';
  String get roleClient => _isEs ? 'Client' : 'Client';
  String get roleClientSubtitle => _isEs ? 'Trouvez et réservez des professionnels de la photo & vidéo' : 'Find and book photography & video professionals';
  String get roleProfessional => _isEs ? 'Professionnel' : 'Professional';
  String get roleProfessionalSubtitle => _isEs ? 'Mettez en valeur votre travail et développez votre activité' : 'Showcase your work and grow your business';

  // ── Service Details ────────────────────────────────────────────────────────
  String get serviceDetailsTitle => _isEs ? 'Détails du service' : 'Service Details';
  String get noDescriptionAvailable => _isEs ? 'Aucune description disponible.' : 'No description available.';
  String get providerLabel => _isEs ? 'Prestataire' : 'Provider';
  String get professional => _isEs ? 'Professionnel' : 'Professional';
  String get responseTimeLabel => _isEs ? 'Délai de réponse' : 'Response Time';
  String get completedProjectsLabel => _isEs ? 'Projets terminés' : 'Completed Projects';
  String get aboutLabel => _isEs ? 'À propos' : 'About';
  String get equipmentLabel => _isEs ? 'Équipement' : 'Equipment';
  String get messageBtn => _isEs ? 'Message' : 'Message';
  String get viewProfileBtn => _isEs ? 'Voir le profil' : 'View Profile';
  String get bookNowBtn => _isEs ? 'Réserver' : 'Book Now';
  String reviewsCount(int count, double rating) => _isEs ? '$rating ($count avis)' : '$rating ($count reviews)';

  // ── Mode Transition ────────────────────────────────────────────────────────
  String get switchingToProfessional => _isEs ? 'Passage en mode professionnel...' : 'Switching to Professional Mode...';
  String get switchingToClient => _isEs ? 'Passage en mode client...' : 'Switching to client mode...';
  String get failedToSwitchMode => _isEs ? 'Échec du changement de mode. Veuillez réessayer.' : 'Failed to switch mode. Please try again.';

  // ── Settings Screen ────────────────────────────────────────────────────
  String get settingsAccount => _isEs ? 'Compte' : 'Account';
  String get settingsPaymentMethod => _isEs ? 'Méthode de paiement' : 'Payment method';
  String get settingsChangePassword => _isEs ? 'Changer le mot de passe' : 'Change password';
  String get settingsAppearance => _isEs ? 'Apparence' : 'Appearance';
  String get settingsDarkMode => _isEs ? 'Mode sombre' : 'Dark mode';
  String get settingsLegal => _isEs ? 'Légal' : 'Legal';
  String get settingsTermsOfService => _isEs ? "Conditions d'utilisation" : 'Terms of Service';
  String get settingsHelpSupport => _isEs ? 'Aide & Support' : 'Help & Support';
  String get settingsContact => _isEs ? 'Contact' : 'Contact';
  String get settingsContactSubtitle => _isEs ? 'Envoyez-nous un message' : 'Send us a message';
  String get settingsFaq => _isEs ? 'FAQ' : 'FAQ';
  String get settingsFaqSubtitle => _isEs ? 'Questions fréquentes' : 'Frequently asked questions';
  String get settingsData => _isEs ? 'Données & Confidentialité' : 'Data & Privacy';
  String get settingsDownloadData => _isEs ? 'Télécharger mes données' : 'Download account data';
  String get settingsDangerZone => _isEs ? 'Zone danger' : 'Danger zone';
  String get settingsDeactivateAccount => _isEs ? 'Désactiver le compte' : 'Deactivate account';
  String get settingsDeactivateConfirm => _isEs ? 'Votre compte sera désactivé temporairement. Vous pourrez le réactiver en vous reconnectant.' : 'Your account will be temporarily deactivated. You can reactivate it by logging back in.';
  String get settingsDeactivate => _isEs ? 'Désactiver' : 'Deactivate';
  String get settingsDeleteAccount => _isEs ? 'Supprimer le compte' : 'Delete account';
  String get settingsDeleteConfirm => _isEs ? 'Cette action est irréversible. Toutes vos données seront définitivement supprimées.' : 'This action is irreversible. All your data will be permanently deleted.';
  String get settingsDelete => _isEs ? 'Supprimer' : 'Delete';
  String get comingSoon => _isEs ? 'bientôt disponible' : 'coming soon';
  
  // Extra keys for profile
  String get loading => _isEs ? 'Chargement...' : 'Loading...';
  String get detectingLocation => _isEs ? 'Détection de l\'emplacement...' : 'Detecting location...';
  String get customLocation => _isEs ? 'Emplacement personnalisé' : 'Custom Location';
  String get unknownProvider => _isEs ? 'Prestataire inconnu' : 'Unknown Provider';
  String get performanceStats => _isEs ? 'Statistiques de performance' : 'Performance Stats';
  String get deliveryLabel => _isEs ? 'Livraison' : 'Delivery';
  String get satisfactionLabel => _isEs ? 'Satisfaction' : 'Satisfaction';
  String get availableForTravel => _isEs ? 'Disponible pour voyager' : 'Travel';
  String get experience => _isEs ? 'Expérience' : 'Experience';
  String get education => _isEs ? 'Éducation' : 'Education';
  String get serviceArea => _isEs ? 'Zone de service' : 'Service Area';
  String get cropProfilePicture => _isEs ? 'Recadrer la photo de profil' : 'Crop Profile Picture';
  String get cropCoverPhoto => _isEs ? 'Recadrer la photo de couverture' : 'Crop Cover Photo';
  String get enterNameHint => _isEs ? 'Entrez le nom' : 'Enter name';
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'es'].contains(locale.languageCode);

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
