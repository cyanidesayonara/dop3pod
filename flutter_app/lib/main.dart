import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/Podcast.dart';
import 'package:flutter_app/notifiers/play_button_notifier.dart';
import 'package:flutter_app/notifiers/progress_notifier.dart';
import 'package:flutter_app/notifiers/repeat_button_notifier.dart';
import 'package:flutter_app/page_manager.dart';
import 'package:flutter_app/pages/podcast/podcast_page.dart';
import 'package:flutter_app/pages/search/search_page.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

import 'services/service_locator.dart';

extension StringFormatExtension on String {
  String format(var arguments) => sprintf(this, arguments);
}

Future<void> main() async {
  await dotenv.load(fileName: Constants.DOTENV_FILENAME);
  await setupServiceLocator();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final pageManager = getIt<PageManager>();
  int selectedIndex = 0;
  static const List<Widget> widgetOptions = <Widget>[
    NowPlaying(),
    Playlist(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
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
      title: Constants.TITLE,
      initialRoute: Constants.INITIAL_ROUTE,
      home: SearchPage(),
      builder: (context, child) {
        return Stack(children: [child!, buildAudioPlayerOverlay()]);
      },
    );
  }

  ValueListenableBuilder<MediaItem?> buildAudioPlayerOverlay() {
    return ValueListenableBuilder<MediaItem?>(
        valueListenable: pageManager.currentSongNotifier,
        builder: (_, episode, __) {
          final episode = pageManager.currentSongNotifier.value;
          return episode != null
              ? Positioned(
                  left: 0,
                  bottom: 0,
                  right: 0,
                  child: Column(children: [
                    SizedBox(
                        height: 251,
                        child: DraggableScrollableSheet(
                            maxChildSize: 1,
                            initialChildSize: 1,
                            minChildSize: 0.2,
                            snapSizes: [0.58],
                            snap: true,
                            builder: (BuildContext context,
                                ScrollController scrollController) {
                              return SingleChildScrollView(
                                  controller: scrollController,
                                  child: Column(children: [
                                    Material(
                                        color: Color.fromRGBO(0, 191, 165, 1.0),
                                        child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(Constants.TITLE_SHORT,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontFamily:
                                                      GoogleFonts.orbitron()
                                                          .fontFamily,
                                                  fontSize: 24.0,
                                                )))),
                                    Material(
                                        color: Color.fromRGBO(0, 191, 165, 1.0),
                                        child: widgetOptions
                                            .elementAt(selectedIndex))
                                  ]));
                            })),
                    SizedBox(height: 60, child: buildBottomNavigationOverlay())
                  ]))
              : Positioned(child: Material());
        });
  }

  Overlay buildBottomNavigationOverlay() {
    return Overlay(initialEntries: [
      OverlayEntry(
          builder: (context) => Scaffold(
              backgroundColor: Color.fromRGBO(0, 191, 165, 1.0),
              bottomNavigationBar: BottomNavigationBar(
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedLabelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.exo2().fontFamily),
                  unselectedLabelStyle: TextStyle(
                      fontSize: 12, fontFamily: GoogleFonts.exo2().fontFamily),
                  elevation: 20,
                  type: BottomNavigationBarType.shifting,
                  selectedItemColor: Colors.black,
                  unselectedItemColor: Colors.white,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.play_circle_fill),
                      label: 'Now Playing',
                      backgroundColor: Color.fromRGBO(0, 191, 165, 1.0),
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.list),
                      label: 'Playlist',
                      backgroundColor: Color.fromRGBO(0, 191, 165, 1.0),
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: _onItemTapped)))
    ]);
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
          return episode != null
              ? Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: buildPodcastInfo(episode, context),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: AudioProgressBar(),
                  ),
                  Container(
                    child: AudioControlButtons(),
                  )
                ])
              : Padding(padding: const EdgeInsets.all(0));
        });
  }

  Row buildPodcastInfo(MediaItem episode, BuildContext context) {
    RichText buildPubDate(MediaItem episode) {
      final pubDate = DateTime.parse(episode.extras!['pubDate']);
      return RichText(
          maxLines: 1,
          text: TextSpan(
              text: Constants.RELEASED_TEXT,
              style: TextStyle(
                  fontFamily: GoogleFonts.exo2().fontFamily,
                  fontSize: 12.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.black),
              children: [
                TextSpan(
                    text: DateFormat(Constants.DEFAULT_DATE_FORMAT)
                        .format(pubDate),
                    style: TextStyle(
                        fontFamily: GoogleFonts.exo2().fontFamily,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold))
              ]));
    }

    RichText buildArtist(MediaItem episode) {
      return RichText(
          maxLines: 1,
          text: TextSpan(
              text: Constants.BY_TEXT,
              style: TextStyle(
                  fontFamily: GoogleFonts.exo2().fontFamily,
                  fontSize: 12.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.black),
              children: [
                TextSpan(
                    text: episode.extras!['podcastTitle'],
                    style: TextStyle(
                        fontFamily: GoogleFonts.exo2().fontFamily,
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.clip))
              ]));
    }

    Text buildTitle(MediaItem episode) {
      return Text(episode.title,
          maxLines: 2,
          style: TextStyle(
              fontFamily: GoogleFonts.exo2().fontFamily,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              overflow: TextOverflow.clip));
    }

    Container buildImageContainer(MediaItem episode, BuildContext context) {
      return Container(
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
                          image: NetworkImage(episode.artUri.toString())),
                    ),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(0.4),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: Offset(0, 3))
                        ]))),
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
                                title: episode.extras!['podcastTitle'],
                                artist: episode.extras!['podcastArtist'],
                                artworkUrl: episode.extras!['artworkUrl'],
                                copyrightText:
                                    episode.extras!['podcastCopyrightText'],
                                description:
                                    episode.extras!['podcastDescription']);
                            return PodcastPage(podcast: podcast);
                          }));
                        })))
          ]));
    }

    return Row(children: [
      buildImageContainer(episode, context),
      Expanded(
          flex: 2,
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTitle(episode),
                    buildArtist(episode),
                    buildPubDate(episode),
                  ])))
    ]);
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
                        color: Colors.black);
                  },
                  itemBuilder: (context, index) {
                    final episode = playlistItems[index];
                    return ListTile(
                        horizontalTitleGap: 5,
                        minLeadingWidth: 10,
                        leading: Text('${index + 1}',
                            style: TextStyle(
                                fontFamily: GoogleFonts.exo2().fontFamily,
                                fontWeight: FontWeight.bold)),
                        title: buildEpisodeInfo(episode, context),
                        trailing: IconButton(
                            icon: Icon(Icons.delete_forever),
                            onPressed: () => pageManager.remove(index)));
                  }));
        });
  }

  Row buildEpisodeInfo(MediaItem episode, BuildContext context) {
    RichText buildPubDate(MediaItem episode) {
      final pubDate = DateTime.parse(episode.extras!['pubDate']);
      return RichText(
          maxLines: 1,
          text: TextSpan(
              text: Constants.RELEASED_TEXT,
              style: TextStyle(
                  fontFamily: GoogleFonts.exo2().fontFamily,
                  fontSize: 12.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.black),
              children: [
                TextSpan(
                    text: DateFormat(Constants.DEFAULT_DATE_FORMAT)
                        .format(pubDate),
                    style: TextStyle(
                        fontFamily: GoogleFonts.exo2().fontFamily,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold))
              ]));
    }

    RichText buildArtist(MediaItem episode) {
      return RichText(
          maxLines: 1,
          text: TextSpan(
              text: Constants.BY_TEXT,
              style: TextStyle(
                  fontFamily: GoogleFonts.exo2().fontFamily,
                  fontSize: 12.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.black),
              children: [
                TextSpan(
                    text: episode.extras!['podcastTitle'],
                    style: TextStyle(
                        fontFamily: GoogleFonts.exo2().fontFamily,
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.clip))
              ]));
    }

    Text buildTitle(MediaItem episode) {
      return Text(episode.title,
          maxLines: 2,
          style: TextStyle(
              fontFamily: GoogleFonts.exo2().fontFamily,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.clip));
    }

    Container buildImageContainer(MediaItem episode, BuildContext context) {
      return Container(
          height: 70,
          width: 70,
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
                              image: NetworkImage(episode.artUri.toString())),
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
                            ])))),
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
                                title: episode.extras!['podcastTitle'],
                                artist: episode.extras!['podcastArtist'],
                                artworkUrl: episode.extras!['artworkUrl'],
                                copyrightText:
                                    episode.extras!['podcastCopyrightText'],
                                description:
                                    episode.extras!['podcastDescription']);
                            return PodcastPage(podcast: podcast);
                          }));
                        })))
          ]));
    }

    return Row(children: [
      buildImageContainer(episode, context),
      Flexible(
          child: Container(
              width: double.infinity,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTitle(episode),
                    buildArtist(episode),
                    buildPubDate(episode)
                  ])))
    ]);
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
          return ProgressBar(
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
              timeLabelTextStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.exo2().fontFamily),
              onSeek: pageManager.seek);
        });
  }
}

class AudioControlButtons extends StatelessWidget {
  const AudioControlButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      RepeatButton(),
      PreviousSongButton(),
      PlayButton(),
      NextSongButton(),
      ShuffleButton()
    ]);
  }
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();

    Icon getIcon(RepeatState value) {
      switch (value) {
        case RepeatState.off:
          return Icon(Icons.repeat, color: Colors.grey);
        case RepeatState.repeatSong:
          return Icon(Icons.repeat_one);
        case RepeatState.repeatPlaylist:
          return Icon(Icons.repeat);
      }
    }

    return ValueListenableBuilder<RepeatState>(
        valueListenable: pageManager.repeatButtonNotifier,
        builder: (context, value, child) {
          final Icon icon = getIcon(value);
          return IconButton(icon: icon, onPressed: pageManager.repeat);
        });
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
              onPressed: (isFirst) ? null : pageManager.previous);
        });
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();

    dynamic getIcon(value) {
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
              onPressed: pageManager.pause);
      }
      return null;
    }

    return ValueListenableBuilder<ButtonState>(
        valueListenable: pageManager.playButtonNotifier,
        builder: (_, value, __) => getIcon(value));
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
              onPressed: (isLast) ? null : pageManager.next);
        });
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
              onPressed: pageManager.shuffle);
        });
  }
}
