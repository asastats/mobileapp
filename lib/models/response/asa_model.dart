// ignore_for_file: prefer_null_aware_operators, prefer_if_null_operators
import 'nftValues.dart';
import 'notEval.dart';
import 'total.dart';
import 'values.dart';

class ASAModel {
  List<String>? addresses;
  Total? total;
  List<Values>? values;
  List<NftValues>? nftValues;
  List<NotEval>? notEval;
  Ratiochart? ratioChart;
  Ratiochart? asaChart;
  Ratiochart? nftChart;
  String? message;
  String? information;
  Map<String, String>? colors;
  Map<String, String>? nftColors;

  ASAModel({
    this.addresses,
    this.total,
    this.values,
    this.nftValues,
    this.ratioChart,
    this.asaChart,
    this.nftChart,
    this.colors,
    this.nftColors,
    this.notEval,
    this.message,
    this.information,
  });

  ASAModel copyWith({
    List<String>? addresses,
    Total? total,
    List<Values>? values,
    List<NftValues>? nftValues,
    List<NotEval>? notEval,
    Ratiochart? ratioChart,
    Ratiochart? asaChart,
    Ratiochart? nftChart,
    Map<String, String>? colors,
    Map<String, String>? nftColors,
    String? message,
    String? information,
  }) {
    return ASAModel(
      addresses: addresses ?? this.addresses,
      total: total ?? this.total,
      values: values ?? this.values,
      nftValues: nftValues ?? this.nftValues,
      ratioChart: ratioChart ?? this.ratioChart,
      asaChart: asaChart ?? this.asaChart,
      nftChart: nftChart ?? this.nftChart,
      colors: colors ?? this.colors,
      nftColors: nftColors ?? this.nftColors,
      notEval: notEval ?? this.notEval,
      message: message ?? this.message,
      information: information ?? this.information,
    );
  }

  ASAModel.fromJson(Map<String, dynamic> json) {
    addresses = json['addresses'].cast<String>();
    total = json['total'] != null ? Total.fromJson(json['total']) : null;
    if (json['values'] != null) {
      values = <Values>[];
      json['values'].forEach((v) {
        values!.add(Values.fromJson(v ?? {}));
      });
    }
    if (json['nft_values'] != null) {
      nftValues = <NftValues>[];
      json['nft_values'].forEach((v) {
        nftValues!.add(NftValues.fromJson(v ?? {}));
      });
    }
    if (json['noteval'] != null) {
      notEval = <NotEval>[];
      json['noteval'].forEach((v) {
        notEval!.add(NotEval.fromJson(v ?? {}));
      });
    }
    ratioChart = json['ratiochart'] != null
        ? Ratiochart.fromJson(json['ratiochart'] ?? {})
        : null;
    asaChart = json['asachart'] != null
        ? Ratiochart.fromJson(json['asachart'] ?? {})
        : null;
    nftChart = json['nftchart'] != null
        ? Ratiochart.fromJson(json['nftchart'] ?? {})
        : null;
    colors = json['colors'] != null
        ? Map<String, String>.from(json['colors'] ?? {})
        : null;
    nftColors = json['nft_colors'] != null
        ? Map<String, String>.from(json['nft_colors'] ?? {})
        : null;
    message = json['message'];
    information = json['information'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['addresses'] = addresses;
    if (total != null) {
      data['total'] = total!.toJson();
    }
    if (values != null) {
      data['values'] = values!.map((v) => v.toJson()).toList();
    }
    if (nftValues != null) {
      data['nft_values'] = nftValues!.map((v) => v.toJson()).toList();
    }
    if (notEval != null) {
      data['noteval'] = notEval!.map((v) => v.toJson()).toList();
    }
    if (ratioChart != null) {
      data['ratiochart'] = ratioChart!.toJson();
    }
    if (asaChart != null) {
      data['asachart'] = asaChart!.toJson();
    }
    if (nftChart != null) {
      data['nftchart'] = nftChart!.toJson();
    }
    if (colors != null) {
      data['colors'] = colors!;
    }
    if (nftColors != null) {
      data['nft_colors'] = nftColors!;
    }
    if (message != null) {
      data['message'] = message!;
    }
    if (information != null) {
      data['information'] = information!;
    }
    return data;
  }
}

class Creator {
  String? name;
  String? description;
  String? address;

  Creator({this.name, this.description, this.address});

  Creator.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    data['address'] = address;
    return data;
  }
}

class Royalties {
  String? name;
  String? addr;
  int? share;

  Royalties({this.name, this.addr, this.share});

  Royalties.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    addr = json['addr'];
    share = json['share'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['addr'] = addr;
    data['share'] = share;
    return data;
  }
}

class Ratiochart {
  List<String>? labels;
  List<Datasets>? datasets;

  Ratiochart({this.labels, this.datasets});

  Ratiochart.fromJson(Map<String, dynamic> json) {
    labels = json['labels'].cast<String>();
    if (json['datasets'] != null) {
      datasets = <Datasets>[];
      json['datasets'].forEach((v) {
        datasets!.add(Datasets.fromJson(v ?? {}));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['labels'] = labels;
    if (datasets != null) {
      data['datasets'] = datasets!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Datasets {
  String? label;
  List<String>? data;
  List<String>? backgroundColor;
  int? borderWidth;
  int? hoverOffset;

  Datasets(
      {this.label,
      this.data,
      this.backgroundColor,
      this.borderWidth,
      this.hoverOffset});

  Datasets.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    data = json['data'].cast<String>();
    backgroundColor = json['backgroundColor'].cast<String>();
    borderWidth = json['borderWidth'];
    hoverOffset = json['hoverOffset'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = label;
    data['data'] = this.data;
    data['backgroundColor'] = backgroundColor;
    data['borderWidth'] = borderWidth;
    data['hoverOffset'] = hoverOffset;
    return data;
  }
}
