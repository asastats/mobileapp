class Urls {
  String? uRL;
  String? externalUrl;
  String? animationUrl;
  String? externalLink;

  Urls({this.uRL, this.externalUrl, this.animationUrl, this.externalLink});

  Urls.fromJson(Map<String, dynamic> json) {
    uRL = json['URL'];
    externalUrl = json['external_url'];
    animationUrl = json['animation_url'];
    externalLink = json['external_link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['URL'] = uRL;
    data['external_url'] = externalUrl;
    data['animation_url'] = animationUrl;
    data['external_link'] = externalLink;
    return data;
  }
}
