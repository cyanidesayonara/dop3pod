import 'dart:developer' as developer;

class Podcast {
  final String? title;
  final String? feedUrl;
  final String? artworkUrl;

  Podcast({
    required this.title,
    required this.feedUrl,
    required this.artworkUrl,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      title: json['title'],
      feedUrl: json['feed_url'],
      artworkUrl: json['artwork_url'],
    );
  }
}