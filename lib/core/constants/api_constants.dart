class ApiConstants {
  static const String baseUrl =
      "https://api-adventista-default-rtdb.firebaseio.com";
  static const String version = "vbl";

  static String booksPath() => "/biblias/$version/libros.json";
  static String chapterPath(String bookId, int chapterNum) =>
      "/versiculos/$version/$bookId/$chapterNum.json";
  static String footnotesPath(String bookId, int chapterNum) =>
      "/notas/$version/$bookId/$chapterNum.json";
}
