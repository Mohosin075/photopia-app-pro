import 'package:photopya/core/network/urls.dart';

class ProfessionalProfileModel {
  final int? profileViews;
  final int? projects;
  final int? responseRate;
  final String? id;
  final User? user;
  final List<dynamic>? specialties;
  final List<dynamic>? portfolio;
  final List<dynamic>? language;
  final bool? isVerified;
  final double? rating;
  final int? reviewCount;
  final String? bio;
  final String? specialty;
  final String? coverPhoto;
  final Statistics? statistics;
  final bool isSubscribed;
  final String? subscriptionStatus;
  final List<dynamic>? documents;

  final int? responseTime;
  final int? deliveryRate;
  final int? satisfactionRate;
  final bool? isSuperPro;
  final String? dateOfBirth;
  final String? miniBio;
  final List<dynamic>? primaryDomain;
  final String? createdAt;
  final String? updatedAt;
  final String? stripeAccountId;
  final bool? stripeOnboardingComplete;
  final List<dynamic>? categories;
  final AreaOfIntervention? areaOfIntervention;
  final ExperienceDetails? experienceDetails;
  final NotificationPreferences? notificationPreferences;
  final LegalNotice? legalNotice;

  ProfessionalProfileModel({
    this.profileViews,
    this.projects,
    this.responseRate,
    this.id,
    this.user,
    this.specialties,
    this.portfolio,
    this.language,
    this.isVerified,
    this.rating,
    this.reviewCount,
    this.bio,
    this.specialty,
    this.coverPhoto,
    this.statistics,
    this.isSubscribed = false,
    this.subscriptionStatus,
    this.documents,
    this.responseTime,
    this.deliveryRate,
    this.satisfactionRate,
    this.isSuperPro,
    this.dateOfBirth,
    this.miniBio,
    this.primaryDomain,
    this.createdAt,
    this.updatedAt,
    this.stripeAccountId,
    this.stripeOnboardingComplete,
    this.categories,
    this.areaOfIntervention,
    this.experienceDetails,
    this.notificationPreferences,
    this.legalNotice,
  });

  factory ProfessionalProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalProfileModel(
      profileViews: json['profileViews'],
      projects: json['projects'],
      responseRate: json['responseRate'],
      id: json['_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      specialties: json['specialties'],
      portfolio: (json['portfolio'] as List?)
          ?.map((e) => formatUrl(e))
          .toList(),
      language: json['language'],
      isVerified: json['isVerified'] == true,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'],
      bio: json['bio'],
      specialty: json['specialty'],
      coverPhoto: formatUrl(json['coverPhoto']),
      statistics: json['statistics'] != null
          ? Statistics.fromJson(json['statistics'])
          : null,
      isSubscribed:
          json['isStripeConnected'] == true ||
          json['isVerified'] == true ||
          json['isSubscribed'] == true,
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      documents: (json['documents'] as List?)
          ?.map((e) => formatUrl(e))
          .toList(),
      responseTime: json['responseTime'],
      deliveryRate: json['deliveryRate'],
      satisfactionRate: json['satisfactionRate'],
      isSuperPro: json['isSuperPro'],
      dateOfBirth: json['dateOfBirth'],
      miniBio: json['miniBio'],
      primaryDomain: json['primaryDomain'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      stripeAccountId: json['stripeAccountId'],
      stripeOnboardingComplete: json['stripeOnboardingComplete'],
      categories: json['categories'],
      areaOfIntervention: json['areaOfIntervention'] != null
          ? AreaOfIntervention.fromJson(json['areaOfIntervention'])
          : null,
      experienceDetails: json['experienceDetails'] != null
          ? ExperienceDetails.fromJson(json['experienceDetails'])
          : null,
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(json['notificationPreferences'])
          : null,
      legalNotice: json['legalNotice'] != null
          ? LegalNotice.fromJson(json['legalNotice'])
          : null,
    );
  }

  static String? formatUrl(dynamic url) {
    if (url == null) return null;
    String urlString = url.toString();
    if (urlString.isEmpty) return null;
    if (urlString.startsWith('http') || urlString.startsWith('assets/'))
      return urlString;

    final String base = Urls.baseUrl.endsWith('/')
        ? Urls.baseUrl.substring(0, Urls.baseUrl.length - 1)
        : Urls.baseUrl;

    // Most backends serve static files at /uploads/ or directly.
    // Based on your JSON, it starts with /images, /portfolio, etc.
    final String path = urlString.startsWith('/') ? urlString : '/$urlString';
    return "$base$path";
  }
}

class User {
  final String? id;
  final String? name;
  final String? email;
  final String? profile;
  final String? description;
  final bool? verified;
  final bool isSubscribed;
  final String? subscriptionStatus;
  final String? phone;
  final List<dynamic>? roles;
  final String? activeRole;
  final String? stripeCustomerId;
  final String? subscriptionTier;
  final bool? isOnline;
  final String? lastActive;

  User({
    this.id,
    this.name,
    this.email,
    this.profile,
    this.description,
    this.verified,
    this.isSubscribed = false,
    this.subscriptionStatus,
    this.phone,
    this.roles,
    this.activeRole,
    this.stripeCustomerId,
    this.subscriptionTier,
    this.isOnline,
    this.lastActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      profile: ProfessionalProfileModel.formatUrl(json['profile']),
      description: json['description'],
      verified: json['verified'] == true,
      isSubscribed:
          json['subscription'] != null || json['isSubscribed'] == true,
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      phone: json['phone'],
      roles: json['roles'],
      activeRole: json['activeRole'],
      stripeCustomerId: json['stripeCustomerId'],
      subscriptionTier: json['subscriptionTier'],
      isOnline: json['isOnline'],
      lastActive: json['lastActive'],
    );
  }
}

class Statistics {
  final Bookings? bookings;
  final Revenue? revenue;

  Statistics({this.bookings, this.revenue});

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      bookings: json['bookings'] != null
          ? Bookings.fromJson(json['bookings'])
          : null,
      revenue: json['revenue'] != null
          ? Revenue.fromJson(json['revenue'])
          : null,
    );
  }
}

class Bookings {
  final int? count;
  final int? thisWeek;

  Bookings({this.count, this.thisWeek});

  factory Bookings.fromJson(Map<String, dynamic> json) {
    return Bookings(count: json['count'], thisWeek: json['thisWeek']);
  }
}

class Revenue {
  final int? amount;
  final int? percentageChange;

  Revenue({this.amount, this.percentageChange});

  factory Revenue.fromJson(Map<String, dynamic> json) {
    return Revenue(
      amount: json['amount'],
      percentageChange: json['percentageChange'],
    );
  }
}

class AreaOfIntervention {
  final String? mainCity;
  final String? department;
  final String? radius;
  final bool? availableForTravel;

  AreaOfIntervention({
    this.mainCity,
    this.department,
    this.radius,
    this.availableForTravel,
  });

  factory AreaOfIntervention.fromJson(Map<String, dynamic> json) {
    return AreaOfIntervention(
      mainCity: json['mainCity'],
      department: json['department'],
      radius: json['radius'],
      availableForTravel: json['availableForTravel'],
    );
  }
}

class ExperienceDetails {
  final String? yearsOfExperience;
  final String? projectsCompleted;
  final String? education;

  ExperienceDetails({
    this.yearsOfExperience,
    this.projectsCompleted,
    this.education,
  });

  factory ExperienceDetails.fromJson(Map<String, dynamic> json) {
    return ExperienceDetails(
      yearsOfExperience: json['yearsOfExperience'],
      projectsCompleted: json['projectsCompleted'],
      education: json['education'],
    );
  }
}

class NotificationPreferences {
  final bool? emailNewRequests;
  final bool? smsUrgentRequests;
  final bool? newsletterPros;
  final bool? customerReviewReminder;

  NotificationPreferences({
    this.emailNewRequests,
    this.smsUrgentRequests,
    this.newsletterPros,
    this.customerReviewReminder,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      emailNewRequests: json['emailNewRequests'],
      smsUrgentRequests: json['smsUrgentRequests'],
      newsletterPros: json['newsletterPros'],
      customerReviewReminder: json['customerReviewReminder'],
    );
  }
}

class LegalNotice {
  final bool? acceptedTerms;
  final bool? privacyPolicy;
  final bool? gdprAuthorization;

  LegalNotice({this.acceptedTerms, this.privacyPolicy, this.gdprAuthorization});

  factory LegalNotice.fromJson(Map<String, dynamic> json) {
    return LegalNotice(
      acceptedTerms: json['acceptedTerms'],
      privacyPolicy: json['privacyPolicy'],
      gdprAuthorization: json['gdprAuthorization'],
    );
  }
}
