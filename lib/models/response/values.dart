import 'asa.dart';
import 'dapps.dart';

class Values {
  double? value;
  int? id;
  double? amount;
  Asa? asa;
  List<Dapps>? dapps;
  double? price;

  Values(
      {this.value,
      this.id,
      this.amount,
      this.asa,
      this.dapps,
      this.price});

  Values.fromJson(Map<String, dynamic> json) {
    value = (json['value'] ?? 0).toDouble();
    id = json['id'];
    amount = (json['amount'] ?? 0.0).toDouble();
    asa = json['asa'] != null ? Asa.fromJson(json['asa'] ?? {}) : null;
    if (json['dapps'] != null) {
      dapps = <Dapps>[];
      json['dapps'].forEach((v) {
        dapps!.add(Dapps.fromJson(v ?? {}));
      });
    }
    price = (json['price'] ?? 0).toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['value'] = value;
    data['id'] = id;
    data['amount'] = amount;
    if (asa != null) {
      data['asa'] = asa!.toJson();
    }
    if (dapps != null) {
      data['dapps'] = dapps!.map((v) => v.toJson()).toList();
    }
    data['price'] = price;
    return data;
  }
}
