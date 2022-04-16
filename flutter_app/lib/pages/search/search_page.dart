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
        title: Text("dopepod"),
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
          resultCount.toString() == "0"
              ? Padding(padding: const EdgeInsets.all(10.0))
              : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text('$resultCount results')),
          SizedBox(
            height: 10.0,
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: searchResults.length,
            itemBuilder: (BuildContext context, int index) {
              return buildPodcastCard(searchResults[index], context);
            },
          ),
        ],
      ),
    );
  }
}

Widget buildPodcastCard(Podcast podcast, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: <Widget>[
        ListTile(
          title: Text(podcast.title ?? ''),
          subtitle: Text(podcast.artworkUrl ?? ''),
        ),
        Center(
          child: ButtonBar(
            children: [
              IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/podcast',
                        arguments: podcast);
                  },
                  icon: Icon(Icons.link))
            ],
          ),
        ),
        Divider(color: Colors.black)
      ],
    ),
  );
}
