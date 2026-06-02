class UserSettings {
  final bool pushNotification;
  final bool emailNotification;
  final bool smsNotification;
  final bool locationService;
  final String profileStatus;
  final bool dndMode;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final List<String> disabledCategories;

  UserSettings({
    this.pushNotification = true,
    this.emailNotification = true,
    this.smsNotification = true,
    this.locationService = true,
    this.profileStatus = 'public',
    this.dndMode = false,
    this.quietHoursEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.disabledCategories = const [],
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      pushNotification: json['pushNotification'] ?? true,
      emailNotification: json['emailNotification'] ?? true,
      smsNotification: json['smsNotification'] ?? true,
      locationService: json['locationService'] ?? true,
      profileStatus: json['profileStatus'] ?? 'public',
      dndMode: json['dndMode'] ?? false,
      quietHoursEnabled: json['quietHoursEnabled'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '08:00',
      disabledCategories: json['disabledCategories'] != null
          ? List<String>.from(json['disabledCategories'])
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotification': pushNotification,
      'emailNotification': emailNotification,
      'smsNotification': smsNotification,
      'locationService': locationService,
      'profileStatus': profileStatus,
      'dndMode': dndMode,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'disabledCategories': disabledCategories,
    };
  }
}

class UserProfileModel {
  final String? id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? profile;
  final String? location;
  final String? role;
  final String? description;
  final String? specialty;
  final List<String>? languages;
  final String? createdAt;
  final bool isSubscribed;
  final String? subscriptionStatus;
  final UserSettings? settings;

  UserProfileModel({
    this.id,
    this.fullName,
    this.email,
    this.phone,
    this.profile,
    this.location,
    this.role,
    this.description,
    this.specialty,
    this.languages,
    this.createdAt,
    this.isSubscribed = false,
    this.subscriptionStatus,
    this.settings,
  });

  bool get isPremium =>
      isSubscribed == true ||
      subscriptionStatus == 'active' ||
      subscriptionStatus == 'trialing';

  static String? _formatUrl(dynamic url) {
    if (url == null) return null;
    String? urlString;
    if (url is String) {
      urlString = url;
    } else if (url is Map && url.containsKey('url')) {
      urlString = url['url']?.toString();
    } else {
      urlString = url.toString();
    }
    return urlString;
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    String? tempLocation;
    if (json['location'] != null) {
      if (json['location'] is String) {
        tempLocation = json['location'];
      } else if (json['location'] is Map) {
        tempLocation = json['location']['city']?.toString() ?? 'Custom Location';
      }
    }

    return UserProfileModel(
      id: json['_id']?.toString(),
      fullName: (json['name'] ?? json['fullName'])?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      profile: _formatUrl(json['profile']),
      location: tempLocation ?? json['location']?.toString(),
      role: (json['activeRole'] ?? json['role'])?.toString(),
      description: json['description']?.toString(),
      specialty: json['specialty']?.toString(),
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
      createdAt: json['createdAt']?.toString(),
      isSubscribed: json['subscription'] != null || json['isSubscribed'] == true,
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      settings: json['settings'] != null ? UserSettings.fromJson(json['settings']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profile': profile,
      'location': location,
      'role': role,
      'description': description,
      'specialty': specialty,
      'languages': languages,
      'createdAt': createdAt,
      'settings': settings?.toJson(),
    };
  }
}
