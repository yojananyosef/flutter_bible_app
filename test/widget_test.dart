// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:bible_app/main.dart';
import 'package:bible_app/features/bible/data/datasources/bible_remote_datasource.dart';
import 'package:bible_app/features/bible/data/datasources/bible_local_datasource.dart';
import 'package:bible_app/features/bible/data/repositories/bible_repository_impl.dart';

class MockBibleLocalDataSource extends BibleLocalDataSourceImpl {}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final client = http.Client();
    final remoteDataSource = BibleRemoteDataSourceImpl(client: client);
    final localDataSource = MockBibleLocalDataSource();
    final repository = BibleRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    await tester.pumpWidget(BibleApp(repository: repository));

    expect(find.byType(CupertinoApp), findsOneWidget);
  });
}
