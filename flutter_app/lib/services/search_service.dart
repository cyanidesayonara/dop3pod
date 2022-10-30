import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/PodcastResult.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchService {
  static Future<PodcastResult> searchBackendApi(String query) async {
    final String hostname = dotenv.get(Constants.ENV_FLUTTER_HOSTNAME,
        fallback: Constants.DEFAULT_URL);
    final String url = Constants.SEARCH_URL.format([hostname, query]);
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return PodcastResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load podcasts from $url');
    }
  }
}
