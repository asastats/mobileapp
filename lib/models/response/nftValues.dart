import 'listed.dart';
import 'transaction.dart';
import 'urls.dart';

class NftValues {
  double? value;
  String? collection;
  double? amount;
  List<Nfts>? nfts;

  NftValues({this.value, this.collection, this.amount, this.nfts});

  NftValues.fromJson(Map<String, dynamic> json) {
    value = (json['value'] ?? 0).toDouble();
    collection = json['collection'];
    amount = json['amount'].toDouble();
    if (json['nfts'] != null) {
      nfts = <Nfts>[];
      json['nfts'].forEach((v) {
        nfts!.add(Nfts.fromJson(v ?? {}));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['value'] = value;
    data['collection'] = collection;
    data['amount'] = amount;
    if (nfts != null) {
      data['nfts'] = nfts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Nfts {
  double? value;
  int? id;
  num? amount;
  Nft? nft;
  double? price;
  String? creator;

  Nfts({this.value, this.id, this.amount, this.nft, this.price, this.creator});

  Nfts.fromJson(Map<String, dynamic> json) {
    value = (json['value'] ?? 0).toDouble();
    id = json['id'];
    try {
      amount = json['amount'];
    } catch (e) {
      print("Cant parse amount" + e.toString());
    }
    // amount = json['amount'];
    nft = json['nft'] != null ? Nft.fromJson(json['nft'] ?? {}) : null;
    price = (json['price'] ?? 0).toDouble();
    creator = json['creator'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['value'] = value;
    data['id'] = id;
    data['amount'] = amount;
    if (nft != null) {
      data['nft'] = nft!.toJson();
    }
    data['price'] = price;
    data['creator'] = creator;
    return data;
  }
}

class Nft {
  int? id;
  String? name;
  String? unit;
  int? total;
  String? collection;
  Map<String, dynamic>? urls;
  String? path;
  String? tpath;
  List<Listed>? listed;
  Transaction? last;
  Transaction? max;
  Transaction? floor;
  Map<String, dynamic>? attrs;
  String? title;
  String? desc;
  String? rarity;
  String? hash;

  Nft(
      {this.id,
      this.name,
      this.unit,
      this.total,
      this.collection,
      this.urls,
      this.path,
      this.tpath,
      this.listed,
      this.last,
      this.max,
      this.floor,
      this.attrs,
      this.title,
      this.desc,
      this.rarity,
      this.hash});

  Nft.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    unit = json['unit'] ?? '';
    total = json['total'];
    collection = json['collection'];
    urls = json['urls'] != null ? json['urls'] ?? {} : null;
    path = json['path'];
    tpath = json['tpath'];
    final rawListed = json['listed'];
    if (rawListed is List) {
      listed = rawListed.map((e) => Listed.fromJson(e)).toList();
    } else if (rawListed is Map<String, dynamic> && rawListed.containsKey('price')) {
      listed = [Listed.fromJson(rawListed)];
    } else {
      listed = [];
    }
    last =
        json['last'] != null ? Transaction.fromJson(json['last'] ?? {}) : null;
    max = json['max'] != null ? Transaction.fromJson(json['max'] ?? {}) : null;
    floor = json['floor'] != null
        ? Transaction.fromJson(json['floor'] ?? {})
        : null;
    attrs = json['attrs'] != null
        ? Map<String, dynamic>.from(json['attrs'] ?? {})
        : null;
    title = json['title'];
    desc = json['desc'];
    rarity = json['rarity'];
    hash = json['hash'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (unit != null) {
      data['unit'] = unit;
    }
    data['total'] = total;
    data['collection'] = collection;
    if (urls != null) {
      data['urls'] = urls!;
    }
    data['path'] = path;
    data['tpath'] = tpath;
    if (listed != null && listed!.isNotEmpty) {
      data['listed'] = listed!.map((e) => e.toJson()).toList();
    }
    if (last != null) {
      data['last'] = last!.toJson();
    }
    if (max != null) {
      data['max'] = max!.toJson();
    }
    if (floor != null) {
      data['floor'] = floor!.toJson();
    }
    if (attrs != null) {
      data['attrs'] = attrs!;
    }
    data['title'] = title;
    data['desc'] = desc;
    data['rarity'] = rarity;
    data['hash'] = hash;
    return data;
  }
}
