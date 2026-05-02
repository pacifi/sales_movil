import 'package:sales/models/category.dart';

class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final Category category;

  Product(this.id, this.name, this.price, this.description, this.category);

  factory Product.fromJson(Map<String, dynamic> productJson) {
    return Product(
      productJson['id'],
      productJson['name'].toString(),
      double.parse(productJson['price'].toString()),
      productJson['description'].toString(),
      Category.fromJson(productJson['category']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      'name': this.name,
      'description': this.description,
      'price': this.price,
      'category': this.category.id,
    };
  }
}
