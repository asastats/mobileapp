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
    algo = json['algo'];
    asa = json['asa'];
    nft = json['nft'];
    total = json['total'];
    totalusdc = json['totalusdc'];
    priceusdc = json['priceusdc'];
    pricealgo = json['pricealgo'];
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
