import 'package:flutter_app/models/PodcastResult.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class SearchService {
  static Future<PodcastResult> searchDjangoApi(String query) async {
    String url = 'https://dop3pod.herokuapp.com/podcasts/?search=' + query;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return PodcastResult.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }
}
