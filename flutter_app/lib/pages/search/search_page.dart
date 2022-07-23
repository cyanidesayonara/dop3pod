import 'package:flutter_app/pages/podcast/podcast_page.dart';
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
    searchDjango('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('dopepod', style: GoogleFonts.orbitron()),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(0, 191, 165, 1.0),
      ),
      body: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  style: GoogleFonts.exo(),
                  onChanged: (val) {
                    searchResults.clear();
                    searchDjango(val);
                  },
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(left: 20.0),
                    hintText: 'Search by Podcast Title',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromRGBO(0, 191, 165, 1.0), width: 2.0),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromRGBO(0, 191, 165, 1.0), width: 2.0),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    suffixIcon: IconButton(
                      color: Color.fromRGBO(0, 191, 165, 1.0),
                      icon: Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '$resultCount results',
                    style: GoogleFonts.exo(),
                  )),
              Expanded(
                  child: Row(
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              childAspectRatio: 2 / 3,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15),
                      itemCount: searchResults.length,
                      itemBuilder: (BuildContext context, int index) {
                        return buildPodcastTile(searchResults[index], context);
                      },
                    ),
                  )
                ],
              ))
            ],
          )),
    );
  }
}

Widget buildPodcastTile(Podcast podcast, BuildContext context) {
  return Stack(children: <Widget>[
    Positioned.fill(
        bottom: 0.0,
        child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 5,
                      ),
                    ]),
                child: GridTile(
                    header: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: RichText(
                        maxLines: 2,
                        text: TextSpan(
                          text: podcast.title ?? '',
                          style: TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: GoogleFonts.exo().fontFamily,
                              color: Colors.black,
                              overflow: TextOverflow.fade),
                        ),
                      ),
                    ),
                    child: Image(
                      image: NetworkImage(
                          'https://${podcast.artworkUrl}/200x200bb.jpg'),
                    ),
                    footer: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: RichText(
                          maxLines: 2,
                          text: TextSpan(
                              text: 'By: ',
                              style: TextStyle(
                                  fontFamily: GoogleFonts.exo().fontFamily,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                              children: [
                                TextSpan(
                                  text: podcast.artist ?? '',
                                  style: TextStyle(
                                    fontFamily: GoogleFonts.exo().fontFamily,
                                    fontSize: 10.0,
                                  ),
                                )
                              ])),
                    ))))),
    Positioned.fill(
        child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4.0),
                  splashColor: Colors.grey.withOpacity(0.2),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PodcastPage(podcast: podcast),
                        ));
                  },
                )))),
  ]);
}
