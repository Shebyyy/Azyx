import 'dart:developer';
import 'package:azyx/Screens/Anime/episode_src.dart';
import 'package:azyx/utils/helper/jaro_winkler.dart';
import 'package:azyx/utils/scraper/Anime/extractors/vidstream.dart';
import 'package:azyx/utils/sources/Anime/Base/base_class.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class GogoAnime implements EXtractAnimes {
  final String _baseUrl = "https://ww5.gogoanimes.fi";
  final String _ajaxUrl = "https://ajax.gogocdn.net/ajax";

  @override
  String get url => "https://ww5.gogoanimes.fi";
  @override
  Future<List<Map<String, String?>>> scrapeAnimeSearch(String query) async {
    final searchUrl =
        "$_baseUrl/search.html?keyword=${Uri.encodeComponent(query)}";
    final response = await _httpGet(searchUrl);
    final document = html.parse(response.body);

    final titles = document.querySelectorAll(".items p.name");
    final images = document.querySelectorAll(".img");
    if (titles.isEmpty) throw Exception("NO_SEARCH_RESULTS");

    List<Map<String, String?>> results = [];
    for (int i = 0; i < titles.length; i++) {
      final title = titles[i].text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final link = titles[i].children.first.attributes['href'];
      final imageUrl =
          images[i].children.first.children.first.attributes['src'];

      if (link != null && imageUrl != null) {
        results.add({
          'name': title,
          'id': '$_baseUrl$link',
          'poster':
              imageUrl.startsWith("https://") ? imageUrl : '$_baseUrl$imageUrl',
        });
      }
    }
    return results;
  }

  @override
  Future<Map<String, dynamic>> scrapeEpisodesSrc(String episodeUrl,String category, String serverName,
      {AnimeServers? server}) async {
    final serverLinks = await _getAllServerLinks(episodeUrl);
    final vidstreamLink = _getServerUrl("vidstreaming", serverLinks);
    // final streamwishLink = _getServerUrl("streamwish", serverLinks);
    // final vidhideLink = _getServerUrl("vidhide", serverLinks);

    // Initialize the mapped data
    final Map<String, dynamic> mappedData = {
      "sources": [],
      "tracks": [],
      "download": "",
    };

    try {
      final result = await Vidstream().extract(vidstreamLink);
      if (result != null && result.isNotEmpty) {
        mappedData["sources"].add({"url": result[0]['link']});
        log('Mapped Data: ${mappedData['sources'][0]['url']}');
      }
    } catch (error) {
      log('Error extracting stream: $error');
      return {};
    }

    return mappedData;
  }

  @override
  Future<Map<String,dynamic>> scrapeAnimeEpisodes(String aliasId, {dynamic args}) async {
    final url =
        aliasId.startsWith("http") ? aliasId : '$_baseUrl/category/$aliasId';
    final response = await _httpGet(url);
    final document = html.parse(response.body);

    final epStart = document
        .querySelector('.anime_video_body > ul > li > a')
        ?.attributes['ep_start'];
    final epEnd = document
        .querySelector('.anime_video_body > ul > li:last-child > a')
        ?.attributes['ep_end'];
    final alias = document.querySelector('#alias_anime')?.attributes['value'];
    final movieId = document.querySelector('#movie_id')?.attributes['value'];

    if (epEnd == null || alias == null || movieId == null) {
      throw Exception('Failed to retrieve episode details');
    }

    final ajaxUrl =
        '$_ajaxUrl/load-list-episode?ep_start=$epStart&ep_end=$epEnd&id=$movieId&default_ep=0&alias=$alias';
    final ajaxResponse = await _httpGet(ajaxUrl);
    final parsedAjaxResponse = html.parse(ajaxResponse.body);

    final firstEpisodeLink =
        parsedAjaxResponse.querySelector('a')?.attributes['href'];
    if (firstEpisodeLink == null) throw Exception('No episodes found');

    final totalEpisodes = int.parse(epEnd);
    final baseEpisodeLink =
        '$_baseUrl${firstEpisodeLink.split('-').sublist(0, firstEpisodeLink.split('-').length - 1).join('-').trimLeft()}-';
    final animeTitle =
        document.querySelector('.anime_info_body_bg h1')?.text.trim();
    final episodes = List.generate(totalEpisodes, (i) {
      final episodeId = '$baseEpisodeLink${i + 1}';
      return {
        "episodeId": episodeId,
        "title": "Episode ${i + 1}",
        "number": i + 1
      };
    });

    final result = {
      "id": aliasId,
      "name": animeTitle,
      "episodes": episodes,
      "totalEpisodes": episodes.length,
    };

    log(result.toString());
    return result;
  }

  Future<List<Map<String, String>>> _getAllServerLinks(
      String episodeUrl) async {
    final response = await _httpGet(episodeUrl);
    final document = html.parse(response.body);

    return document
        .querySelectorAll('div.anime_muti_link > ul > li')
        .map((element) {
      final serverName = element.attributes['class'] ?? '';
      final dataVideo = element.children
          .map((child) => child.attributes['data-video'])
          .firstWhere((video) => video != null, orElse: () => null);

      return {
        'server': serverName == 'anime' ? 'vidstreaming' : serverName,
        'src': dataVideo ?? '',
      };
    }).toList();
  }

  String _getServerUrl(String serverName, List<Map<String, String>> servers) {
    return servers
        .firstWhere(
            (server) =>
                server['server']?.toLowerCase() == serverName.toLowerCase(),
            orElse: () => {})
        .putIfAbsent('src', () => '');
  }

  Future<String> getDownloadLink(String episodeUrl) async {
    final resp = await _httpGet(episodeUrl);
    if (resp.statusCode == 200) {
      var document = html.parse(resp.body);
      var dwLink =
          document.querySelector('.dowloads a')?.attributes['href'] ?? '';
      return dwLink;
    }
    return '';
  }

  Future<http.Response> _httpGet(String url) async {
    return await http.get(Uri.parse(url));
  }

  @override
  Future<String?> mappingId(String query) async {
    try {
      final result = await scrapeAnimeSearch(query) as List<dynamic>?;
      if (result == null || result.isEmpty) {
        return null; 
      }

      String? bestMatchId;
      double highestSimilarity = 0.0;

      for (var anime in result) {
        if (anime is Map<String, dynamic> &&
            anime['name'] is String &&
            anime['id'] is String) {
          final similarity = jaroWinklerDistance(query, anime['name']);
          if (similarity > highestSimilarity) {
            highestSimilarity = similarity;
            bestMatchId = anime['id'];
          }
        }
      }
      log(bestMatchId.toString());
      return bestMatchId;
    } catch (e) {
      return null;
    }
  }

  // @override
  // bool get isMulti => false;

  @override
  String get sourceName => 'GogoAnime';
}