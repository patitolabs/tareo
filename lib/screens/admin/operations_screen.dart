import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/operation_model.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  List<OperationModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final records = await Provider.of<AuthService>(
        context,
        listen: false,
      ).pb.collection('operations').getFullList(sort: 'name');
      if (mounted) {
        setState(() {
          _items = records.map((r) => OperationModel.fromRecord(r)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForm([OperationModel? item]) async {
    final controller = TextEditingController(text: item?.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Nueva Operación' : 'Editar Operación'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              try {
                final pb = Provider.of<AuthService>(context, listen: false).pb;
                if (item == null) {
                  await pb
                      .collection('operations')
                      .create(body: {'name': controller.text});
                } else {
                  await pb
                      .collection('operations')
                      .update(item.id, body: {'name': controller.text});
                }
                if (context.mounted) Navigator.pop(context);
                _fetchItems();
              } catch (e) {
                // Handle error
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Está seguro de que desea eliminar esta operación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      try {
        await Provider.of<AuthService>(
          context,
          listen: false,
        ).pb.collection('operations').delete(id);
        _fetchItems();
      } catch (e) {
        if (mounted) {
          String message = 'Error al eliminar: $e';
          if (e.toString().contains(
            'Make sure that the record is not part of a required relation',
          )) {
            message =
                'No se puede eliminar esta operación porque tiene usuarios asociados';
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showForm(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _delete(item.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
