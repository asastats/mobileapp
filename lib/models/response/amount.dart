// ignore_for_file: prefer_if_null_operators

class Amount {
  Amount({
    this.text,
    this.amount,
    this.unit,
    this.border,
    this.bracket,
  });

  String? text;
  double? amount;
  String? unit;
  bool? border;
  dynamic bracket;

  factory Amount.fromJson(Map<String, dynamic> json) => Amount(
        text: json["text"] == null ? null : json["text"],
        amount: (json["amount"] ?? 0.0).toDouble(),
        unit: json["unit"] == null ? null : json["unit"],
        border: json["border"] == null ? null : json["border"],
        bracket: json["bracket"],
      );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["text"] = text;
    data["amount"] = amount;
    data["unit"] = unit;
    data["border"] = border;
    data["bracket"] = bracket;
    return data;
  }
}
