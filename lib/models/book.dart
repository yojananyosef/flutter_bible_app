class Book {
  final String id;
  final String nombre;
  final int capitulos;

  Book({required this.id, required this.nombre, required this.capitulos});

  factory Book.fromJson(String id, Map<String, dynamic> json) {
    return Book(id: id, nombre: json['nombre'], capitulos: json['capitulos']);
  }
}
