import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BibleService {
  final String baseUrl = "https://api-adventista-default-rtdb.firebaseio.com";
  final String version = "vbl";

  // 1. Obtener la lista de libros (Metadata ligera)
  Future<Map<String, List<Book>>> fetchBooks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/biblias/$version/libros.json'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      Map<String, List<Book>> testamentos = {"at": [], "nt": []};

      data['at'].forEach(
        (id, json) => testamentos['at']!.add(Book.fromJson(id, json)),
      );
      data['nt'].forEach(
        (id, json) => testamentos['nt']!.add(Book.fromJson(id, json)),
      );

      return testamentos;
    } else {
      throw Exception('Error al cargar libros');
    }
  }

  // 2. Obtener un capítulo específico (Contenido pesado)
  Future<Map<String, String>> fetchChapter(
    String bookId,
    int chapterNum,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/versiculos/$version/$bookId/$chapterNum.json'),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        Map<String, String> verses = {};
        for (int i = 0; i < decoded.length; i++) {
          if (decoded[i] != null) {
            verses[i.toString()] = decoded[i].toString();
          }
        }
        return verses;
      }
      return Map<String, String>.from(decoded);
    } else {
      throw Exception('Error al cargar el capítulo');
    }
  }

  // 3. Obtener notas al pie (Opcional)
  Future<Map<String, String>> fetchFootnotes(
    String bookId,
    int chapterNum,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notas/$version/$bookId/$chapterNum.json'),
    );
    if (response.statusCode == 200 && response.body != 'null') {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        Map<String, String> notes = {};
        for (int i = 0; i < decoded.length; i++) {
          if (decoded[i] != null) {
            notes[i.toString()] = decoded[i].toString();
          }
        }
        return notes;
      }
      return Map<String, String>.from(decoded);
    }
    return {};
  }
}
