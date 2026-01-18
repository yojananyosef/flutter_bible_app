import '../../domain/entities/book_entity.dart';

class BookModel extends BookEntity {
  BookModel({
    required super.id,
    required super.nombre,
    required super.capitulos,
  });

  factory BookModel.fromJson(String id, Map<String, dynamic> json) {
    return BookModel(
      id: id,
      nombre: json['nombre'],
      capitulos: json['capitulos'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'nombre': nombre, 'capitulos': capitulos, 'id': id};
  }
}
