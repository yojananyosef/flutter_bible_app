import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/bible_order.dart';
import '../models/book_model.dart';

abstract class BibleRemoteDataSource {
  Future<Map<String, List<BookModel>>> fetchBooks();
  Future<Map<String, String>> fetchChapter(String bookId, int chapterNum);
  Future<Map<String, String>> fetchFootnotes(String bookId, int chapterNum);
}

class BibleRemoteDataSourceImpl implements BibleRemoteDataSource {
  final http.Client client;

  BibleRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, List<BookModel>>> fetchBooks() async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.booksPath()}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      Map<String, List<BookModel>> testamentos = {"at": [], "nt": []};

      // Helper to sort and add books
      void processBooks(String testamentoKey, List<String> orderList) {
        final Map<String, dynamic> booksMap = data[testamentoKey];
        for (final id in orderList) {
          if (booksMap.containsKey(id)) {
            testamentos[testamentoKey]!.add(
              BookModel.fromJson(id, booksMap[id]),
            );
          }
        }
        // Add any missing books just in case
        booksMap.forEach((id, json) {
          if (!orderList.contains(id)) {
            testamentos[testamentoKey]!.add(BookModel.fromJson(id, json));
          }
        });
      }

      processBooks('at', BibleOrder.atOrder);
      processBooks('nt', BibleOrder.ntOrder);

      return testamentos;
    } else {
      throw Exception('Error al cargar libros');
    }
  }

  @override
  Future<Map<String, String>> fetchChapter(
    String bookId,
    int chapterNum,
  ) async {
    final response = await client.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.chapterPath(bookId, chapterNum)}',
      ),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return _processMapOrList(decoded);
    } else {
      throw Exception('Error al cargar el capítulo');
    }
  }

  @override
  Future<Map<String, String>> fetchFootnotes(
    String bookId,
    int chapterNum,
  ) async {
    final response = await client.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.footnotesPath(bookId, chapterNum)}',
      ),
    );
    if (response.statusCode == 200 && response.body != 'null') {
      final decoded = json.decode(response.body);
      return _processMapOrList(decoded);
    }
    return {};
  }

  Map<String, String> _processMapOrList(dynamic decoded) {
    if (decoded is List) {
      Map<String, String> result = {};
      for (int i = 0; i < decoded.length; i++) {
        if (decoded[i] != null) {
          result[i.toString()] = decoded[i].toString();
        }
      }
      return result;
    }
    return Map<String, String>.from(decoded);
  }
}
