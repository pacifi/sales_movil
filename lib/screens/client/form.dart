import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/models/client.dart';
import 'package:sales/providers/client_provider.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerDocumentNumber = TextEditingController();

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    if (client != null) {
      controllerName.text = client.name;
      controllerDocumentNumber.text = client.documentNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Formulario de Cliente'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            TextField(
              controller: controllerName,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controllerDocumentNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de documento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (controllerName.text.trim().isEmpty ||
                    controllerDocumentNumber.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Completa todos los campos'),
                    ),
                  );
                  return;
                }
                if (isEditing) {
                  await context.read<ClientProvider>().edit(
                    widget.client!.id,
                    Client(
                      widget.client!.id,
                      controllerName.text.trim(),
                      controllerDocumentNumber.text.trim(),
                      false,
                      widget.client!.serverId,
                    ),
                  );
                } else {
                  await context.read<ClientProvider>().save(
                    Client(
                      0,
                      controllerName.text.trim(),
                      controllerDocumentNumber.text.trim(),
                      false,
                      null,
                    ),
                  );
                }
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Editar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }
}