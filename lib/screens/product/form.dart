import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sales/models/category.dart';
import 'package:sales/models/product.dart';
import 'package:sales/providers/category_provider.dart';
import 'package:sales/providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _name = '';
  String _description = '';
  double _price = 0.0;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadAll();
    _selectedCategoryId = widget.product?.category.id;
  }

  Future<void> _submit() async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final categories = context.read<CategoryProvider>().categories;
    final selectedCategory =
    categories.firstWhere((cat) => cat.id == _selectedCategoryId);

    setState(() => _isLoading = true);
    try {
      final provider = context.read<ProductProvider>();
      if (widget.product == null) {
        await provider.save(
          Product(0, _name, _price, _description, selectedCategory),
        );
      } else {
        await provider.edit(
          widget.product!.id,
          Product(
              widget.product!.id, _name, _price, _description, selectedCategory),
        );
      }
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final selectedCategory = _selectedCategoryId == null
        ? null
        : categories.where((c) => c.id == _selectedCategoryId).isNotEmpty
        ? categories.firstWhere((c) => c.id == _selectedCategoryId)
        : null;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            if (categories.isEmpty)
              const CircularProgressIndicator()
            else
              DropdownButtonFormField<Category>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat.name),
                ))
                    .toList(),
                onChanged: (cat) =>
                    setState(() => _selectedCategoryId = cat?.id),
                validator: (value) =>
                value == null ? 'Selecciona una categoría' : null,
              ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.product?.name ?? '',
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 2) return 'Mínimo 2 caracteres';
                return null;
              },
              onSaved: (value) => _name = value!.trim(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.product?.price.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: 'S/ ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El precio es requerido';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null) return 'Ingresa un número válido';
                if (parsed < 0) return 'El precio no puede ser negativo';
                return null;
              },
              onSaved: (value) => _price = double.parse(value!.trim()),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.product?.description ?? '',
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La descripción es requerida';
                }
                return null;
              },
              onSaved: (value) => _description = value!.trim(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(widget.product == null ? 'Crear' : 'Editar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}