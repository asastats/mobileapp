class Listed {
  double? price;
  String? text;
  String? link;

  Listed({this.price, this.text, this.link});

  Listed.fromJson(Map<String, dynamic> json) {
    price = (json['price'] ?? 0).toDouble();
    text = json['text'];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['price'] = price;
    data['text'] = text;
    data['link'] = link;
    return data;
  }
}
