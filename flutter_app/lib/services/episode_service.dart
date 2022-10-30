import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/Episode.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EpisodeService {
  static Future<List<Episode>> getEpisodes(String id) async {
    final String hostname = dotenv.get(Constants.ENV_FLUTTER_HOSTNAME,
        fallback: Constants.DEFAULT_URL);
    final String url = Constants.EPISODE_URL.format([hostname, id]);
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> episodes = jsonDecode(response.body);
      return episodes.map((episode) => Episode.fromJson(episode)).toList();
    } else {
      throw Exception('Failed to load episodes from $url');
    }
  }
}
