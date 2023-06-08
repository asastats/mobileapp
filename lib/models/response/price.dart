class Price {
  Price({
    this.price,
    this.unit,
  });

  double? price;
  String? unit;

  factory Price.fromJson(Map<String, dynamic> json) => Price(
        price: json["price"] == null ? null : json["price"].toDouble(),
        unit: json["unit"] == null ? null : json["unit"],
      );

  Map<String, dynamic> toJson() => {
        "price": price,
        "unit": unit,
      };
}
