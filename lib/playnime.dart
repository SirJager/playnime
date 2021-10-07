import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:ansicolor/ansicolor.dart';

AnsiPen red = new AnsiPen()..red(bold: true);
AnsiPen green = new AnsiPen()..green(bold: true);
AnsiPen yellow = new AnsiPen()..yellow(bold: true);
AnsiPen blue = new AnsiPen()..blue(bold: true);
AnsiPen magenta = new AnsiPen()..magenta(bold: true);
AnsiPen cyan = new AnsiPen()..cyan(bold: true);

Future<String?> makeRequest(String url, String useragent, error) async {
  //! #1
  final uri = Uri.parse(url);
  try {
    final response = await http.get(uri, headers: {'User-Agent': useragent});
    if (response.statusCode == 200)
      return response.body;
    else
      print(red("NEGATIVE RESPONSE\nRESPONSE CODE : ${response.statusCode}"));
  } catch (e) {
    print(red(error));
  }
}

Future<List<Anime>> getAnimes(dom.Document doc, {String? search}) async {
  //! #2
  final all = doc.getElementsByClassName("img");
  List<Anime> animelist = [];
  for (int i = 0; i < all.length; i++) {
    final ani = all[i];
    final animeUrl = ani.innerHtml.split("href=\"").last.split("\"").first;
    final animeID = animeUrl.split("/").last;
    final animename = ani.innerHtml.split("title=\"").last.split("\"").first;
    final imageUrl = ani.innerHtml.split("img src=\"").last.split("\"").first;

    final released = doc
        .getElementsByClassName("released")[i]
        .text
        .replaceAll(" ", "")
        .replaceAll("\n", "")
        .replaceAll("Released:", "");
    final Anime anime = Anime(
      animeID: animeID,
      animename: animename,
      animeUrl: animeUrl,
      imageUrl: imageUrl,
      released: released,
    );
    animelist.add(anime);
  }
  return animelist;
}

Future<Anime?> showAndGetChoice(List<Anime> animelist) async {
  //! #3
  if (animelist.length == 0) {
    print(magenta("=========[ ${animelist.length} Anime Found ]========="));
  } else {
    print(green("=========[ ${animelist.length} Anime Found ]=========\n"));
    print(yellow("[ NO ] : ANIME NAME : RELEASED\n"));
    for (int a = 0; a < animelist.length; a++) {
      bool isOdd = a % 2 == 0;
      String index = a.toString().padLeft(2, " ");
      final anime = animelist[a];
      if (isOdd) {
        print(blue("[ $index ] ::  ${anime.animename}  :: ${anime.released} "));
      } else {
        print(magenta(
            "[ $index ] ::  ${anime.animename}  :: ${anime.released} "));
      }
    }
    print(red("\nPRESS Q TO EXIT\n"));
    print(yellow("SELECT ANIME BY NO "));
    final choice = await getChoice(min: 0, max: animelist.length - 1);
    if (choice != null) {
      return animelist[choice];
    } else {
      print(red("NO VALID CHOICE RECEIVED\nEXITING"));
    }
  }
}

Future<int?> getChoice({
  int trycount = 0,
  required int min,
  required int max,
  bool canbenull = false,
}) async {
  //! #3 II
  if (trycount < 3) {
    while (trycount < 3) {
      var choice = stdin.readLineSync();
      if (canbenull) {
        if (choice == null)
          return null;
        else {
          if (choice == "q" || choice == "Q") {
            exit(0);
          } else {
            int? no = int.tryParse(choice);
            if (no != null && no >= min && no <= max) {
              return no;
            } else {
              print(magenta("\nENTER A VALID NO FROM $min TO $max\n"));
              trycount++;
              return getChoice(trycount: trycount, min: min, max: max);
            }
          }
        }
      } else {
        if (choice != null) {
          if (choice == "q" || choice == "Q") {
            exit(0);
          } else {
            int? no = int.tryParse(choice);
            if (no != null && no >= min && no <= max) {
              return no;
            } else {
              print(magenta("\nENTER A VALID NO FROM $min TO $max\n"));
              trycount++;
              return getChoice(trycount: trycount, min: min, max: max);
            }
          }
        }
      }
    }
  } else {
    print(red("\nTOO MANY INVALID INPUTS\n"));
  }
}

Future<String?> getEpisodeChoice(dom.Document doc2) async {
  //! #4
  final episodeElement = doc2.getElementById("episode_page");
  if (episodeElement != null) {
    final html = episodeElement.innerHtml;
    final firstAndLast = getFirstAndLastEpisodes(html);
    if (firstAndLast.last != 0) {
      print(magenta("\n${firstAndLast[1]} EPISODES FOUND"));
      print(yellow("\nENTER EPISODE NO"));
      final choice = await getChoice(min: 1, max: firstAndLast[1]);
      if (choice != null) {
        return choice.toString();
      } else {
        print(red("NO VALID CHOICE RECEIVED\nEXITING"));
      }
    } else {
      print(red("NO EPISODES FOUND"));
    }
  } else {
    print(red("NO EPISODES FOUND"));
    return null;
  }
}

List<int> getFirstAndLastEpisodes(source) {
  //! #5
  RegExp reg = new RegExp("ep_start=\"([0-9]+)\".ep_end=\"([0-9]+)");
  final matches = reg.allMatches(source);
  List<int> list = [];
  for (var match in matches) {
    var value = match.group(1);
    var value2 = match.group(2);
    if (value != null) {
      list.add(int.parse(value));
    } else {}
    if (value2 != null) {
      list.add(int.parse(value2));
    } else {}
  }
  int first = list.reduce(min);
  int last = list.reduce(max);
  return [first, last];
}

Future<String?> getEpisodeRes(
    Anime choiceAnime, String episodeChoice, String useragent) async {
  //! #6
  final url =
      Private.site + "/" + choiceAnime.animeID + "-episode-" + episodeChoice;
  final episodeRes =
      await makeRequest(url, useragent, "ERROR WHILE GETTING EPISODE");
  if (episodeRes != null) {
    final dom.Document doc3 = parse(episodeRes);
    final down = doc3.getElementsByClassName("favorites_book").first;
    final downloadUrl = down.innerHtml.split("href=\"").last.split("\"").first;
    final downRes = await makeRequest(
        downloadUrl, useragent, "ERROR WHILE FETCHING VIDEO LINKS");
    if (downRes != null) {
      return downRes;
    }
  } else
    exit(0);
}

Future<Episode> getEpisodeLinks(dom.Document doc3, String useragent) async {
  //! #7
  final downs = doc3.getElementsByClassName("dowload");
  List<Video> videos = [];
  for (var lenk in downs) {
    bool crap = lenk.innerHtml.contains("target");
    if (!crap) {
      final url = lenk.innerHtml.split("href=\"").last.split("\"").first;
      final quality = lenk.text
          .split("(")
          .last
          .split(")")
          .first
          .split("-")
          .first
          .replaceAll(" ", "");
      final vid = Video(url: url, quality: quality);
      videos.add(vid);
    }
  }
  return Episode(videos: videos);
}

Future<bool> asQualityAndPlay(
    Anime choiceAnime, String episodeChoice, Episode episode) async {
  //! #8
  print(yellow("\nCHOOSE QUALITY\n"));
  for (int i = 0; i < episode.videos.length; i++) {
    print(green("[ ${i} ] : ${episode.videos[i].quality}"));
  }
  var quality =
      await getChoice(min: 0, max: episode.videos.length - 1, canbenull: true);
  return await tryPlay(episode.videos, choiceAnime, episodeChoice,
      episode.videos[quality ?? 0].quality);
}

Future<bool> tryPlay(List<Video> videos, Anime choiceAnime, String episodeNo,
    String? qualitychoice,
    {String? choice}) async {
  //! #9
  List<String> faillist = [];
  bool value = false;
  for (var vid in videos) {
    if (faillist.contains(vid.url) == false) {
      print(green("\n========[ PLAYING ]========\n"));
      print(magenta("Anime : " + choiceAnime.animename));
      print(magenta("Episode : " + episodeNo));
      print(magenta("Quality : " + qualitychoice.toString()));
      var output =
          await Process.run("mpv", [vid.url]).then((result) => result.exitCode);
      if (output == 2) {
        faillist.add(vid.url);
        print(red("FAILED FOR ${qualitychoice.toString()}"));
        print(cyan("TRYING ANOTHER QUALTIY"));
      } else if (output == 0) {
        value = true;
        return true;
      } else {
        return value;
      }
    }
  }
  return value;
}

// Future userDecision() async {
//   print(yellow("\nWHAT DO YOU WANT TO DO NOW ?\n"));
//   print(green("[ 0 ] : CHANGE EPISODE"));
//   print(red("[ 1 ] : CHANGE ANIME"));
//   print(red("[ 2 ] : EXIT"));
//   var choice = await getChoice(min: 0, max: 2);
//   if (choice == 0) {
//     // await getEpisode();
//   } else if (choice == 1) {
//     // await getAnime();
//   } else if (choice == 2) {
//     exit(0);
//   } else {
//     print(red("\nINVALID CHOICE\nEXITING"));
//     exit(0);
//   }
// }

class Private {
  static final String search = "https://gogoanime.vc/search.html?keyword=";
  static final String site = "https://gogoanime.vc";
}

class Choice {
  final int no;
  final String name;
  Choice({required this.no, required this.name});
}

class Episode {
  List<Video> videos;
  Episode({required this.videos});
}

class Anime {
  final String animeID;
  final String animename;
  final String animeUrl;
  final String imageUrl;
  final String released;

  Anime({
    required this.animeID,
    required this.animename,
    required this.animeUrl,
    required this.imageUrl,
    required this.released,
  });
}

class Video {
  String url;
  String quality;
  Video({required this.url, required this.quality});
}
