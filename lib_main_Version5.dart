import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'db/app_database.dart';
import 'providers/project_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/media_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/tech_log_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/youtube_service.dart';

const String kBackgroundSyncTask = "shiskar_background_sync_task";

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kBackgroundSyncTask) {
      try {
        final svc = YouTubeService(minLongFormSeconds: 78);
        // Build default channels map for background fetch
        final channelsMap = YouTubeService.defaultChannels;
        await svc.fetchAndCacheAll(channelsMap);
      } catch (e) {
        // ignore background errors
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.init();

  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  final prefs = await SharedPreferences.getInstance();
  final sawWelcome = prefs.getBool('saw_welcome') ?? false;

  runApp(MyApp(sawWelcome: sawWelcome));
}

class MyApp extends StatelessWidget {
  final bool sawWelcome;
  const MyApp({super.key, required this.sawWelcome});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectProvider()..loadAll()..maybeStartAutoSync(),
      child: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final theme = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            brightness: provider.isDarkMode ? Brightness.dark : Brightness.light,
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            }),
          );
          return MaterialApp(
            title: 'Shiskar Studio Manager',
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: sawWelcome ? const MainShell() : const WelcomeScreen(),
            routes: {
              '/settings': (_) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _pages = const [
    DashboardScreen(),
    TasksScreen(),
    MediaScreen(),
    TechLogScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.perm_media), label: 'Media'),
          NavigationDestination(icon: Icon(Icons.build), label: 'Tech Log'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}