import 'package:flutter/material.dart';
import 'package:flutter_app/podcastModel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  double fetchCountPercentage = 40;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            backgroundColor: Colors.cyan,
            body: SizedBox.expand(
                child: Stack(
              // ignore: deprecated_member_use
              children: [
                FutureBuilder(
                    future: fetchFromServer(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "${snapshot.error}",
                            style: TextStyle(color: Colors.amberAccent),
                          ),
                        );
                      }

                      if (snapshot.hasData) {
                        return ListView.builder(
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                  child: ListTile(
                                title: Text("Podcast"),
                                subtitle: Text(
                                    "id: ${snapshot.data[index].id} \t price: ${snapshot.data[index].price}"),
                              ));
                            });
                      }

                      return Center(
                          child: Text(
                        "${snapshot.error}",
                        style: TextStyle(color: Colors.amberAccent),
                      ));
                    }),
                Positioned(
                    bottom: 5,
                    right: 5,
                    child: Slider(
                      value: fetchCountPercentage,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      label: fetchCountPercentage.toString(),
                      onChanged: (double value) {
                        setState(() {
                          fetchCountPercentage = value;
                        });
                      },
                    ))
              ],
            ))));
  }

  Future<List<Podcast>> fetchFromServer() async {
    var url = Uri.parse("http://localhost:5500/podcasts");
    var response = await http.get(url);

    List<Podcast> podcastList = [];
    if (response.statusCode == 200) {
      var podcastMap = convert.jsonDecode(response.body);
      for (final item in podcastMap) {
        podcastList.add(Podcast.fromJson(item));
      }
    }

    return podcastList;
  }
}
