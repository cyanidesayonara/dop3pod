import 'package:flutter/material.dart';
import 'package:flutter_app/models/Episode.dart';
import 'package:flutter_app/models/Podcast.dart';
import 'package:flutter_app/page_manager.dart';
import 'package:flutter_app/pages/search/search_page.dart';
import 'package:flutter_app/services/episode_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
      throw Exception('Exception ${e.toString()}');
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
        appBar: buildAppBar(context),
        body: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildImageContainer(),
                      buildTitle(),
                      buildArtist(),
                      buildDescription(),
                      buildCopyrightText(),
                      buildEpisodeList(context),
                      buildBottomNavigation(context)
                    ]))));
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SearchPage()));
            },
            child: Text(Constants.TITLE,
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: GoogleFonts.orbitron().fontFamily,
                    fontSize: 24.0))),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(0, 191, 165, 1.0));
  }

  Padding buildTitle() {
    return Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: RichText(
            maxLines: 2,
            text: TextSpan(
                text: widget.podcast.title,
                style: TextStyle(
                    fontFamily: GoogleFonts.exo2().fontFamily,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black))));
  }

  Padding buildArtist() {
    return Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: RichText(
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
                      text: widget.podcast.artist,
                      style: TextStyle(
                          fontFamily: GoogleFonts.exo2().fontFamily,
                          fontSize: 13.0,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.fade))
                ])));
  }

  Padding buildDescription() {
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child:
            Text(widget.podcast.description ?? '', style: GoogleFonts.exo2()));
  }

  Padding buildCopyrightText() {
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(widget.podcast.copyrightText?.substring(1) ?? '',
            style: TextStyle(
                fontFamily: GoogleFonts.exo2().fontFamily,
                fontStyle: FontStyle.italic)));
  }

  ButtonBar buildBottomNavigation(BuildContext context) {
    return ButtonBar(alignment: MainAxisAlignment.start, children: <Widget>[
      GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => SearchPage()));
        },
        child: Icon(Icons.arrow_back),
      ),
      GestureDetector(
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => SearchPage()));
          },
          child: Text('Back', style: GoogleFonts.exo2()))
    ]);
  }

  Theme buildEpisodeList(BuildContext context) {
    return Theme(
        data: Theme.of(context)
            .copyWith(cardColor: Color.fromRGBO(225, 225, 225, 1)),
        child: PaginatedDataTable(
            header: Text('Episode list - $resultCount episodes',
                style: TextStyle(
                    fontFamily: GoogleFonts.exo2().fontFamily,
                    fontWeight: FontWeight.bold)),
            source: DataSource(context, episodes, widget.podcast),
            columnSpacing: 10,
            rowsPerPage: 25,
            headingRowHeight: 25,
            dataRowHeight: 100,
            horizontalMargin: 15,
            columns: [
              DataColumn(label: Text('')),
              DataColumn(
                  label: Text('Title',
                      style: TextStyle(
                          fontFamily: GoogleFonts.exo2().fontFamily,
                          fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Date',
                      style: TextStyle(
                          fontFamily: GoogleFonts.exo2().fontFamily,
                          fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Length',
                      style: TextStyle(
                          fontFamily: GoogleFonts.exo2().fontFamily,
                          fontWeight: FontWeight.bold)))
            ],
            showCheckboxColumn: false,
            showFirstLastButtons: true));
  }

  Container buildImageContainer() {
    return Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(
              fit: BoxFit.contain,
              image: NetworkImage(
                  'https://${widget.podcast.artworkUrl}/600x600bb.jpg')),
        ),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3))
            ]));
  }
}

class DataSource extends DataTableSource {
  DataSource(this.context, this.episodes, this.podcast);

  final pageManager = getIt<PageManager>();
  final List<Episode> episodes;
  final Podcast podcast;
  int selectedCount = 0;
  BuildContext context;

  MaterialStateColor getColor(int index) {
    return MaterialStateColor.resolveWith((states) {
      if (index % 2 == 0) {
        return Color.fromRGBO(0, 191, 165, 0.4);
      }
      return Color.fromRGBO(255, 255, 255, 0.4);
    });
  }

  addToPlaylist(Episode episode) async {
    var playAudio;
    playAudio = () {
      pageManager.play();
      pageManager.currentSongNotifier.removeListener(playAudio);
    };

    await pageManager.add(episode, podcast);

    if (pageManager.playlistNotifier.value.isNotEmpty) {
      pageManager.next();
    }

    pageManager.currentSongNotifier.addListener(playAudio);
  }

  @override
  DataRow getRow(int index) {
    assert(index >= 0);
    assert(index < episodes.length);
    final episode = episodes[index];
    final color = getColor(index);
    final pubDate = DateTime.parse(episode.pubDate ?? '');
    return DataRow.byIndex(
        index: index,
        color: color,
        cells: [
          DataCell(SizedBox(
              child: Text('${index + 1}',
                  style: TextStyle(
                      fontFamily: GoogleFonts.exo2().fontFamily,
                      fontWeight: FontWeight.bold)),
              width: MediaQuery.of(context).size.width * 0.08)),
          DataCell(SizedBox(
              child: Text(episode.title ?? '', maxLines: 5),
              width: MediaQuery.of(context).size.width * 0.43)),
          DataCell(SizedBox(
              child: Text(
                  DateFormat(Constants.DEFAULT_DATE_FORMAT).format(pubDate)),
              width: MediaQuery.of(context).size.width * 0.12)),
          DataCell(SizedBox(
              child: Text(episode.length ?? ''),
              width: MediaQuery.of(context).size.width * 0.14))
        ],
        onSelectChanged: ((value) => addToPlaylist(episode)));
  }

  @override
  int get rowCount => episodes.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => selectedCount;
}
