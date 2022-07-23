import 'package:flutter/material.dart';
import 'package:flutter_app/models/Podcast.dart';
import 'package:flutter_app/pages/podcast/podcast_page.dart';
import 'package:flutter_app/pages/search/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'dopepod',
    initialRoute: '/',
    routes: {
      '/': (context) => SearchPage(),
      '/podcast': (context) => PodcastPage(podcast: (ModalRoute.of(context)!.settings.arguments as Podcast)),
    },
  ));
}
