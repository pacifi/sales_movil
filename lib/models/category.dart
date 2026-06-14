// /lib/models/category.dart

class Category {
  final int id;
  final String name;
  final String description;

  Category(this.id, this.name, this.description);

  factory Category.fromJson(Map<String, dynamic> categoryJson) {
    return Category(
      categoryJson['id'],
      categoryJson['name'].toString(),
      categoryJson['description'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      'name': this.name,
      'description': this.description
    };
  }
}
