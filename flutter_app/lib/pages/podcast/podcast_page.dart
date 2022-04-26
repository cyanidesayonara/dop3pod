import 'package:google_fonts/google_fonts.dart';
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
    final Podcast podcast =
        ModalRoute.of(context)!.settings.arguments as Podcast;

    return Scaffold(
        appBar: AppBar(
          title: Text('dopepod', style: GoogleFonts.orbitron()),
          centerTitle: true,
          backgroundColor: Color.fromRGBO(0, 191, 165, 1.0),
        ),
        body: Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView(
              children: <Widget>[
                ListTile(
                  title: Text(
                    podcast.title ?? '',
                    style: GoogleFonts.exo(),
                  ),
                  subtitle: Text(
                    podcast.description ?? '',
                    style: GoogleFonts.exo(),
                  ),
                ),
                Image(
                    image: NetworkImage(
                        'https://${podcast.artworkUrl}/600x600bb.jpg')),
                Center(
                  child: ButtonBar(
                    alignment: MainAxisAlignment.start,
                    children: <Widget>[
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back)),
                      Text('Back', style: GoogleFonts.exo())
                    ],
                  ),
                ),
              ],
            )));
  }
}
