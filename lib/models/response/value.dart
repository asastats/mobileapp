class Value {
  Value({
    this.linktext,
    this.link,
    this.title,
    this.text,
    this.border,
    this.value,
    this.bracket,
  });

  String? linktext;
  String? link;
  String? title;
  String? text;
  bool? border;
  double? value;
  bool? bracket;

  factory Value.fromJson(Map<String, dynamic> json) => Value(
        linktext: json["linktext"],
        link: json["link"],
        title: json["title"],
        text: json["text"],
        border: json["border"],
        value: json["value"] == null ? null : json["value"].toDouble(),
        bracket: json["bracket"],
      );

  Map<String, dynamic> toJson() => {
        "linktext": linktext,
        "link": link,
        "title": title,
        "text": text,
        "border": border,
        "value": value,
        "bracket": bracket,
      };
}
