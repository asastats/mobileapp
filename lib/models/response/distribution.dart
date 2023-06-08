class Distribution {
  double? value;
  double? amount;
  double? price;
  String? text;
  String? link;

  Distribution({this.value, this.amount, this.price, this.text, this.link});

  Distribution.fromJson(Map<String, dynamic> json) {
    value = json['value'];
    amount = json['amount'];
    price = json['price'];
    text = json['text'];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['value'] = value;
    data['amount'] = amount;
    data['price'] = price;
    data['text'] = text;
    data['link'] = link;
    return data;
  }
}
