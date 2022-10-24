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
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        title: Text('dopepod',
            style: TextStyle(
              color: Colors.black,
              fontFamily: GoogleFonts.orbitron().fontFamily,
              fontSize: 24.0,
            )),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(0, 191, 165, 1.0),
      ),
      body: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 10),
                child: TextField(
                  style: GoogleFonts.exo2(),
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
                  padding: const EdgeInsets.only(
                      left: 25, right: 25, top: 10, bottom: 10),
                  child: Text(
                    '$resultCount results',
                    style: GoogleFonts.exo2(),
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
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10),
                      itemCount: searchResults.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (index % 2 != 0) {}
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
        child: Padding(
            padding: EdgeInsets.all(5.0),
            child: GridTile(
                header: Container(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image(
                        fit: BoxFit.contain,
                        image: NetworkImage(
                            'https://${podcast.artworkUrl}/200x200bb.jpg')),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4),
                        spreadRadius: 3,
                        blurRadius: 5,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 190),
                  child: RichText(
                    maxLines: 2,
                    text: TextSpan(
                      text: podcast.title,
                      style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.exo2().fontFamily,
                          color: Colors.black,
                          overflow: TextOverflow.fade),
                    ),
                  ),
                ),
                footer: RichText(
                    maxLines: 2,
                    text: TextSpan(
                        text: 'By: ',
                        style: TextStyle(
                            fontFamily: GoogleFonts.exo2().fontFamily,
                            fontSize: 12.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.black),
                        children: [
                          TextSpan(
                            text: podcast.artist ?? '',
                            style: TextStyle(
                              fontFamily: GoogleFonts.exo2().fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          )
                        ]))))),
    Positioned.fill(
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.grey.withOpacity(0.2),
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PodcastPage(podcast: podcast),
                    ));
              },
            ))),
  ]);
}
