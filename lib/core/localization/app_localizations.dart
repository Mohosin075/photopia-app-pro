import 'package:flutter/material.dart';

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
  String get navHome => _isFr ? 'Accueil' : 'Home';
  String get navMessages => 'Messages';
  String get navSearch => _isFr ? 'Rechercher' : 'Search';
  String get navFavorites => _isFr ? 'Favoris' : 'Favorites';
  String get navProfile => _isFr ? 'Profil' : 'Profile';

  // ── Common actions ────────────────────────────────────────────────────────
  String get save => _isFr ? 'Enregistrer' : 'Save';
  String get cancel => _isFr ? 'Annuler' : 'Cancel';
  String get add => _isFr ? 'Ajouter' : 'Add';
  String get edit => _isFr ? 'Modifier' : 'Edit';
  String get close => _isFr ? 'Fermer' : 'Close';
  String get back => _isFr ? 'Retour' : 'Back';
  String get clear => _isFr ? 'Effacer' : 'Clear';
  String get viewAll => _isFr ? 'Voir tout' : 'View All';
  String get viewAllOrders =>
      _isFr ? 'Voir toutes les commandes' : 'View All Orders';
  String get markAllAsRead =>
      _isFr ? 'Tout marquer comme lu' : 'Mark all as read';
  String get pressBackToExit =>
      _isFr ? 'Appuyez à nouveau pour quitter' : 'Press back again to exit';

  // ── Auth / Account ────────────────────────────────────────────────────────
  String get login => _isFr ? 'Connexion' : 'Login';
  String get signUp => _isFr ? "S'inscrire" : 'Sign Up';
  String get logOut => _isFr ? 'Déconnexion' : 'Log Out';
  String get logOutConfirm => _isFr
      ? 'Êtes-vous sûr de vouloir vous déconnecter ?'
      : 'Are you sure you want to log out of your account?';
  String get switchToProfessional =>
      _isFr ? 'Passer en professionnel' : 'Switch to Professional';

  // ── Profile ───────────────────────────────────────────────────────────────
  String get profile => _isFr ? 'Profil' : 'Profile';
  String get editProfile => _isFr ? 'Modifier le profil' : 'Edit Profile';
  String get language => _isFr ? 'Langue' : 'Language';
  String get selectLanguage =>
      _isFr ? 'Sélectionner la langue' : 'Select Language';
  String get orderHistory =>
      _isFr ? 'Historique des commandes' : 'Order History';
  String get notifications => _isFr ? 'Notifications' : 'Notifications';
  String get privacyPolicy =>
      _isFr ? 'Politique de confidentialité' : 'Privacy Policy';
  String get privacySecurity =>
      _isFr ? 'Confidentialité & Sécurité' : 'Privacy & Security';
  String get helpAndSupport => _isFr ? 'Aide & Support' : 'Help & Support';
  String get settings => _isFr ? 'Paramètres' : 'Settings';
  String get recentOrders =>
      _isFr ? 'Commandes récentes' : 'Recent Orders';
  String get noRecentOrders =>
      _isFr ? 'Aucune commande récente' : 'No recent orders';

  // ── Notifications ─────────────────────────────────────────────────────────
  String get noNotificationsAvailable =>
      _isFr ? 'Aucune notification disponible.' : 'No notifications available.';
  String unread(int count) => _isFr ? '$count non lus' : '$count unread';

  // ── Search / Categories ───────────────────────────────────────────────────
  String get browseCategories =>
      _isFr ? 'Parcourir les catégories' : 'Browse Categories';
  String get searchResults =>
      _isFr ? 'Résultats de recherche' : 'Search Results';
  String get noCategoriesFound =>
      _isFr ? 'Aucune catégorie trouvée' : 'No categories found';
  String get noSubcategoriesFound => _isFr
      ? 'Aucune sous-catégorie trouvée'
      : 'No subcategories found for this category';
  String get noServicesFound =>
      _isFr ? 'Aucun service trouvé' : 'No services found';
  String get backToCategories =>
      _isFr ? 'Retour aux catégories' : 'Back to Categories';
  String get categories => _isFr ? 'Catégories' : 'Categories';
  String get search => _isFr ? 'Rechercher' : 'Search';
  String get searchHint =>
      _isFr ? 'Rechercher des photographes, services...' : 'Search photographers, services...';
  String get location => _isFr ? 'Emplacement' : 'Location';
  String get searchLocationHint =>
      _isFr ? 'Rechercher un emplacement...' : 'Search location...';
  String radius(int km) => _isFr ? 'Rayon: $km km' : 'Radius: $km km';
  String budget(int start, int end) =>
      _isFr ? 'Budget: €$start - €$end' : 'Budget: €$start - €$end';
  String get typeOfService => _isFr ? 'Type de service' : 'Type of Service';
  String get equipmentUsed => _isFr ? 'Équipement utilisé' : 'Equipment Used';
  String get applyFilters => _isFr ? 'Appliquer les filtres' : 'Apply Filters';
  String get clearAll => _isFr ? 'Tout effacer' : 'Clear All';
  String get recentSearches => _isFr ? 'Recherches récentes' : 'Recent Searches';
  String get trendingCategories => _isFr ? 'Catégories populaires' : 'Trending Categories';
  String get searchResultsFor => _isFr ? 'Résultats pour' : 'Results for';

  // ── Provider Profile ──────────────────────────────────────────────────────
  String get aboutMe => _isFr ? 'À propos de moi' : 'About Me';
  String get languages => _isFr ? 'Langues' : 'Languages';
  String get specializations =>
      _isFr ? 'Spécialisations' : 'Specializations';
  String get portfolio => _isFr ? 'Portfolio' : 'Portfolio';
  String get clientReviews => _isFr ? 'Avis clients' : 'Client Reviews';
  String get noReviewsYet =>
      _isFr ? "Aucun avis pour l'instant" : 'No reviews yet';
  String get completedBookingsWillAppear => _isFr
      ? 'Les réservations terminées apparaîtront ici'
      : 'Completed bookings will appear here';
  String get rating => _isFr ? 'Note' : 'Rating';
  String get reviewsLabel => _isFr ? 'Avis' : 'Reviews';
  String get responseRate => _isFr ? 'Réponse' : 'Response\nRate';
  String get projects => _isFr ? 'Projets' : 'Projects';
  String get documents => _isFr ? 'Documents' : 'Documents';
  String get addPhoto => _isFr ? 'Ajouter une photo' : 'Add Photo';
  String get selectALanguage =>
      _isFr ? 'Sélectionner une langue' : 'Select a language';
  String get noDocumentsAdded =>
      _isFr ? 'Aucun document ajouté.' : 'No documents added yet.';
  String get selectLanguageToAdd => _isFr
      ? 'Sélectionnez une langue à ajouter à votre profil.'
      : 'Select a language to add to your profile.';
  String get enterSpecialization => _isFr
      ? 'Saisissez la spécialisation à ajouter.'
      : 'Enter the specialization you want to add.';
  String addTitle(String title) => _isFr ? 'Ajouter $title' : 'Add $title';

  // ── Home Page ─────────────────────────────────────────────────────────────
  String get originalProjects => _isFr ? 'Projets originaux' : 'Original Projects';
  String get recentlyViewed => _isFr ? 'Récemment consultés' : 'Recently Viewed';
  String get ideasForProject => _isFr ? 'Idées pour votre projet' : 'Ideas for your project';
  String get getInspired => _isFr ? 'Laissez-vous inspirer' : 'Get Inspired';
  String get superPros => _isFr ? 'Super Pros' : 'Super Pros';
  String get availableRightNow => _isFr ? 'Disponible en ce moment' : 'Available Right Now';
  String get nearYou => _isFr ? 'Près de chez vous' : 'Near You';
  String get popularCategories => _isFr ? 'Catégories populaires' : 'Popular Categories';
  String get mainCategories => _isFr ? 'Catégories principales' : 'Main Categories';
  String get findYourStyle => _isFr ? 'Trouvez votre style' : 'Find Your Style';
  String get trendingProjects => _isFr ? 'Projets tendances' : 'Trending Projects';
  String get trendingThisWeek => _isFr ? 'Tendances de la semaine' : 'Trending This Week';
  String get unableToLoadHome => _isFr ? 'Impossible de charger l\'accueil' : 'Unable to load home';
  String get tryAgain => _isFr ? 'Réessayer' : 'Try Again';
  String get noData => _isFr ? 'Aucune donnée' : 'No Data';

  // ── Messages ──────────────────────────────────────────────────────────────
  String get noMessagesYet => _isFr ? 'Aucun message pour le moment' : 'No Messages Yet';
  String get noMessagesDesc => _isFr 
      ? 'Lorsque vous commencez une conversation, elle apparaîtra ici. Commencez à explorer pour vous connecter !' 
      : 'When you start a conversation, it will appear here. Start exploring to connect!';
  String get searchConversations => _isFr ? 'Rechercher des conversations...' : 'Search conversations...';

  // ── Favorites ─────────────────────────────────────────────────────────────
  String favoritePostsCount(int count) => _isFr ? 'Annonces ($count)' : 'Posts ($count)';
  String favoriteProvidersCount(int count) => _isFr ? 'Prestataires ($count)' : 'Providers ($count)';
  String get noFavoritePosts => _isFr ? 'Aucune annonce favorite pour le moment' : 'No favorite posts yet';
  String get noFavoriteProviders => _isFr ? 'Aucun prestataire favori pour le moment' : 'No favorite providers yet';
  
  // ── Provider Navigation ───────────────────────────────────────────────────
  String get providerNavOrders => _isFr ? 'Commandes' : 'Orders';
  String get providerNavCalendar => _isFr ? 'Calendrier' : 'Calendar';
  String get providerNavListing => _isFr ? 'Annonces' : 'Listing';
  String get providerNavMenu => _isFr ? 'Menu' : 'Menu';

  // ── Provider Overview / Dashboard ─────────────────────────────────────────
  String get myListings => _isFr ? 'Mes annonces' : 'My Listings';
  String get create => _isFr ? 'Créer' : 'Create';
  String get active => _isFr ? 'Actif' : 'Active';
  String get drafts => _isFr ? 'Brouillons' : 'Drafts';
  String get past => _isFr ? 'Passé' : 'Past';
  String noListingsFound(String status) => _isFr ? 'Aucune annonce $status trouvée' : 'No $status listings found';
  String get noTitle => _isFr ? 'Sans titre' : 'No Title';
  String get noCategory => _isFr ? 'Aucune catégorie' : 'No Category';
  String viewsCount(int count) => _isFr ? '$count vues' : '$count views';
  String bookingsCount(int count) => _isFr ? '$count réservations' : '$count bookings';
  String get viewBtn => _isFr ? 'Voir' : 'View';
  String get editBtn => _isFr ? 'Modifier' : 'Edit';
  String get deleteConfirmation => _isFr ? 'Confirmation de suppression' : 'Delete Confirmation';
  String get areYouSureDelete => _isFr ? 'Êtes-vous sûr de vouloir supprimer ceci ?' : 'Are you sure you want to delete this?';
  String get serviceDeletedSuccess => _isFr ? 'Service supprimé avec succès' : 'Service deleted successfully';
  String get deleteFailed => _isFr ? 'Échec de la suppression' : 'Delete failed';
  String get yes => _isFr ? 'Oui' : 'Yes';
  String get no => _isFr ? 'Non' : 'No';
  String get overallStatistics => _isFr ? 'Statistiques globales' : 'Overall Statistics';
  String get total => _isFr ? 'Total' : 'Total';
  String get profilePhotoRequired => _isFr ? 'Photo de profil requise' : 'Profile Photo Required';
  String get profilePhotoRequiredDesc => _isFr 
      ? 'Vous devez ajouter une photo de profil avant de pouvoir créer une annonce. Les clients font confiance aux créateurs qu\'ils peuvent voir !' 
      : 'You need to add a profile photo before you can create a service listing. Clients trust creators they can see!';
  String get later => _isFr ? 'Plus tard' : 'Later';
  
  // ── Provider Menu ─────────────────────────────────────────────────────────
  String get paymentsTransactions => _isFr ? 'Paiements & Transactions' : 'Payments & Transactions';
  String get detailedStatistics => _isFr ? 'Statistiques détaillées' : 'Detailed Statistics';
  String get failedToContactAdmin => _isFr ? 'Échec de la connexion avec l\'admin' : 'Failed to contact admin';
  String get switchToClient => _isFr ? 'Passer en mode client' : 'Switch to Client';
  String get viewPublicProfile => _isFr ? 'Voir le profil public' : 'View Public Profile';
  String get bookingsTitle => _isFr ? 'Réservations' : 'Bookings';
  String bookingsThisWeek(int count) => _isFr ? '+$count cette semaine' : '+$count this week';
  String get revenueTitle => _isFr ? 'Revenus' : 'Revenue';
  String revenueVsLastMonth(num percent) => _isFr ? '+$percent% vs mois dernier' : '+$percent% vs last month';
  String get profileViewsTitle => _isFr ? 'Vues du profil' : 'Profile Views';
  String get thisWeek => _isFr ? 'cette semaine' : 'this week';
  String reviewCount(int count) => _isFr ? '$count avis' : '$count reviews';
  String get premiumMember => _isFr ? 'Membre Premium' : 'Premium Member';
  String get premiumPrice => _isFr ? '€10/mois' : '€10/month';
  String get premiumBenefits => _isFr ? 'Classement prioritaire • Analyses avancées • Badge premium' : 'Priority search placement • Extended analytics • Premium badge';
  String get manageSubscription => _isFr ? 'Gérer l\'abonnement' : 'Manage Subscription';

  // ── Provider Orders ───────────────────────────────────────────────────────
  String get tabToday => _isFr ? 'Aujourd\'hui' : 'Today';
  String get tabUpcoming => _isFr ? 'À venir' : 'Upcoming';
  String get tabPending => _isFr ? 'En attente' : 'Pending';
  String get todaysBookings => _isFr ? 'Réservations du jour' : 'Today\'s Bookings';
  String get noBookingsRightNow => _isFr ? 'Aucune réservation pour le moment' : 'No bookings right now';
  String get unknownClient => _isFr ? 'Client inconnu' : 'Unknown Client';
  String get unknownService => _isFr ? 'Service inconnu' : 'Unknown Service';
  String get locationNA => _isFr ? 'Emplacement N/D' : 'Location N/A';
  String get notAvailable => _isFr ? 'N/D' : 'N/A';
  String get upcomingBookings => _isFr ? 'Réservations à venir' : 'Upcoming Bookings';
  String get noUpcomingBookings => _isFr ? 'Aucune réservation à venir' : 'No upcoming bookings';
  String get pendingApproval => _isFr ? 'En attente d\'approbation' : 'Pending Approval';
  String requestsCount(int count) => _isFr ? '$count demandes' : '$count requests';
  String get noPendingRequests => _isFr ? 'Aucune demande en attente' : 'No pending requests';
  String get requestedRecently => _isFr ? 'Demandé récemment' : 'Requested recently';
  String get viewDetails => _isFr ? 'Voir les détails' : 'View Details';
  String get contactBtn => _isFr ? 'Contacter' : 'Contact';
  String get detailsBtn => _isFr ? 'Détails' : 'Details';
  String get declineBtn => _isFr ? 'Refuser' : 'Decline';
  String get acceptBtn => _isFr ? 'Accepter' : 'Accept';
  String get viewFullDetails => _isFr ? 'Voir tous les détails' : 'View Full Details';
  String get clientInfoNotAvailable => _isFr ? 'Informations client non disponibles' : 'Client information not available';
  String get doYouWantToAccept => _isFr ? 'Voulez-vous accepter ceci ?' : 'Do you want to accept this?';
  String get doYouWantToDecline => _isFr ? 'Voulez-vous refuser ceci ?' : 'Do you want to decline this?';
  String get orderAcceptedSuccess => _isFr ? 'Commande acceptée avec succès !' : 'Order accepted successfully!';
  String get orderDeclinedSuccess => _isFr ? 'Commande refusée avec succès !' : 'Order declined successfully!';
  String get orderStatusUpdateFailed => _isFr ? 'Échec de la mise à jour du statut' : 'Failed to update order status';

  // ── Provider Calendar ─────────────────────────────────────────────────────
  String get calendarAvailability => _isFr ? 'Calendrier et Disponibilités' : 'Calendar & Availability';
  String get viewWeek => _isFr ? 'Semaine' : 'Week';
  String get viewMonth => _isFr ? 'Mois' : 'Month';
  String get viewYear => _isFr ? 'Année' : 'Year';
  String get monthlySchedule => _isFr ? 'Planning mensuel' : 'Monthly Schedule';
  String get noBookingsForDate => _isFr ? 'Aucune réservation pour cette date' : 'No bookings for this date';
  String get defaultBookingTitle => _isFr ? 'Réservation' : 'Booking';
  String get defaultClientName => _isFr ? 'Client' : 'Client';
  String get weeklyOverview => _isFr ? 'Aperçu hebdomadaire' : 'Weekly Overview';
  String get upcomingThisWeek => _isFr ? 'À venir cette semaine' : 'Upcoming this week';
  String get statusOn => _isFr ? 'ON' : 'ON';
  String get statusOff => _isFr ? 'OFF' : 'OFF';

  // ── Provider Statistics ───────────────────────────────────────────────────
  String get statisticsTitle => _isFr ? 'Statistiques' : 'Statistics';
  String get monthlyRevenue => _isFr ? 'Revenu mensuel' : 'Monthly Revenue';
  String vsLastMonth(num percent) => _isFr ? '${percent >= 0 ? "+" : ""}$percent% vs mois dernier' : '${percent >= 0 ? "+" : ""}$percent% vs last month';
  String get viewsVsCategoryAvg => _isFr ? 'Vues vs Moyenne de la catégorie' : 'Views vs Category Average';
  String get yourViews => _isFr ? 'Vos vues' : 'Your Views';
  String get categoryAverage => _isFr ? 'Moyenne de la catégorie' : 'Category Average';
  String performingAboveAvg(num percent) => _isFr ? 'Vous performez $percent% au-dessus de la moyenne' : 'You\'re performing $percent% above category average';
  String performingBelowAvg(num percent) => _isFr ? 'Vous performez $percent% en dessous de la moyenne' : 'You\'re performing $percent% below category average';
  String get ratingVsCategoryAvg => _isFr ? 'Note vs Moyenne de la catégorie' : 'Rating vs Category Average';
  String get yourRating => _isFr ? 'Votre note' : 'Your Rating';
  String ratingHigherThanProviders(num percent) => _isFr ? 'Votre note est $percent% supérieure aux autres' : 'Your rating is $percent% higher than similar providers';
  String get profileViewsByRegion => _isFr ? 'Vues par région' : 'Profile Views by Region';
  String get noRegionalData => _isFr ? 'Aucune donnée régionale' : 'No regional data available';
  String get totalViews => _isFr ? 'Vues totales' : 'Total Views';
  String get revenueAnalyticsTitle => _isFr ? 'Analyses des revenus' : 'Revenue Analytics';
  String get currentMonth => _isFr ? 'Mois en cours' : 'Current Month';
  String vsPreviousMonth(num amount) => _isFr ? 'vs mois précédent: €$amount' : 'vs previous month: €$amount';
  String get avgPerPeriod => _isFr ? 'Moyenne par période' : 'Average per period';
  String get bestPerforming => _isFr ? 'Meilleure performance' : 'Best performing';
  String get deepBusinessInsights => _isFr ? 'Analyses commerciales approfondies' : 'Deep Business Insights';
  String get conversionRate => _isFr ? 'Taux de conversion' : 'Conversion Rate';
  String get repeatRate => _isFr ? 'Taux de répétition' : 'Repeat Rate';
  String get mostViewedProject => _isFr ? 'Projet le plus vu' : 'Most Viewed Project';
  String get unlockInsights => _isFr ? 'Débloquer les analyses' : 'Unlock Insights';
  String get upgradeSubscriptionDesc => _isFr 
      ? 'Améliorez votre abonnement pour accéder aux analyses avancées incluant :' 
      : 'Upgrade your subscription to get access to advanced business analytics including:';
  String get premiumFeature1 => _isFr ? 'Suivi régional détaillé' : 'Deep regional profile view tracking';
  String get premiumFeature2 => _isFr ? 'Répartition hebdomadaire' : 'Weekly revenue breakdowns';
  String get premiumFeature3 => _isFr ? 'Taux de conversion' : 'Business Conversion rates';
  String get premiumFeature4 => _isFr ? 'Analyses de la valeur moyenne' : 'Average order value analytics';
  String get upgradeToPremium => _isFr ? 'Passer à Premium' : 'Upgrade to Premium';
  String get exportFullReport => _isFr ? 'Exporter le rapport' : 'Export Full Report';
  String get exportingBtn => _isFr ? 'Exportation...' : 'Exporting...';
  String reportSavedTo(String path) => _isFr ? 'Rapport enregistré sous : $path' : 'Report saved to: $path';
  String get filterWeek => _isFr ? 'Semaine' : 'Week';
  String get filterMonth => _isFr ? 'Mois' : 'Month';
  String get filterQuarter => _isFr ? 'Trimestre' : 'Quarter';
  String get filterYear => _isFr ? 'Année' : 'Year';

  // ── Provider Wallet ───────────────────────────────────────────────────────
  String get walletTitle => _isFr ? 'Portefeuille' : 'Wallet';
  String get thisMonth => _isFr ? 'Ce mois-ci' : 'This Month';
  String get lastMonth => _isFr ? 'Mois dernier' : 'Last Month';
  String get allTransactions => _isFr ? 'Toutes les transactions' : 'All Transactions';
  String get filterReceived => _isFr ? 'Reçu' : 'Received';
  String get filterUpcoming => _isFr ? 'À venir' : 'Upcoming';
  String get statusCompleted => _isFr ? 'Terminé' : 'Completed';
  String get statusPaidOut => _isFr ? 'Payé' : 'Paid Out';
  String get totalBalance => _isFr ? 'Solde total' : 'Total Balance';
  String get balanceAvailable => _isFr ? 'Disponible' : 'Available';
  String get balancePending => _isFr ? 'En attente' : 'Pending';
  String get requestPayout => _isFr ? 'Demander un paiement' : 'Request Payout';
  String get invoiceBtn => _isFr ? 'Facture' : 'Invoice';

  // ── Provider Profile (extra) ──────────────────────────────────────────────
  String get profileTitle => _isFr ? 'Profil' : 'Profile';
  String get fullNameHint => _isFr ? 'Nom complet' : 'Full Name';
  String get bioTaglineHint => _isFr ? 'Slogan (ex: Photographe de mariage)' : 'Bio Tagline (e.g. Wedding Photographer)';
  String get ratingLabel => _isFr ? 'Note' : 'Rating';
  String get responseRateLabel => _isFr ? 'Taux de\nRéponse' : 'Response\nRate';
  String get projectsLabel => _isFr ? 'Projets' : 'Projects';
  String get aboutMeTitle => _isFr ? 'À propos de moi' : 'About Me';
  String get specializationsTitle => _isFr ? 'Spécialisations' : 'Specializations';
  String get languagesTitle => _isFr ? 'Langues' : 'Languages';
  String get portfolioTitle => _isFr ? 'Portfolio' : 'Portfolio';
  String portfolioCount(int count) => _isFr ? 'Portfolio ($count)' : 'Portfolio ($count)';
  String get addPhotoBtn => _isFr ? 'Ajouter' : 'Add Photo';
  String get clientReviewsTitle => _isFr ? 'Avis clients' : 'Client Reviews';
  String get completedBookingsWillAppearHere => _isFr ? 'Les réservations terminées apparaîtront ici' : 'Completed bookings will appear here';
  String get anonymous => _isFr ? 'Anonyme' : 'Anonymous';
  String get enterSpecializationHint => _isFr ? 'Entrez la spécialisation à ajouter.' : 'Enter the specialization you want to add.';
  String get selectLanguageHint => _isFr ? 'Sélectionnez une langue à ajouter à votre profil.' : 'Select a language to add to your profile.';
  String get selectLanguageDropdownHint => _isFr ? 'Sélectionner une langue' : 'Select a language';
  String get exPortraitPhotography => _isFr ? 'ex: Photographie de portrait' : 'e.g. Portrait Photography';
  String get cancelBtn => _isFr ? 'Annuler' : 'Cancel';
  String get addBtn => _isFr ? 'Ajouter' : 'Add';
  String get documentsTitle => _isFr ? 'Documents' : 'Documents';
  String get couldNotOpenDocument => _isFr ? 'Impossible d\'ouvrir le document' : 'Could not open document';
  String get profileUpdatedSuccess => _isFr ? 'Profil mis à jour avec succès' : 'Profile updated successfully';
  String itemsFailedToDelete(String error) => _isFr ? 'Échec de la suppression de certains éléments : $error' : 'Some items failed to delete: $error';
  String get updateFailed => _isFr ? 'Échec de la mise à jour' : 'Update failed';

  // ── Client Order History ──────────────────────────────────────────────────
  String get orderHistoryTitle => _isFr ? 'Historique des commandes' : 'Order History';
  String get filterAllOrders => _isFr ? 'Toutes les commandes' : 'All Orders';
  String get statusCancelled => _isFr ? 'Annulé' : 'Cancelled';
  String get noOrdersFound => _isFr ? 'Aucune commande trouvée' : 'No orders found';
  String get serviceTitleDefault => _isFr ? 'Titre du service' : 'Service Title';
  String get standardPackageDefault => _isFr ? 'Forfait standard' : 'Standard Package';
  String get providerNameDefault => _isFr ? 'Nom du prestataire' : 'Provider Name';
  String get locationNotSet => _isFr ? 'Lieu non défini' : 'Location not set';

  // ── Authentication ──────────────────────────────────────────────────────────────
  String get logInToContinue => _isFr ? 'Connectez-vous pour continuer' : 'Log in to continue';
  String get emailLabel => _isFr ? 'E-mail' : 'Email';
  String get emailHint => 'your@email.com';
  String get passwordLabel => _isFr ? 'Mot de passe' : 'Password';
  String get forgotPassword => _isFr ? 'Mot de passe oublié ?' : 'Forget Password?';
  String get loginBtn => _isFr ? 'Connexion' : 'Login';
  String get loginSuccessful => _isFr ? 'Connexion réussie' : 'Login successful';
  String get loginFailed => _isFr ? 'Connexion échouée' : 'Login failed';
  String get validEmailPasswordRequired => _isFr ? 'Veuillez saisir un e-mail et un mot de passe valides' : 'Please enter valid email and password';
  String get orContinueWith => _isFr ? 'OU CONTINUER AVEC' : 'OR CONTINUE WITH';
  String get noAccount => _isFr ? "Vous n'avez pas de compte ? " : "Don't have an account? ";
  String get signUpLink => _isFr ? "S'inscrire" : 'Sign up';
  String get createAccount => _isFr ? 'Créer un compte' : 'Create Account';
  String get nameLabel => _isFr ? 'Nom' : 'Name';
  String get signUpBtn => _isFr ? "S'inscrire" : 'Sign Up';
  String get fillAllFields => _isFr ? 'Veuillez remplir tous les champs correctement' : 'Please fill all fields correctly';
  String get registrationFailed => _isFr ? 'Inscription échouée' : 'Registration failed';
  String get accountAlreadyExists => _isFr ? 'Compte déjà existant. Redirection vers la vérification...' : 'Account already exists. Redirecting to verification...';
  String get alreadyHaveAccount => _isFr ? 'Vous avez déjà un compte ? ' : 'Already have an account? ';
  String get logInLink => _isFr ? 'Se connecter' : 'Log in';
  String get forgotPasswordTitle => _isFr ? 'Mot de passe oublié' : 'Forget Password';
  String get forgotPasswordSubtitle => _isFr ? 'Saisissez votre adresse e-mail et nous vous enverrons des instructions de réinitialisation.' : 'Enter your email address and we will send you a reset instructions.';
  String get sendBtn => _isFr ? 'Envoyer' : 'Send';
  String get somethingWentWrong => _isFr ? 'Une erreur est survenue' : 'Something went wrong';
  String get didntReceiveCode => _isFr ? "Vous n'avez pas reçu le code ?  " : "Didn't receive code?  ";
  String get resendAgain => _isFr ? 'Renvoyer' : 'Resend Again';
  String get otpVerificationTitle => _isFr ? 'Vérification OTP' : 'OTP Verification';
  String get codeSubmit => _isFr ? 'Soumettre le code' : 'Code Submit';
  String enterCodeSentTo(String email) => _isFr ? 'Entrez le code à 6 chiffres envoyé à $email' : 'Enter the 6-Digit code sent to you at $email';
  String get submitBtn => _isFr ? 'Soumettre' : 'Submit';
  String get verificationSuccessful => _isFr ? 'Vérification réussie ! Veuillez vous connecter.' : 'Verification successful! Please log in.';
  String get verificationFailed => _isFr ? 'Échec de la vérification' : 'Verification failed';
  String get newPasswordTitle => _isFr ? 'Nouveau mot de passe' : 'New password';
  String get newPasswordLabel => _isFr ? 'Nouveau mot de passe' : 'New Password';
  String get confirmPasswordLabel => _isFr ? 'Confirmer le mot de passe' : 'Confirmed Password';
  String get passwordResetSuccess => _isFr ? 'Mot de passe réinitialisé avec succès ! Veuillez vous connecter.' : 'Password reset successfully! Please log in.';
  String get failedToResetPassword => _isFr ? 'Échec de la réinitialisation du mot de passe' : 'Failed to reset password';

  // ── Onboarding / Role Selection ─────────────────────────────────────────────────
  String get howToUsePhotopia => _isFr ? 'Comment voulez-vous utiliser Photopia ?' : 'How do you want to use Photopia?';
  String get selectRoleToStart => _isFr ? 'Sélectionnez votre rôle pour commencer' : 'Select your role to get started';
  String get roleClient => _isFr ? 'Client' : 'Client';
  String get roleClientSubtitle => _isFr ? 'Trouvez et réservez des professionnels de la photo & vidéo' : 'Find and book photography & video professionals';
  String get roleProfessional => _isFr ? 'Professionnel' : 'Professional';
  String get roleProfessionalSubtitle => _isFr ? 'Mettez en valeur votre travail et développez votre activité' : 'Showcase your work and grow your business';

  // ── Service Details ────────────────────────────────────────────────────────
  String get serviceDetailsTitle => _isFr ? 'Détails du service' : 'Service Details';
  String get noDescriptionAvailable => _isFr ? 'Aucune description disponible.' : 'No description available.';
  String get providerLabel => _isFr ? 'Prestataire' : 'Provider';
  String get professional => _isFr ? 'Professionnel' : 'Professional';
  String get responseTimeLabel => _isFr ? 'Délai de réponse' : 'Response Time';
  String get completedProjectsLabel => _isFr ? 'Projets terminés' : 'Completed Projects';
  String get aboutLabel => _isFr ? 'À propos' : 'About';
  String get equipmentLabel => _isFr ? 'Équipement' : 'Equipment';
  String get messageBtn => _isFr ? 'Message' : 'Message';
  String get viewProfileBtn => _isFr ? 'Voir le profil' : 'View Profile';
  String get bookNowBtn => _isFr ? 'Réserver' : 'Book Now';
  String reviewsCount(int count, double rating) => _isFr ? '$rating ($count avis)' : '$rating ($count reviews)';

  // ── Mode Transition ────────────────────────────────────────────────────────
  String get switchingToProfessional => _isFr ? 'Passage en mode professionnel...' : 'Switching to Professional Mode...';
  String get switchingToClient => _isFr ? 'Passage en mode client...' : 'Switching to client mode...';
  String get failedToSwitchMode => _isFr ? 'Échec du changement de mode. Veuillez réessayer.' : 'Failed to switch mode. Please try again.';

  // ── Settings Screen ────────────────────────────────────────────────────
  String get settingsAccount => _isFr ? 'Compte' : 'Account';
  String get settingsPaymentMethod => _isFr ? 'Méthode de paiement' : 'Payment method';
  String get settingsChangePassword => _isFr ? 'Changer le mot de passe' : 'Change password';
  String get settingsAppearance => _isFr ? 'Apparence' : 'Appearance';
  String get settingsDarkMode => _isFr ? 'Mode sombre' : 'Dark mode';
  String get settingsLegal => _isFr ? 'Légal' : 'Legal';
  String get settingsTermsOfService => _isFr ? "Conditions d'utilisation" : 'Terms of Service';
  String get settingsHelpSupport => _isFr ? 'Aide & Support' : 'Help & Support';
  String get settingsContact => _isFr ? 'Contact' : 'Contact';
  String get settingsContactSubtitle => _isFr ? 'Envoyez-nous un message' : 'Send us a message';
  String get settingsFaq => _isFr ? 'FAQ' : 'FAQ';
  String get settingsFaqSubtitle => _isFr ? 'Questions fréquentes' : 'Frequently asked questions';
  String get settingsData => _isFr ? 'Données & Confidentialité' : 'Data & Privacy';
  String get settingsDownloadData => _isFr ? 'Télécharger mes données' : 'Download account data';
  String get settingsDangerZone => _isFr ? 'Zone danger' : 'Danger zone';
  String get settingsDeactivateAccount => _isFr ? 'Désactiver le compte' : 'Deactivate account';
  String get settingsDeactivateConfirm => _isFr ? 'Votre compte sera désactivé temporairement. Vous pourrez le réactiver en vous reconnectant.' : 'Your account will be temporarily deactivated. You can reactivate it by logging back in.';
  String get settingsDeactivate => _isFr ? 'Désactiver' : 'Deactivate';
  String get settingsDeleteAccount => _isFr ? 'Supprimer le compte' : 'Delete account';
  String get settingsDeleteConfirm => _isFr ? 'Cette action est irréversible. Toutes vos données seront définitivement supprimées.' : 'This action is irreversible. All your data will be permanently deleted.';
  String get settingsDelete => _isFr ? 'Supprimer' : 'Delete';
  String get comingSoon => _isFr ? 'bientôt disponible' : 'coming soon';
  
  // Extra keys for profile
  String get loading => _isFr ? 'Chargement...' : 'Loading...';
  String get detectingLocation => _isFr ? 'Détection de l\'emplacement...' : 'Detecting location...';
  String get customLocation => _isFr ? 'Emplacement personnalisé' : 'Custom Location';
  String get unknownProvider => _isFr ? 'Prestataire inconnu' : 'Unknown Provider';
  String get performanceStats => _isFr ? 'Statistiques de performance' : 'Performance Stats';
  String get deliveryLabel => _isFr ? 'Livraison' : 'Delivery';
  String get satisfactionLabel => _isFr ? 'Satisfaction' : 'Satisfaction';
  String get availableForTravel => _isFr ? 'Disponible pour voyager' : 'Travel';
  String get experience => _isFr ? 'Expérience' : 'Experience';
  String get education => _isFr ? 'Éducation' : 'Education';
  String get serviceArea => _isFr ? 'Zone de service' : 'Service Area';
  String get cropProfilePicture => _isFr ? 'Recadrer la photo de profil' : 'Crop Profile Picture';
  String get cropCoverPhoto => _isFr ? 'Recadrer la photo de couverture' : 'Crop Cover Photo';
  String get enterNameHint => _isFr ? 'Entrez le nom' : 'Enter name';
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
