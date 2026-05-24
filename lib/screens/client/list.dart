import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/client_provider.dart';
import 'package:sales/screens/client/form.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    context.read<ClientProvider>().loadAll();
  }

  Future<void> _sincronizar() async {
    setState(() => _syncing = true);

    final result = await context.read<ClientProvider>().sincronizar();

    if (!mounted) return;

    setState(() => _syncing = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sincronización completa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Creados: ${result['sincronizados']}'),
            Text('🔄 Actualizados: ${result['actualizados']}'),
            Text('⚠️ Ya existían: ${result['duplicados']}'),
            Text('❌ Errores: ${result['errores']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarEliminar(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final clients = context.watch<ClientProvider>().clients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Clientes'),
        backgroundColor: Colors.orange,
        actions: [
          _syncing
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
              : IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: _sincronizar,
          ),
        ],
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClientFormScreen()),
          );
          if (!mounted) return;
          context.read<ClientProvider>().loadAll();
        },
        child: const Icon(Icons.add),
      ),
      body: clients.isEmpty
          ? const Center(child: Text('No hay clientes registrados'))
          : ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return Dismissible(
            key: Key(client.id.toString()),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmarEliminar(context),
            onDismissed: (_) async {
              await context.read<ClientProvider>().delete(client);
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              leading: Icon(
                client.isSynced ? Icons.cloud_done : Icons.cloud_off,
                color: client.isSynced ? Colors.green : Colors.red,
              ),
              title: Text(client.name),
              subtitle: Text(client.documentNumber),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ClientFormScreen(client: client),
                  ),
                );
                if (!mounted) return;
                context.read<ClientProvider>().loadAll();
              },
            ),
          );
        },
      ),
    );
  }
}