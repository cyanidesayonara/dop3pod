class Podcast {
  final int id;
  final String? title;
  final String? artist;
  final int? podId;
  final String? feedUrl;
  final String? artworkUrl;
  final String? reviewsUrl;
  final String? country;
  final bool? explicit;
  final String? primaryGenre;
  final String? copyrightText;
  final String? description;
  final bool? discriminate;

  Podcast({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.copyrightText,
    required this.description,
    this.podId,
    this.feedUrl,
    this.reviewsUrl,
    this.country,
    this.explicit,
    this.primaryGenre,
    this.discriminate,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      podId: json['pod_id'],
      feedUrl: json['feed_url'],
      artworkUrl: json['artwork_url'],
      reviewsUrl: json['reviews_url'],
      country: json['country'],
      explicit: json['explicit'],
      primaryGenre: json['primary_genre'],
      copyrightText: json['copyright_text'],
      description: json['description'],
      discriminate: json['discriminate'],
    );
  }
}
