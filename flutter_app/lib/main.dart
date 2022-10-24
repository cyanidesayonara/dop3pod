import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/models/Podcast.dart';
import 'package:flutter_app/notifiers/play_button_notifier.dart';
import 'package:flutter_app/notifiers/progress_notifier.dart';
import 'package:flutter_app/notifiers/repeat_button_notifier.dart';
import 'package:flutter_app/page_manager.dart';
import 'package:flutter_app/pages/podcast/podcast_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/search/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  await setupServiceLocator();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final pageManager = getIt<PageManager>();
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    NowPlaying(),
    Playlist(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    getIt<PageManager>().init();
  }

  @override
  void dispose() {
    getIt<PageManager>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'dopepod',
      initialRoute: '/',
      home: SearchPage(),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            ValueListenableBuilder<MediaItem?>(
                valueListenable: pageManager.currentSongNotifier,
                builder: (_, episode, __) {
                  final episode = pageManager.currentSongNotifier.value;
                  return episode != null
                      ? Positioned(
                          left: 0,
                          bottom: 0,
                          right: 0,
                          child: Material(
                              color: Color.fromRGBO(0, 191, 165, 1.0),
                              child: Column(
                                children: [
                                  Center(
                                    child: _widgetOptions
                                        .elementAt(_selectedIndex),
                                  ),
                                  SizedBox(
                                    height: 60,
                                    child: Overlay(
                                      initialEntries: [
                                        OverlayEntry(
                                            builder: (context) => Scaffold(
                                                  backgroundColor:
                                                      Color.fromRGBO(
                                                          0, 191, 165, 1.0),
                                                  bottomNavigationBar:
                                                      BottomNavigationBar(
                                                    showSelectedLabels: true,
                                                    showUnselectedLabels: true,
                                                    selectedLabelStyle:
                                                        TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                GoogleFonts
                                                                        .exo2()
                                                                    .fontFamily),
                                                    unselectedLabelStyle:
                                                        TextStyle(
                                                            fontSize: 12,
                                                            fontFamily:
                                                                GoogleFonts
                                                                        .exo2()
                                                                    .fontFamily),
                                                    elevation: 20,
                                                    type:
                                                        BottomNavigationBarType
                                                            .shifting,
                                                    selectedItemColor:
                                                        Colors.black,
                                                    unselectedItemColor:
                                                        Colors.white,
                                                    items: const <
                                                        BottomNavigationBarItem>[
                                                      BottomNavigationBarItem(
                                                        icon: Icon(Icons
                                                            .play_circle_fill),
                                                        label: 'Now Playing',
                                                        backgroundColor:
                                                            Color.fromRGBO(0,
                                                                191, 165, 1.0),
                                                      ),
                                                      BottomNavigationBarItem(
                                                        icon: Icon(Icons.list),
                                                        label: 'Playlist',
                                                        backgroundColor:
                                                            Color.fromRGBO(0,
                                                                191, 165, 1.0),
                                                      ),
                                                    ],
                                                    currentIndex:
                                                        _selectedIndex,
                                                    onTap: _onItemTapped,
                                                  ),
                                                )),
                                      ],
                                    ),
                                  ),
                                ],
                              )))
                      : Positioned(child: Material());
                })
          ],
        );
      },
    );
  }
}

class NowPlaying extends StatelessWidget {
  const NowPlaying({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<MediaItem?>(
      valueListenable: pageManager.currentSongNotifier,
      builder: (_, episode, __) {
        final episode = pageManager.currentSongNotifier.value;
        final df = DateFormat('dd MMM yyyy');
        final pubDate =
            df.format(DateTime.parse(episode?.extras!['pubDate'] ?? ''));
        return episode != null
            ? Column(children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        child: Stack(children: <Widget>[
                          Positioned.fill(
                              bottom: 0,
                              child: Container(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image(
                                      fit: BoxFit.contain,
                                      image: NetworkImage(
                                          episode.artUri.toString())),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.4),
                                      spreadRadius: 3,
                                      blurRadius: 5,
                                      offset: Offset(
                                          0, 3), // changes position of shadow
                                    ),
                                  ],
                                ),
                              )),
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
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                        final podcast = Podcast(
                                            id: episode.extras!['podcastId'],
                                            title:
                                                episode.extras!['podcastTitle'],
                                            artist: episode
                                                .extras!['podcastArtist'],
                                            artworkUrl:
                                                episode.extras!['artworkUrl'],
                                            copyrightText: episode.extras![
                                                'podcastCopyrightText'],
                                            description: episode
                                                .extras!['podcastDescription']);
                                        return PodcastPage(podcast: podcast);
                                      }));
                                    },
                                  ))),
                        ]),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(episode.title,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontFamily:
                                              GoogleFonts.exo2().fontFamily,
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          overflow: TextOverflow.clip)),
                                  RichText(
                                      maxLines: 1,
                                      text: TextSpan(
                                          text: 'By: ',
                                          style: TextStyle(
                                              fontFamily:
                                                  GoogleFonts.exo2().fontFamily,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black),
                                          children: [
                                            TextSpan(
                                              text: episode.artist,
                                              style: TextStyle(
                                                  fontFamily: GoogleFonts.exo2()
                                                      .fontFamily,
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.bold,
                                                  overflow: TextOverflow.clip),
                                            )
                                          ])),
                                  RichText(
                                      maxLines: 1,
                                      text: TextSpan(
                                          text: 'Released: ',
                                          style: TextStyle(
                                              fontFamily:
                                                  GoogleFonts.exo2().fontFamily,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black),
                                          children: [
                                            TextSpan(
                                              text: pubDate,
                                              style: TextStyle(
                                                  fontFamily: GoogleFonts.exo2()
                                                      .fontFamily,
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.bold),
                                            )
                                          ])),
                                ])),
                      )
                    ],
                  ),
                ),
                Container(
                  child: AudioProgressBar(),
                ),
                Container(
                  child: AudioControlButtons(),
                ),
              ])
            : Padding(padding: const EdgeInsets.all(0));
      },
    );
  }
}

class Playlist extends StatelessWidget {
  const Playlist({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<List<MediaItem>>(
      valueListenable: pageManager.playlistNotifier,
      builder: (context, playlistItems, _) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 400.0,
          ),
          child: ListView.separated(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: playlistItems.length,
            padding: const EdgeInsets.all(0),
            separatorBuilder: (BuildContext context, int index) {
              return Container(
                height: 1,
                width: MediaQuery.of(context).size.width,
                child: Divider(),
                color: Colors.black,
              );
            },
            itemBuilder: (context, index) {
              final item = playlistItems[index];
              return ListTile(
                  horizontalTitleGap: 5,
                  minLeadingWidth: 10,
                  leading: Text('${index + 1}',
                      style: TextStyle(
                          fontFamily: GoogleFonts.exo2().fontFamily,
                          fontWeight: FontWeight.bold)),
                  title: Row(
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        child: Stack(children: <Widget>[
                          Positioned.fill(
                              bottom: 0,
                              child: Padding(
                                  padding: EdgeInsets.all(5.0),
                                  child: Container(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image(
                                          fit: BoxFit.contain,
                                          image: NetworkImage(
                                              item.artUri.toString())),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.4),
                                          spreadRadius: 3,
                                          blurRadius: 5,
                                          offset: Offset(0,
                                              3), // changes position of shadow
                                        ),
                                      ],
                                    ),
                                  ))),
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
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                        final podcast = Podcast(
                                            id: item.extras!['podcastId'],
                                            title: item.extras!['podcastTitle'],
                                            artist:
                                                item.extras!['podcastArtist'],
                                            artworkUrl:
                                                item.extras!['artworkUrl'],
                                            copyrightText: item.extras![
                                                'podcastCopyrightText'],
                                            description: item
                                                .extras!['podcastDescription']);
                                        return PodcastPage(podcast: podcast);
                                      }));
                                    },
                                  ))),
                        ]),
                      ),
                      Flexible(
                          child: Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                maxLines: 2,
                                style: TextStyle(
                                    fontFamily: GoogleFonts.exo2().fontFamily,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.clip)),
                            RichText(
                                maxLines: 1,
                                text: TextSpan(
                                    text: 'By: ',
                                    style: TextStyle(
                                        fontFamily:
                                            GoogleFonts.exo2().fontFamily,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: item.artist,
                                        style: TextStyle(
                                            fontFamily:
                                                GoogleFonts.exo2().fontFamily,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                            overflow: TextOverflow.clip),
                                      )
                                    ])),
                          ],
                        ),
                      ))
                    ],
                  ),
                  trailing: IconButton(
                      icon: Icon(Icons.delete_forever),
                      onPressed: () => pageManager.remove(index)));
            },
          ),
        );
      },
    );
  }
}

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: pageManager.progressNotifier,
      builder: (_, value, __) {
        return Padding(
            padding: const EdgeInsets.all(10),
            child: ProgressBar(
              thumbCanPaintOutsideBar: true,
              thumbRadius: 10,
              thumbGlowRadius: 12,
              thumbGlowColor: Colors.black,
              thumbColor: Colors.black,
              progressBarColor: Colors.black,
              baseBarColor: Colors.white,
              bufferedBarColor: Colors.grey,
              progress: value.current,
              buffered: value.buffered,
              total: value.total,
              onSeek: pageManager.seek,
            ));
      },
    );
  }
}

class AudioControlButtons extends StatelessWidget {
  const AudioControlButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        RepeatButton(),
        PreviousSongButton(),
        PlayButton(),
        NextSongButton(),
        ShuffleButton(),
      ],
    );
  }
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<RepeatState>(
      valueListenable: pageManager.repeatButtonNotifier,
      builder: (context, value, child) {
        Icon icon;
        switch (value) {
          case RepeatState.off:
            icon = Icon(Icons.repeat, color: Colors.grey);
            break;
          case RepeatState.repeatSong:
            icon = Icon(Icons.repeat_one);
            break;
          case RepeatState.repeatPlaylist:
            icon = Icon(Icons.repeat);
            break;
        }
        return IconButton(
          icon: icon,
          onPressed: pageManager.repeat,
        );
      },
    );
  }
}

class PreviousSongButton extends StatelessWidget {
  const PreviousSongButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isFirstSongNotifier,
      builder: (_, isFirst, __) {
        return IconButton(
          icon: Icon(Icons.skip_previous),
          onPressed: (isFirst) ? null : pageManager.previous,
        );
      },
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return Container(
              margin: EdgeInsets.all(8.0),
              width: 32.0,
              height: 32.0,
              child: CircularProgressIndicator(),
            );
          case ButtonState.paused:
            return IconButton(
              icon: Icon(Icons.play_arrow),
              iconSize: 32.0,
              onPressed: pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: Icon(Icons.pause),
              iconSize: 32.0,
              onPressed: pageManager.pause,
            );
        }
      },
    );
  }
}

class NextSongButton extends StatelessWidget {
  const NextSongButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isLastSongNotifier,
      builder: (_, isLast, __) {
        return IconButton(
          icon: Icon(Icons.skip_next),
          onPressed: (isLast) ? null : pageManager.next,
        );
      },
    );
  }
}

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isShuffleModeEnabledNotifier,
      builder: (context, isEnabled, child) {
        return IconButton(
          icon: (isEnabled)
              ? Icon(Icons.shuffle)
              : Icon(Icons.shuffle, color: Colors.grey),
          onPressed: pageManager.shuffle,
        );
      },
    );
  }
}
