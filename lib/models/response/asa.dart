import 'links.dart';

class Asa {
  int? id;
  String? name;
  String? unit;
  String? total;
  int? decimals;
  String? url;
  List<Links>? links;

  Asa({
    this.id,
    this.name,
    this.unit,
    this.total,
    this.url,
    this.decimals,
    this.links,
  });

  Asa.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    unit = json['unit'];
    total = json['total'].toString();
    decimals = json['decimals'];
    url = json['url'];
    // links = json['links'] != null ? Links.fromJson(json['links'] ?? {}) : null;
    if (json['links'] != null) {
      links = <Links>[];
      json['links'].forEach((v) {
        links!.add(Links.fromJson(v ?? {}));
      });
    }
    // if (json['entries'] != null) {
    //   entries = Entries;
    //   json['entries'].forEach((v) {
    //     entries!.add(Entries.fromJson(v ?? {}));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['unit'] = unit;
    data['total'] = total;
    data['decimals'] = decimals;
    data['url'] = url;
    // if (this.links != null) {
    //   data['links'] = this.links!.toJson();
    // }
    if (links != null) {
      data['links'] = links!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
