import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/operation_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> _items = [];
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
      ).pb.collection('users').getFullList(sort: 'name', expand: 'operation');
      if (mounted) {
        setState(() {
          _items = records.map((r) => UserModel.fromRecord(r)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForm([UserModel? item]) async {
    await showDialog(
      context: context,
      builder: (context) => UserFormDialog(item: item, onSave: _fetchItems),
    );
  }

  Future<void> _delete(String id) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.id == id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puede eliminarse a sí mismo')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de que desea eliminar este usuario?'),
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

    if (confirmed == true) {
      try {
        await authService.pb.collection('users').delete(id);
        _fetchItems();
      } catch (e) {
        if (mounted) {
          String message = 'Error al eliminar: $e';
          if (e.toString().contains(
            'Make sure that the record is not part of a required relation',
          )) {
            message =
                'No se puede eliminar este usuario porque tiene actividades asociadas';
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
            subtitle: Text(
              '${item.email} - ${item.operationName ?? 'Sin operación'}',
            ),
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

class UserFormDialog extends StatefulWidget {
  final UserModel? item;
  final VoidCallback onSave;

  const UserFormDialog({super.key, this.item, required this.onSave});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _role = 'technician';
  String? _operationId;
  List<OperationModel> _operations = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name);
    _emailController = TextEditingController(text: widget.item?.email);
    _passwordController = TextEditingController();
    if (widget.item != null) {
      _role = widget.item!.role;
      _operationId = widget.item!.operationId;
    }
    _fetchOperations();
  }

  Future<void> _fetchOperations() async {
    try {
      final records = await Provider.of<AuthService>(
        context,
        listen: false,
      ).pb.collection('operations').getFullList(sort: 'name');
      if (mounted) {
        setState(() {
          _operations = records
              .map((r) => OperationModel.fromRecord(r))
              .toList();
          // If editing and operationId is not in list (maybe deleted?), handle it?
          // For now assume it exists or is null.
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Nuevo Usuario' : 'Editar Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              if (widget.item == null) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
              ],
              if (widget.item != null) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña (opcional)',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'technician', child: Text('Técnico')),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Administrador'),
                  ),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _operationId,
                decoration: const InputDecoration(labelText: 'Operación'),
                items: _operations
                    .map(
                      (o) => DropdownMenuItem(value: o.id, child: Text(o.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _operationId = v),
                validator: (v) => v == null ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final body = {
              'name': _nameController.text,
              'email': _emailController.text,
              'role': _role,
              'operation': _operationId,
            };

            if (_passwordController.text.isNotEmpty) {
              body['password'] = _passwordController.text;
              body['passwordConfirm'] = _passwordController.text;
            }

            try {
              final pb = Provider.of<AuthService>(context, listen: false).pb;
              if (widget.item == null) {
                await pb.collection('users').create(body: body);
              } else {
                await pb
                    .collection('users')
                    .update(widget.item!.id, body: body);
              }
              if (context.mounted) {
                Navigator.pop(context);
                widget.onSave();
              }
            } catch (e) {
              // Handle error
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
