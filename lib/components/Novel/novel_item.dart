// anime_item.dart
// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class NovelItem extends StatelessWidget {
  final String id;
  final String poster;
  final String name;
  final String rating;
  final String tagg;
 

  const NovelItem(
      {super.key,
      required this.id,
      required this.poster,
      required this.name,
      required this.rating,
      required this.tagg,
      });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/novelDetail',
            arguments: {"id": id, "image": poster, "tagg": tagg});
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: Platform.isAndroid || Platform.isIOS ? 150 : 230,
                width: Platform.isAndroid || Platform.isIOS ? 103 : 160,
                margin: const EdgeInsets.only(right: 10),
                child: Hero(
                  tag: tagg,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: poster,
                      fit: BoxFit.cover,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Center(
                        child: CircularProgressIndicator(
                            value: downloadProgress.progress),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
              
              rating.isNotEmpty ?
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 22,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(10),
                        topLeft: Radius.circular(25)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          rating,
                          style:  TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontFamily: "Poppins-Bold"),
                        ),
                         Icon(
                          Iconsax.star1,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ) : const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name.length > 12 ? '${name.substring(0, 10)}...' : name,
            style: const TextStyle(fontFamily: "Poppins-Bold"),
          ),
        ],
      ),
    );
  }
}
