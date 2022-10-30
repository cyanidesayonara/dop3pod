import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_app/models/Podcast.dart';
import 'package:flutter_app/pages/podcast/podcast_page.dart';
import 'package:flutter_app/services/search_service.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<Podcast> searchResults = [];
  int resultCount = 0;
  String previousUrl = '';
  String nextUrl = '';

  searchPodcasts(String value) async {
    SearchService.searchBackendApi(value).then((data) {
      setState(() {
        searchResults.clear();
        data.results.forEach((result) {
          searchResults.add(result);
        });
        resultCount = data.count;
        nextUrl = data.nextUrl;
        previousUrl = data.previousUrl;
      });
    }).catchError((e) {
      developer.log(e.toString());
    });
  }

  @override
  void initState() {
    super.initState();
    searchPodcasts('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(),
        body: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSearchBox(),
                  buildResultCount(),
                  buildPodcastGrid()
                ])));
  }

  Padding buildSearchBox() {
    return Padding(
        padding: const EdgeInsets.only(left: 25, right: 25, top: 10),
        child: TextField(
            style: GoogleFonts.exo2(),
            onChanged: (val) {
              searchPodcasts(val);
            },
            decoration: InputDecoration(
                contentPadding: EdgeInsets.only(left: 20.0),
                hintText: Constants.SEARCH_BOX_HINT,
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
                    onPressed: () {}))));
  }

  Padding buildResultCount() {
    return Padding(
        padding:
            const EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 10),
        child: Text('$resultCount results', style: GoogleFonts.exo2()));
  }

  AppBar buildAppBar() {
    return AppBar(
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        title: Text(Constants.TITLE,
            style: TextStyle(
              color: Colors.black,
              fontFamily: GoogleFonts.orbitron().fontFamily,
              fontSize: 24.0,
            )),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(0, 191, 165, 1.0));
  }

  Expanded buildPodcastGrid() {
    return Expanded(
        child: Row(children: [
      Expanded(
          child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 210,
                  childAspectRatio: 2 / 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10),
              itemCount: searchResults.length,
              itemBuilder: (BuildContext context, int index) {
                return buildPodcastTile(searchResults[index], context);
              }))
    ]));
  }

  Stack buildPodcastTile(Podcast podcast, BuildContext context) {
    return Stack(children: <Widget>[
      Positioned.fill(
          child: Padding(
              padding: EdgeInsets.all(5.0),
              child: GridTile(
                  header: buildImageContainer(podcast),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [buildTitle(podcast), buildArtist(podcast)])))),
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
                  })))
    ]);
  }

  Padding buildArtist(Podcast podcast) {
    return Padding(
        padding: EdgeInsets.only(top: 10),
        child: RichText(
            textAlign: TextAlign.start,
            maxLines: 2,
            text: TextSpan(
                text: Constants.BY_TEXT,
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
                          fontSize: 13.0))
                ])));
  }

  Padding buildTitle(Podcast podcast) {
    return Padding(
        padding: EdgeInsets.only(top: 180),
        child: RichText(
            maxLines: 2,
            textAlign: TextAlign.start,
            text: TextSpan(
                text: podcast.title,
                style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.exo2().fontFamily,
                    color: Colors.black,
                    overflow: TextOverflow.fade))));
  }

  Container buildImageContainer(Podcast podcast) {
    return Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(
              fit: BoxFit.contain,
              image:
                  NetworkImage('https://${podcast.artworkUrl}/200x200bb.jpg')),
        ),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.4),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 3))
            ]));
  }
}
