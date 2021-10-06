import 'dart:io';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:faker/faker.dart';
import 'package:playnime/playnime.dart';

void main() async {
  //!hello
  var faker = Faker();
  final useragent = faker.internet.userAgent();
  print(yellow("Enter Anime Name :"));
  var animeName = stdin.readLineSync();
  if (animeName != null) {
    //? FETCHING SEARCH RESULT PAGE DATA : IF ANIME NAME IS NOT NULL
    final url = (Private.search + animeName);
    final res =
        await makeRequest(url, useragent, "COULD NOT FETCH ANIME RESULTS");
    if (res != null) {
      //? EXTRACTING ANIME LIST : IF SEARCH RESULTS IS NOT NULL
      dom.Document doc = parser.parse(res);
      final animelist = await getAnimes(doc);
      final choiceAnime = await showAndGetChoice(animelist);
      if (choiceAnime != null) {
        final episodesRes = await makeRequest(
            Private.site + choiceAnime.animeUrl,
            useragent,
            "ERROR WHILE GETTING EPISODES");
        if (episodesRes != null) {
          dom.Document doc2 = parser.parse(episodesRes);
          final episodeChoice = await getEpisodeChoice(doc2);
          if (episodeChoice != null) {
            print(green("EPISODE CHOICE is $episodeChoice"));
            final episodesData =
                await getEpisodeRes(choiceAnime, episodeChoice, useragent);
            dom.Document doc3 = parser.parse(episodesData);
            final episode = await getEpisodeLinks(doc3, useragent);
            await asQualityAndPlay(choiceAnime, episodeChoice, episode);
          }
        }
      }
    }
  }
}
