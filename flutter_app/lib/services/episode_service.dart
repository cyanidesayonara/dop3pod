import 'package:flutter_app/models/Episode.dart';
import 'package:flutter_app/models/PodcastResult.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class EpisodeService {
  static Future<List<Episode>> getEpisodes(String id) async {
    final String hostname =
        dotenv.get("FLUTTER_HOSTNAME", fallback: "https://dopepod.net");
    final String url = '$hostname/podcasts/$id/episodes';
    final response = await http.get(Uri.parse(url));
    List<dynamic> episodes = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return episodes.map((episode) => Episode.fromJson(episode)).toList();
    } else {
      throw Exception('Failed to load podcasts');
    }
  }
}
