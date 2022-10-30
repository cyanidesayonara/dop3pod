import 'package:flutter_app/models/Podcast.dart';

class PodcastResult {
  final int count;
  final String nextUrl;
  final String previousUrl;
  final List<Podcast> results;

  PodcastResult(
      {required this.count,
      required this.nextUrl,
      required this.previousUrl,
      required this.results});

  factory PodcastResult.fromJson(Map<String, dynamic> json) {
    List<dynamic> results = json['results'];
    return PodcastResult(
        count: json['count'],
        nextUrl: json['next'] ?? '',
        previousUrl: json['previous'] ?? '',
        results: results.map((result) => Podcast.fromJson(result)).toList());
  }
}
