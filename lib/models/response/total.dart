class Total {
  double? algo;
  double? asa;
  double? nft;
  double? total;
  double? totalusdc;
  double? priceusdc;
  double? pricealgo;
  int? noteval;

  Total(
      {this.algo,
      this.asa,
      this.nft,
      this.total,
      this.totalusdc,
      this.priceusdc,
      this.pricealgo,
      this.noteval});

  Total.fromJson(Map<String, dynamic> json) {
    algo = (json['algo'] ?? 0).toDouble();
    asa = (json['asa'] ?? 0).toDouble();
    nft = (json['nft'] ?? 0).toDouble();
    total = (json['total'] ?? 0).toDouble();
    totalusdc = (json['totalusdc'] ?? 0).toDouble();
    priceusdc = (json['priceusdc'] ?? 0).toDouble();
    pricealgo = (json['pricealgo'] ?? 0).toDouble();
    noteval = json['noteval'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['algo'] = algo;
    data['asa'] = asa;
    data['nft'] = nft;
    data['total'] = total;
    data['totalusdc'] = totalusdc;
    data['priceusdc'] = priceusdc;
    data['pricealgo'] = pricealgo;
    data['noteval'] = noteval;
    return data;
  }
}
