class PaymentMethodModel {
  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  PaymentMethodModel({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] ?? '',
      brand: json['brand'] ?? 'unknown',
      last4: json['last4'] ?? '****',
      expMonth: json['expMonth'] ?? 0,
      expYear: json['expYear'] ?? 0,
      isDefault: json['isDefault'] ?? false,
    );
  }
}
