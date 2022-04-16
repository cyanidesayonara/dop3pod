import 'package:flutter_app/models/PodcastResult.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchService {
  static Future<PodcastResult> searchDjangoApi(String query) async {
    String hostname =
        dotenv.get("FLUTTER_HOSTNAME", fallback: "https://dopepod.net");
    String url = '$hostname/podcasts/?search=' + query;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return PodcastResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load podcasts');
    }
  }
}
