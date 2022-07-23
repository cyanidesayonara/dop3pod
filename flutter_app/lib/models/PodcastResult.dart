import 'package:flutter_app/models/Podcast.dart';

class PodcastResult {
  final int count;
  final String? next;
  final String? previous;
  final List<Podcast> results;

  PodcastResult(
      {required this.count,
      required this.next,
      required this.previous,
      required this.results});

  factory PodcastResult.fromJson(Map<String, dynamic> json) {
    List<dynamic> results = json['results'];
    return PodcastResult(
        count: json['count'],
        next: json['next'],
        previous: json['previous'],
        results: results.map((result) => Podcast.fromJson(result)).toList());
  }
}
