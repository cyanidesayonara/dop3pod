import 'package:flutter_app/models/Episode.dart';
import 'package:flutter_app/services/episode_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/models/Podcast.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:developer' as developer;

class PodcastPage extends StatefulWidget {
  final Podcast podcast;

  const PodcastPage({Key? key, required this.podcast}) : super(key: key);

  @override
  _PodcastPageState createState() => _PodcastPageState();
}

class _PodcastPageState extends State<PodcastPage> {
  final List<Episode> episodes = [];
  int resultCount = 0;

  getEpisodes(String id) async {
    EpisodeService.getEpisodes(id).then((data) {
      setState(() {
        data.forEach((result) {
          episodes.add(result);
        });
        resultCount = episodes.length;
      });
    }).catchError((e) {
      developer.log(e.toString());
    });
  }

  @override
  void initState() {
    super.initState();
    getEpisodes(widget.podcast.id.toString());
  }

  @override
  Widget build(BuildContext context) {
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
                            text: widget.podcast.title ?? '',
                            style: TextStyle(
                                fontFamily: GoogleFonts.exo().fontFamily,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        )),
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
                                  color: Colors.black),
                              children: [
                                TextSpan(
                                  text: widget.podcast.artist ?? '',
                                  style: TextStyle(
                                      fontFamily: GoogleFonts.exo().fontFamily,
                                      fontSize: 12.0,
                                      decoration: TextDecoration.underline,
                                      overflow: TextOverflow.fade),
                                )
                              ])),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        widget.podcast.description ?? '',
                        style: GoogleFonts.exo(),
                      ),
                    ),
                    Image(
                        fit: BoxFit.contain,
                        image: NetworkImage(
                            'https://${widget.podcast.artworkUrl}/600x600bb.jpg')),
                    Padding(padding: const EdgeInsets.all(8.0), child: null),
                    PaginatedDataTable(
                      header: Text(
                        '$resultCount episodes',
                        style: GoogleFonts.exo(),
                      ),
                      source: DataSource(context, episodes),
                      columnSpacing: 10.0,
                      rowsPerPage: 25,
                      headingRowHeight: 35,
                      dataRowHeight: 100,
                      horizontalMargin: 15,
                      columns: [
                        DataColumn(label: Text('')),
                        DataColumn(
                            label: Text('Title', style: GoogleFonts.exo())),
                        DataColumn(
                            label: Text('Length', style: GoogleFonts.exo())),
                      ],
                      showCheckboxColumn: false,
                      showFirstLastButtons: true,
                    ),
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
                ))));
  }
}

class DataSource extends DataTableSource {
  DataSource(this.context, this.episodes);

  final AudioPlayer audioPlayer = AudioPlayer();
  final List<Episode> episodes;
  BuildContext context;

  playAudio(String url) async {
    await audioPlayer.stop();
    await audioPlayer.setUrl(url);
    await audioPlayer.play();
  }

  int selectedCount = 0;
  @override
  DataRow getRow(int index) {
    assert(index >= 0);
    assert(index < episodes.length);
    final episode = episodes[index];
    return DataRow.byIndex(
        index: index,
        cells: [
          DataCell(SizedBox(
              child: Text((index + 1).toString()),
              width: MediaQuery.of(context).size.width * 0.08)),
          DataCell(SizedBox(
              child: Text(episode.title ?? '', maxLines: 5),
              width: MediaQuery.of(context).size.width * 0.55)),
          DataCell(SizedBox(
              child: Text(episode.length ?? ''),
              width: MediaQuery.of(context).size.width * 0.14)),
        ],
        onSelectChanged: ((value) => playAudio(episode.url ?? '')));
  }

  @override
  int get rowCount => episodes.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => selectedCount;
}
