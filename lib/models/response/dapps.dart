import 'distribution.dart';
import 'entries.dart';

class Dapps {
  String? dapp;
  double? value;
  double? price;
  String? link;
  double? available;
  double? amount;
  dynamic proxy;
  List<Distribution>? distribution;
  String? name;
  int? appId;
  String? address;
  List<String>? staking;
  dynamic committed;
  dynamic reward;
  dynamic next;
  Entries? entries;

  Dapps(
      {this.dapp,
      this.value,
      this.price,
      this.link,
      this.available,
      this.amount,
      this.proxy,
      this.distribution,
      this.name,
      this.appId,
      this.address,
      this.staking,
      this.committed,
      this.reward,
      this.next,
      this.entries});

  Dapps.fromJson(Map<String, dynamic> json) {
    dapp = json['dapp'];
    value = (json['value'] ?? 0).toDouble();
    price = json['price'];
    link = json['link'];
    available = json['available'];
    amount = json['amount'];
    proxy = json['proxy'];
    if (json['distribution'] != null) {
      distribution = <Distribution>[];
      json['distribution'].forEach((v) {
        distribution!.add(Distribution.fromJson(v ?? {}));
      });
    }
    name = json['name'];
    appId = json['app_id'];
    address = json['address'];
    staking = (json['staking'] ?? [""]).cast<String>();
    committed = json['committed'];
    reward = json['reward'];
    next = json['next'];
    entries = Entries.fromJson(json["entries"] ?? {});
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['dapp'] = dapp;
    data['value'] = value;
    data['price'] = price;
    data['link'] = link;
    data['available'] = available;
    data['amount'] = amount;
    data['proxy'] = proxy;
    if (distribution != null) {
      data['distribution'] = distribution!.map((v) => v.toJson()).toList();
    }
    data['name'] = name;
    data['app_id'] = appId;
    data['address'] = address;
    data['staking'] = staking;
    data['committed'] = committed;
    data['reward'] = reward;
    data['next'] = next;
    data['entries'] = entries?.toJson();
    return data;
  }
}
