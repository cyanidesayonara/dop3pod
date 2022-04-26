import 'dart:developer' as developer;

class Podcast {
  final String? title;
  final String? artist;
  final int? podId;
  final String? feedUrl;
  final String? artworkUrl;
  final String? reviewsUrl;
  final String? country;
  final bool? explicit;
  final String? primaryGenre;
  final String? genres;
  final String? copyrightText;
  final String? description;
  final bool? discriminate;

  Podcast({
    required this.title,
    required this.artist,
    required this.podId,
    required this.feedUrl,
    required this.artworkUrl,
    required this.reviewsUrl,
    required this.country,
    required this.explicit,
    required this.primaryGenre,
    required this.genres,
    required this.copyrightText,
    required this.description,
    required this.discriminate,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      title: json['title'],
      artist: json['artist'],
      podId: json['pod_id'],
      feedUrl: json['feed_url'],
      artworkUrl: json['artwork_url'],
      reviewsUrl: json['reviews_url'],
      country: json['country'],
      explicit: json['explicit'],
      primaryGenre: json['primary_genre'],
      genres: json['genres'],
      copyrightText: json['copyright_text'],
      description: json['description'],
      discriminate: json['discriminate'],
    );
  }
}
