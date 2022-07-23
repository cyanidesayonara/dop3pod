class Episode {
  final String? title;
  final String? pubDate;
  final String? description;
  final String? length;
  final String? url;
  final String? kind;
  final String? size;

  Episode({
    required this.title,
    required this.pubDate,
    required this.description,
    required this.length,
    required this.url,
    required this.kind,
    required this.size,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      title: json['title'],
      pubDate: json['pub_date'],
      description: json['description'],
      length: json['length'],
      url: json['url'],
      kind: json['kind'],
      size: json['size'],
    );
  }
}
