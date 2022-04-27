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
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: RichText(
                        maxLines: 2,
                        text: TextSpan(
                          text: podcast.title ?? '',
                          style: TextStyle(
                              fontFamily: GoogleFonts.exo().fontFamily,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black
                          ),
                        ),
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: RichText(
                        maxLines: 2,
                        text: TextSpan(
                          text: 'By: ',
                          style: TextStyle(
                            fontFamily: GoogleFonts.exo().fontFamily,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black
                          ),
                          children: [
                            TextSpan(
                              text: podcast.artist ?? '',
                              style: TextStyle(
                                fontFamily: GoogleFonts.exo().fontFamily,
                                fontSize: 12.0,
                                decoration: TextDecoration.underline,
                                overflow: TextOverflow.fade
                              ),
                            )
                          ]
                        )
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        podcast.description ?? '',
                        style: GoogleFonts.exo(),
                      ),
                    ),
                    Image(
                      fit: BoxFit.contain,
                      image: NetworkImage(
                          'https://${podcast.artworkUrl}/600x600bb.jpg')),
                    ButtonBar(
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
                  ],
              )
          )
        )
    );
  }
}
