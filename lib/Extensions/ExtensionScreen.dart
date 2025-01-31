// ignore_for_file: file_names

import 'package:azyx/Extensions/ExtensionList.dart';
import 'package:azyx/api/Mangayomi/Model/Source.dart';
import 'package:azyx/components/Common/ScrollConfig.dart';
import 'package:azyx/core/icons/icons_broken.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../Preferences/PrefManager.dart';
import '../../Preferences/Preferences.dart';
import '../../StorageProvider.dart';
import '../../main.dart';

class ExtensionScreen extends ConsumerStatefulWidget {
  const ExtensionScreen({super.key});

  @override
  ConsumerState<ExtensionScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<ExtensionScreen>
    with TickerProviderStateMixin {
  late TabController _tabBarController;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _tabBarController = TabController(length: 4, vsync: this);
    _tabBarController.animateTo(0);
    _tabBarController.addListener(() {
      setState(() {
        _textEditingController.clear();
        //_isSearch = false;
      });
    });
  }

  _checkPermission() async {
    await StorageProvider().requestPermission();
  }

  final _textEditingController = TextEditingController();

  //bool _isSearch = false;
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    return ScrollConfig(
      context,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text(
              'Extensions',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: theme.primary,
              ),
            ),
            leading: IconButton(
                onPressed: () {
                  Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => const HomeScreen()));
                },
                icon: const Icon(Broken.arrow_left_2)),
            iconTheme: IconThemeData(color: theme.primary),
            bottom: TabBar(
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: true,
              controller: _tabBarController,
              dragStartBehavior: DragStartBehavior.start,
              tabs: [
                _buildTab(context, 'INSTALLED ANIME', false, true),
                _buildTab(context, 'AVAILABLE ANIME', false, false),
                _buildTab(context, 'INSTALLED MANGA', true, true),
                _buildTab(context, 'AVAILABLE MANGA', true, false),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabBarController,
            children: [
              Extension(
                installed: true,
                query: _textEditingController.text,
                isManga: false,
              ),
              Extension(
                installed: false,
                query: _textEditingController.text,
                isManga: false,
              ),
              Extension(
                installed: true,
                query: _textEditingController.text,
                isManga: true,
              ),
              Extension(
                installed: false,
                query: _textEditingController.text,
                isManga: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(
      BuildContext context, String label, bool isManga, bool installed) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
          const SizedBox(width: 8),
          _extensionUpdateNumbers(context, isManga, installed),
        ],
      ),
    );
  }
}

Widget _extensionUpdateNumbers(
    BuildContext context, bool isManga, bool installed) {
  return StreamBuilder(
      stream: isar.sources
          .filter()
          .idIsNotNull()
          .and()
          .isAddedEqualTo(installed)
          .isActiveEqualTo(true)
          .isMangaEqualTo(isManga)
          .watch(fireImmediately: true),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final entries = snapshot.data!
              .where((element) => PrefManager.getVal(PrefName.NSFWExtensions)
                  ? true
                  : element.isNsfw == false)
              .toList();

          return entries.isEmpty
              ? Container()
              : Text(
                  "(${entries.length.toString()})",
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                );
        }
        return Container();
      });
}
