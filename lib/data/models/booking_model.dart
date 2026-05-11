import 'package:flutter/foundation.dart';

class BookingModel {
  int? statusCode;
  bool? success;
  String? message;
  Meta? meta;
  List<Booking>? data;

  BookingModel({
    this.statusCode,
    this.success,
    this.message,
    this.meta,
    this.data,
  });

  BookingModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    success = json['success'];
    message = json['message'];
    meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
    if (json['data'] != null) {
      data = <Booking>[];
      if (json['data'] is List) {
        json['data'].forEach((v) {
          data!.add(Booking.fromJson(v));
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['statusCode'] = statusCode;
    dataMap['success'] = success;
    dataMap['message'] = message;
    if (meta != null) {
      dataMap['meta'] = meta!.toJson();
    }
    if (data != null) {
      dataMap['data'] = data!.map((v) => v.toJson()).toList();
    }
    return dataMap;
  }
}

class Meta {
  int? page;
  int? limit;
  int? total;
  int? totalPages;

  Meta({this.page, this.limit, this.total, this.totalPages});

  Meta.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    limit = json['limit'];
    total = json['total'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['page'] = page;
    data['limit'] = limit;
    data['total'] = total;
    data['totalPages'] = totalPages;
    return data;
  }
}

class Booking {
  String? sId;
  String? bookingId;
  Service? serviceId;
  Provider? providerId;
  User? clientId;
  String? bookingDate;
  String? startTime;
  String? endTime;
  double? totalPrice;
  String? currency;
  String? status;
  String? paymentStatus;
  String? pricingType;
  PricingDetails? pricingDetails;
  Package? package;
  List<CustomOption>? customOptions;
  String? createdAt;
  String? updatedAt;
  double? depositPercentage;
  double? depositAmount;
  double? balanceAmount;

  Booking({
    this.sId,
    this.bookingId,
    this.serviceId,
    this.providerId,
    this.clientId,
    this.bookingDate,
    this.startTime,
    this.endTime,
    this.totalPrice,
    this.currency,
    this.status,
    this.paymentStatus,
    this.pricingType,
    this.pricingDetails,
    this.package,
    this.customOptions,
    this.createdAt,
    this.updatedAt,
    this.depositPercentage,
    this.depositAmount,
    this.balanceAmount,
  });

  Booking.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    bookingId = json['bookingId'];
    serviceId = json['serviceId'] != null
        ? Service.fromJson(json['serviceId'])
        : null;
    providerId = json['providerId'] != null
        ? Provider.fromJson(json['providerId'])
        : null;
    clientId = json['clientId'] != null
        ? User.fromJson(json['clientId'])
        : null;
    bookingDate = json['bookingDate'] ?? json['date'];
    startTime = json['startTime'];
    endTime = json['endTime'];

    pricingDetails = json['pricingDetails'] != null
        ? PricingDetails.fromJson(json['pricingDetails'])
        : null;

    totalPrice =
        (json['totalPrice'] as num?)?.toDouble() ??
        (pricingDetails?.clientTotal);

    currency = json['currency'] ?? pricingDetails?.currency;
    status = json['status'];
    paymentStatus = json['paymentStatus'];
    pricingType = json['pricingType'];
    package = json['package'] != null
        ? Package.fromJson(json['package'])
        : null;
    if (json['customOptions'] != null) {
      customOptions = <CustomOption>[];
      json['customOptions'].forEach((v) {
        customOptions!.add(CustomOption.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    depositPercentage = (json['depositPercentage'] as num?)?.toDouble();
    depositAmount = (json['depositAmount'] as num?)?.toDouble();
    balanceAmount = (json['balanceAmount'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['bookingId'] = bookingId;
    if (serviceId != null) data['serviceId'] = serviceId!.toJson();
    if (providerId != null) data['providerId'] = providerId!.toJson();
    if (clientId != null) data['clientId'] = clientId!.toJson();
    data['bookingDate'] = bookingDate;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['totalPrice'] = totalPrice;
    data['currency'] = currency;
    data['status'] = status;
    data['paymentStatus'] = paymentStatus;
    data['pricingType'] = pricingType;
    if (pricingDetails != null)
      data['pricingDetails'] = pricingDetails!.toJson();
    if (package != null) data['package'] = package!.toJson();
    if (customOptions != null) {
      data['customOptions'] = customOptions!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['depositPercentage'] = depositPercentage;
    data['depositAmount'] = depositAmount;
    data['balanceAmount'] = balanceAmount;
    return data;
  }
}

class PricingDetails {
  double? clientTotal;
  double? baseRate;
  double? subtotal;
  double? commission;
  String? currency;

  PricingDetails({
    this.clientTotal,
    this.baseRate,
    this.subtotal,
    this.commission,
    this.currency,
  });

  PricingDetails.fromJson(Map<String, dynamic> json) {
    clientTotal = (json['clientTotal'] as num?)?.toDouble();
    baseRate = (json['baseRate'] as num?)?.toDouble();
    subtotal = (json['subtotal'] as num?)?.toDouble();
    commission = (json['commission'] as num?)?.toDouble();
    currency = json['currency'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['clientTotal'] = clientTotal;
    data['baseRate'] = baseRate;
    data['subtotal'] = subtotal;
    data['commission'] = commission;
    data['currency'] = currency;
    return data;
  }
}

class Service {
  String? sId;
  String? title;
  String? coverMedia;
  String? cover_media;
  String? cover_image;
  Location? location;

  Service({
    this.sId,
    this.title,
    this.coverMedia,
    this.cover_media,
    this.cover_image,
    this.location,
  });

  Service.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    coverMedia =
        json['coverMedia'] ??
        json['cover_media'] ??
        json['cover_image'] ??
        json['image'] ??
        (json['gallery'] != null && (json['gallery'] as List).isNotEmpty
            ? json['gallery'][0]
            : null);
    cover_media = json['cover_media'];
    cover_image = json['cover_image'];
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['title'] = title;
    data['coverMedia'] = coverMedia;
    data['cover_media'] = cover_media;
    data['cover_image'] = cover_image;
    if (location != null) data['location'] = location!.toJson();
    return data;
  }
}

class Provider {
  String? sId;
  String? name;
  String? profile;

  Provider({this.sId, this.name, this.profile});

  Provider.fromJson(Map<String, dynamic> json) {
    debugPrint("🔍 Provider JSON: $json");
    sId = json['_id'];
    name = json['name'];
    profile =
        json['profile'] ??
        json['profile_image'] ??
        json['image'] ??
        json['avatar'] ??
        json['profile_pic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['profile'] = profile;
    return data;
  }
}

class User {
  String? sId;
  String? name;
  String? profile;

  User({this.sId, this.name, this.profile});

  User.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    profile =
        json['profile'] ??
        json['profile_image'] ??
        json['image'] ??
        json['avatar'] ??
        json['profile_pic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['profile'] = profile;
    return data;
  }
}

class Package {
  String? name;
  double? price;

  Package({this.name, this.price});

  Package.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    price = (json['price'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    return data;
  }
}

class Location {
  String? address;
  String? city;

  Location({this.address, this.city});

  Location.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    city = json['city'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['city'] = city;
    return data;
  }
}

class CustomOption {
  String? name;
  double? price;

  CustomOption({this.name, this.price});

  CustomOption.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    price = (json['price'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    return data;
  }
}
