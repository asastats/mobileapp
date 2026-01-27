class Transaction {
  double? price;
  String? text;
  String? link;
  int? epoch;

  Transaction({this.price, this.text, this.link, this.epoch});

  Transaction.fromJson(Map<String, dynamic> json) {
    price = (json['price'] ?? 0).toDouble();
    text = json['text'];
    link = json['link'];
    epoch = json['epoch'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['price'] = price;
    data['text'] = text;
    data['link'] = link;
    data['epoch'] = epoch;
    return data;
  }
}
