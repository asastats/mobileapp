class Links {
  String? provider;
  String? link;
  String? title;

  Links({this.provider, this.link});

  Links.fromJson(Map<String, dynamic> json) {
    provider = json['provider'];
    link = json['link'];
    title = json['title'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['provider'] = provider;
    data['link'] = link;
    data['title'] = title;
    return data;
  }
}

class Link {
  Link({
    this.small,
    this.linktext,
    this.link,
    this.title,
  });

  String? small;
  String? linktext;
  String? link;
  String? title;

  factory Link.fromJson(Map<String, dynamic> json) => Link(
        small: json["small"],
        linktext: json["linktext"] == null ? null : json["linktext"],
        link: json["link"] == null ? null : json["link"],
        title: json["title"] == null ? null : json["title"],
      );

  Map<String, dynamic> toJson() => {
        "small": small,
        "linktext": linktext,
        "link": link,
        "title": title,
      };
}
