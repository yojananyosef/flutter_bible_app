import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/bible/data/datasources/bible_local_datasource.dart';
import 'features/bible/data/datasources/bible_remote_datasource.dart';
import 'features/bible/data/repositories/bible_repository_impl.dart';
import 'features/bible/presentation/pages/book_list_page.dart';

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
      home: BookListPage(repository: repository),
      debugShowCheckedModeBanner: false,
    );
  }
}
