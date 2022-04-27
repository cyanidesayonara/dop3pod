import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/models/Podcast.dart';
import 'package:flutter_app/services/search_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<Podcast> searchResults = [];
  int resultCount = 0;

  searchDjango(String value) async {
    SearchService.searchDjangoApi(value).then((data) {
      setState(() {
        data.results.forEach((result) {
          searchResults.add(result);
        });
        resultCount = data.count;
      });
    }).catchError((e) {
      developer.log(e.toString());
    });
  }

  @override
  void initState() {
    super.initState();
    searchDjango("");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('dopepod', style: GoogleFonts.orbitron()),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(0, 191, 165, 1.0),
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20),
            itemCount: searchResults.length,
            itemBuilder: (BuildContext context, int index) {
              return buildPodcastCard(searchResults[index], context);
            },
          ),
        )
      ),
    );
  }
}

Widget buildPodcastCard(Podcast podcast, BuildContext context) {
  return GridTile(
      header: GridTileBar(
        title: Container(
          child: Text(
            podcast.title ?? '',
            style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.exo().fontFamily,
                color: Colors.black,
                overflow: TextOverflow.fade
            ),
          ),
        )
      ),
      child: Ink.image(
        image: NetworkImage('https://${podcast.artworkUrl}/200x200bb.jpg'),
        fit: BoxFit.contain,
        child: InkWell(
          splashColor: Colors.grey,
          onTap: () {
            Navigator.pushNamed(context, '/podcast',
                arguments: podcast);
          },
        ),
      ),
    footer: GridTileBar(
        title: Container(
          child: Text(
            'By: ${podcast.artist ?? ''}',
            style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.exo().fontFamily,
                color: Colors.black,
                overflow: TextOverflow.fade
            ),
          ),
        )
    ),
  );
}
