import 'dart:io';

import 'package:azyx/components/Anime/genres.dart';
import 'package:azyx/components/Manga/mangaInfo.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:text_scroll/text_scroll.dart';

class Mangaalldetails extends StatelessWidget {
  final dynamic mangaData;
  const Mangaalldetails({super.key, this.mangaData});
 
  @override
  Widget build(BuildContext context) {
    if (mangaData == null) {
      return const Column(
        children:[
          SizedBox(height: 50,),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 300,)
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextScroll(
              mangaData == null
                  ? "Loading"
                  : mangaData['name'],
              mode: TextScrollMode.bouncing,
              velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
              delayBefore: const Duration(milliseconds: 500),
              pauseBetween: const Duration(milliseconds: 1000),
              textAlign: TextAlign.center,
              selectable: true,
              style: const TextStyle(fontSize: 18, fontFamily: "Poppins-Bold"),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Ionicons.eye,
                size: 20,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                mangaData['view'],
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Genres(genres: mangaData['genres']),
          const SizedBox(
            height: 30,
          ),
          MangaInfo(mangaData: mangaData,),
          const SizedBox(
            height: 10,
          ),
          Text(!Platform.isAndroid || Platform.isIOS ? mangaData['description'] : (mangaData['description'].length > 380 ? '${mangaData['description'].substring(0,380)}...' : mangaData['description']), style: const TextStyle(fontStyle: FontStyle.italic, color: Color.fromARGB(232, 165, 159, 159)),),
        ],
      ),
    );
  }
}
