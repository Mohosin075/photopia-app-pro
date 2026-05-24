class ServiceDuration {
  int? value;
  String? unit; // 'minute' or 'hour'

  ServiceDuration({this.value, this.unit});

  factory ServiceDuration.fromJson(dynamic json) {
    if (json == null) {
      return ServiceDuration(value: 1, unit: 'hour');
    }
    if (json is Map) {
      return ServiceDuration(
        value: (json['value'] as num?)?.toInt() ?? 1,
        unit: json['unit']?.toString() ?? 'hour',
      );
    }
    // Backward compatibility: parse from String or numeric
    String rawStr = json.toString().trim();
    int val = 1;
    String unit = 'hour';
    if (rawStr.toLowerCase().contains('min')) {
      unit = 'minute';
    }
    // Extract the first consecutive digits
    RegExp numReg = RegExp(r'\d+');
    Match? match = numReg.firstMatch(rawStr);
    if (match != null) {
      val = int.tryParse(match.group(0)!) ?? 1;
    } else {
      val = int.tryParse(rawStr) ?? 1;
    }
    return ServiceDuration(value: val, unit: unit);
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
    };
  }

  int get totalMinutes {
    if (unit == 'minute') {
      return value ?? 0;
    } else {
      return (value ?? 0) * 60;
    }
  }

  String get formattedDisplay {
    if (value == null) return 'Flexible';
    if (unit == 'minute') {
      return '$value min${value! > 1 ? 's' : ''}';
    } else {
      return '$value hr${value! > 1 ? 's' : ''}';
    }
  }
}
