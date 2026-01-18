import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/bible/data/datasources/bible_local_datasource.dart';
import 'features/bible/data/datasources/bible_remote_datasource.dart';
import 'features/bible/data/repositories/bible_repository_impl.dart';
import 'features/bible/presentation/pages/chapter_view_page.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Hive
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox('bible_books'),
      Hive.openBox('bible_chapters'),
      Hive.openBox('bible_footnotes'),
      Hive.openBox('bible_highlights'),
      Hive.openBox('bible_state'),
    ]);

    // Dependency Injection
    final client = http.Client();
    final remoteDataSource = BibleRemoteDataSourceImpl(client: client);
    final localDataSource = BibleLocalDataSourceImpl();
    final repository = BibleRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    runApp(BibleApp(repository: repository));
  } catch (e) {
    runApp(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error al iniciar: $e'),
            ),
          ),
        ),
      ),
    );
  }
}

class BibleApp extends StatelessWidget {
  final BibleRepositoryImpl repository;

  const BibleApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Bible App',
      theme: AppTheme.cupertinoTheme,
      home: FutureBuilder<Map<String, dynamic>?>(
        future: repository.getLastRead(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()),
            );
          }

          final lastRead = snapshot.data;

          return CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.book),
                  label: 'Biblia',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.chat_bubble_2),
                  label: 'Comentario',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.layers),
                  label: 'Interlineal',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.calendar),
                  label: 'Planes',
                ),
              ],
            ),
            tabBuilder: (context, index) {
              switch (index) {
                case 0:
                  return CupertinoTabView(
                    builder: (context) => ChapterViewPage(
                      repository: repository,
                      initialBookId: lastRead?['bookId'] ?? 'GEN',
                      initialBookName: lastRead?['bookName'] ?? 'Génesis',
                      initialChapterNum: lastRead?['chapterNum'] ?? 1,
                    ),
                  );
                case 1:
                  return CupertinoTabView(
                    builder: (context) =>
                        const PlaceholderPage(title: 'Comentario Bíblico'),
                  );
                case 2:
                  return CupertinoTabView(
                    builder: (context) =>
                        const PlaceholderPage(title: 'Interlineal'),
                  );
                case 3:
                  return CupertinoTabView(
                    builder: (context) =>
                        const PlaceholderPage(title: 'Planes de Lectura'),
                  );
                default:
                  return Container();
              }
            },
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(title)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.hammer,
              size: 64,
              color: CupertinoColors.systemGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'En construcción',
              style: CupertinoTheme.of(
                context,
              ).textTheme.navLargeTitleTextStyle,
            ),
            Text(
              'Próximamente: $title',
              style: CupertinoTheme.of(context).textTheme.textStyle,
            ),
          ],
        ),
      ),
    );
  }
}
