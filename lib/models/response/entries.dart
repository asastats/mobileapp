import 'amount.dart';
import 'links.dart';
import 'price.dart';
import 'value.dart';

class Entries {
  Entries({
    this.value,
    this.links,
    this.amount,
    this.price,
  });

  Value? value;
  List<Link>? links;
  Amount? amount;
  Price? price;

  factory Entries.fromJson(Map<String, dynamic> json) => Entries(
        value: json["value"] == null ? null : Value.fromJson(json["value"]),
        links: json["links"] == null
            ? null
            : List<Link>.from(json["links"].map((x) => Link.fromJson(x))),
        amount: json["amount"] == null ? null : Amount.fromJson(json["amount"]),
        price: json["price"] == null ? null : Price.fromJson(json["price"]),
      );

  Map<String, dynamic> toJson() => {
        "value": value?.toJson() ?? {},
        "links": List<Map<String, dynamic>>.from(
            links?.map((x) => x.toJson()) ?? {}),
        "amount": amount?.toJson() ?? {},
        "price": price?.toJson() ?? {},
      };
}
