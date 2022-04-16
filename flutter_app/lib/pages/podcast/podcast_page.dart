import 'package:flutter_app/models/Podcast.dart';
import 'package:flutter/material.dart';

class PodcastPage extends StatefulWidget {
  const PodcastPage({Key? key}) : super(key: key);

  @override
  _PodcastPageState createState() => _PodcastPageState();
}

class _PodcastPageState extends State<PodcastPage> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Podcast;

    return Scaffold(
        appBar: AppBar(
          title: Text("dopepod"),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            ListTile(
              title: Text(args.title ?? ''),
              subtitle: Text(args.artworkUrl ?? ''),
            ),
            Center(
              child: ButtonBar(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.link))
                ],
              ),
            ),
          ],
        ));
  }
}