class CalenderSettingsModel {
  int? statusCode;
  bool? success;
  String? message;
  Data? data;

  CalenderSettingsModel(
      {this.statusCode, this.success, this.message, this.data});

  CalenderSettingsModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['statusCode'] = this.statusCode;
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  DefaultSchedule? defaultSchedule;
  Pricing? pricing;
  GoogleCalendarSync? googleCalendarSync;
  String? sId;
  String? providerId;
  String? serviceId;
  List<CustomDates>? customDates;
  List<RecurringRules>? recurringRules;
  List<AvailabilityPeriods>? availabilityPeriods;
  List<BlockedDateRanges>? blockedDateRanges;
  int? bufferMinutes;
  int? advanceNoticeHours;
  int? maxBookingsPerDay;
  int? maxBookingsPerWeek;
  bool? autoBlockAfterBooking;
  int? autoBlockDuration;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? id;

  Data(
      {this.defaultSchedule,
      this.pricing,
      this.googleCalendarSync,
      this.sId,
      this.providerId,
      this.serviceId,
      this.customDates,
      this.recurringRules,
      this.availabilityPeriods,
      this.blockedDateRanges,
      this.bufferMinutes,
      this.advanceNoticeHours,
      this.maxBookingsPerDay,
      this.maxBookingsPerWeek,
      this.autoBlockAfterBooking,
      this.autoBlockDuration,
      this.createdAt,
      this.updatedAt,
      this.iV,
      this.id});

  Data.fromJson(Map<String, dynamic> json) {
    defaultSchedule = json['defaultSchedule'] != null
        ? new DefaultSchedule.fromJson(json['defaultSchedule'])
        : null;
    pricing =
        json['pricing'] != null ? new Pricing.fromJson(json['pricing']) : null;
    googleCalendarSync = json['googleCalendarSync'] != null
        ? new GoogleCalendarSync.fromJson(json['googleCalendarSync'])
        : null;
    sId = json['_id'];
    providerId = json['providerId'];
    serviceId = json['serviceId'];
    if (json['customDates'] != null) {
      customDates = <CustomDates>[];
      json['customDates'].forEach((v) {
        customDates!.add(new CustomDates.fromJson(v));
      });
    }
    if (json['recurringRules'] != null) {
      recurringRules = <RecurringRules>[];
      json['recurringRules'].forEach((v) {
        recurringRules!.add(new RecurringRules.fromJson(v));
      });
    }
    if (json['availabilityPeriods'] != null) {
      availabilityPeriods = <AvailabilityPeriods>[];
      json['availabilityPeriods'].forEach((v) {
        availabilityPeriods!.add(new AvailabilityPeriods.fromJson(v));
      });
    }
    if (json['blockedDateRanges'] != null) {
      blockedDateRanges = <BlockedDateRanges>[];
      json['blockedDateRanges'].forEach((v) {
        blockedDateRanges!.add(new BlockedDateRanges.fromJson(v));
      });
    }
    bufferMinutes = json['bufferMinutes'];
    advanceNoticeHours = json['advanceNoticeHours'];
    maxBookingsPerDay = json['maxBookingsPerDay'];
    maxBookingsPerWeek = json['maxBookingsPerWeek'];
    autoBlockAfterBooking = json['autoBlockAfterBooking'];
    autoBlockDuration = json['autoBlockDuration'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.defaultSchedule != null) {
      data['defaultSchedule'] = this.defaultSchedule!.toJson();
    }
    if (this.pricing != null) {
      data['pricing'] = this.pricing!.toJson();
    }
    if (this.googleCalendarSync != null) {
      data['googleCalendarSync'] = this.googleCalendarSync!.toJson();
    }
    if (this.sId != null) data['_id'] = this.sId;
    if (this.providerId != null) data['providerId'] = this.providerId;
    if (this.serviceId != null) data['serviceId'] = this.serviceId;
    if (this.customDates != null) {
      data['customDates'] = this.customDates!.map((v) => v.toJson()).toList();
    }
    if (this.recurringRules != null) {
      data['recurringRules'] =
          this.recurringRules!.map((v) => v.toJson()).toList();
    }
    if (this.availabilityPeriods != null) {
      data['availabilityPeriods'] =
          this.availabilityPeriods!.map((v) => v.toJson()).toList();
    }
    if (this.blockedDateRanges != null) {
      data['blockedDateRanges'] =
          this.blockedDateRanges!.map((v) => v.toJson()).toList();
    }
    if (this.bufferMinutes != null) data['bufferMinutes'] = this.bufferMinutes;
    if (this.advanceNoticeHours != null) data['advanceNoticeHours'] = this.advanceNoticeHours;
    if (this.maxBookingsPerDay != null) data['maxBookingsPerDay'] = this.maxBookingsPerDay;
    if (this.maxBookingsPerWeek != null) data['maxBookingsPerWeek'] = this.maxBookingsPerWeek;
    if (this.autoBlockAfterBooking != null) data['autoBlockAfterBooking'] = this.autoBlockAfterBooking;
    if (this.autoBlockDuration != null) data['autoBlockDuration'] = this.autoBlockDuration;
    if (this.createdAt != null) data['createdAt'] = this.createdAt;
    if (this.updatedAt != null) data['updatedAt'] = this.updatedAt;
    if (this.iV != null) data['__v'] = this.iV;
    if (this.id != null) data['id'] = this.id;
    return data;
  }
}

class Pricing {
  String? model;
  double? baseRate;
  double? weekendRate;

  Pricing({this.model, this.baseRate, this.weekendRate});

  Pricing.fromJson(Map<String, dynamic> json) {
    model = json['model'];
    baseRate = (json['baseRate'] as num?)?.toDouble();
    weekendRate = (json['weekendRate'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['model'] = model;
    data['baseRate'] = baseRate;
    data['weekendRate'] = weekendRate;
    return data;
  }
}

class DefaultSchedule {
  Monday? monday;
  Monday? tuesday;
  Monday? wednesday;
  Monday? thursday;
  Monday? friday;
  Monday? saturday;
  Monday? sunday;

  DefaultSchedule(
      {this.monday,
      this.tuesday,
      this.wednesday,
      this.thursday,
      this.friday,
      this.saturday,
      this.sunday});

  DefaultSchedule.fromJson(Map<String, dynamic> json) {
    monday =
        json['monday'] != null ? new Monday.fromJson(json['monday']) : null;
    tuesday =
        json['tuesday'] != null ? new Monday.fromJson(json['tuesday']) : null;
    wednesday = json['wednesday'] != null
        ? new Monday.fromJson(json['wednesday'])
        : null;
    thursday =
        json['thursday'] != null ? new Monday.fromJson(json['thursday']) : null;
    friday =
        json['friday'] != null ? new Monday.fromJson(json['friday']) : null;
    saturday =
        json['saturday'] != null ? new Monday.fromJson(json['saturday']) : null;
    sunday =
        json['sunday'] != null ? new Monday.fromJson(json['sunday']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.monday != null) {
      data['monday'] = this.monday!.toJson();
    }
    if (this.tuesday != null) {
      data['tuesday'] = this.tuesday!.toJson();
    }
    if (this.wednesday != null) {
      data['wednesday'] = this.wednesday!.toJson();
    }
    if (this.thursday != null) {
      data['thursday'] = this.thursday!.toJson();
    }
    if (this.friday != null) {
      data['friday'] = this.friday!.toJson();
    }
    if (this.saturday != null) {
      data['saturday'] = this.saturday!.toJson();
    }
    if (this.sunday != null) {
      data['sunday'] = this.sunday!.toJson();
    }
    return data;
  }
}

class Monday {
  String? start;
  String? end;
  bool? isActive;
  int? maxBookings;
  String? sId;

  Monday({this.start, this.end, this.isActive, this.maxBookings, this.sId});

  Monday.fromJson(Map<String, dynamic> json) {
    start = json['start'];
    end = json['end'];
    isActive = json['isActive'];
    maxBookings = json['maxBookings'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['start'] = this.start;
    data['end'] = this.end;
    data['isActive'] = this.isActive;
    data['maxBookings'] = this.maxBookings;
    data['_id'] = this.sId;
    return data;
  }
}

class GoogleCalendarSync {
  String? calendarId;
  bool? syncEnabled;

  GoogleCalendarSync({this.calendarId, this.syncEnabled});

  GoogleCalendarSync.fromJson(Map<String, dynamic> json) {
    calendarId = json['calendarId'];
    syncEnabled = json['syncEnabled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['calendarId'] = this.calendarId;
    data['syncEnabled'] = this.syncEnabled;
    return data;
  }
}

class CustomDates {
  String? date;
  String? type;
  String? start;
  String? end;
  int? maxBookings;
  String? note;
  double? rateMultiplier;
  String? sId;

  CustomDates(
      {this.date,
      this.type,
      this.start,
      this.end,
      this.maxBookings,
      this.note,
      this.rateMultiplier,
      this.sId});

  CustomDates.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    type = json['type'];
    start = json['start'];
    end = json['end'];
    maxBookings = json['maxBookings'];
    note = json['note'];
    rateMultiplier = json['rateMultiplier'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.date != null) data['date'] = this.date;
    if (this.type != null) data['type'] = this.type;
    if (this.start != null) data['start'] = this.start;
    if (this.end != null) data['end'] = this.end;
    if (this.maxBookings != null) data['maxBookings'] = this.maxBookings;
    if (this.note != null) data['note'] = this.note;
    if (this.rateMultiplier != null) data['rateMultiplier'] = this.rateMultiplier;
    if (this.sId != null) data['_id'] = this.sId;
    return data;
  }
}

class RecurringRules {
  String? type;
  int? dayOfWeek;
  bool? active;
  String? sId;
  String? start;
  String? end;
  int? maxBookings;

  RecurringRules(
      {this.type,
      this.dayOfWeek,
      this.active,
      this.sId,
      this.start,
      this.end,
      this.maxBookings});

  RecurringRules.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    dayOfWeek = json['dayOfWeek'];
    active = json['active'];
    sId = json['_id'];
    start = json['start'];
    end = json['end'];
    maxBookings = json['maxBookings'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['dayOfWeek'] = this.dayOfWeek;
    data['active'] = this.active;
    data['_id'] = this.sId;
    data['start'] = this.start;
    data['end'] = this.end;
    data['maxBookings'] = this.maxBookings;
    return data;
  }
}

class AvailabilityPeriods {
  String? startDate;
  String? endDate;
  String? startTime;
  String? endTime;
  double? priceOverride;

  AvailabilityPeriods({
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.priceOverride,
  });

  AvailabilityPeriods.fromJson(Map<String, dynamic> json) {
    startDate = json['startDate'];
    endDate = json['endDate'];
    startTime = json['startTime'];
    endTime = json['endTime'];
    priceOverride = (json['priceOverride'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['priceOverride'] = priceOverride;
    return data;
  }
}

class BlockedDateRanges {
  String? startDate;
  String? endDate;
  String? note;

  BlockedDateRanges({
    this.startDate,
    this.endDate,
    this.note,
  });

  BlockedDateRanges.fromJson(Map<String, dynamic> json) {
    startDate = json['startDate'];
    endDate = json['endDate'];
    note = json['note'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['note'] = note;
    return data;
  }
}
