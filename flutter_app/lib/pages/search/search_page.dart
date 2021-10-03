import 'package:flutter_app/models/Podcast.dart';
import 'package:flutter_app/services/search_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Podcast> searchResults = [];
  String resultCount = "0";

  searchDjango(String value) async {
    if (value.isNotEmpty) {
      SearchService.searchDjangoApi(value)
        .then((data) {
          setState(() {
            data.results.forEach((result) {
              searchResults.add(result);
            });
            resultCount = data.count.toString();
          });
        })
        .catchError((e) {developer.log(e.toString());});
    } else {
      setState(() {
        searchResults = [];
        resultCount = "0";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("dop3pod"),
          centerTitle: true,
        ),
        body: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                onChanged: (val) {
                  searchResults.clear();
                  searchDjango(val);
                },
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(left: 25.0),
                  hintText: 'Search by Podcast Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
            resultCount == "0"
                ? Padding(
                padding: const EdgeInsets.all(10.0))
                : Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(resultCount + ' results')),
            SizedBox(
              height: 10.0,
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (BuildContext context, int index) {
                return buildPodcastCard(searchResults[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildPodcastCard(Podcast podcast) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: <Widget>[
        ListTile(
          title: Text(podcast.title ?? ''),
          subtitle: Text(podcast.artworkUrl ?? ''),
        ),
        Divider(color: Colors.black)
      ],
    ),
  );
}
