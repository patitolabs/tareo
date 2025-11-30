import 'package:flutter/material.dart';
import 'package:tareo/utils/date_utils.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/activity_model.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _sortAscending = true;
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  String? _selectedUserId;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    // Initialize selected user to current user if not admin, or null (all) if admin?
    // Requirement: "View activities of the user per day" (Technician)
    // "A widget to show activities by user in the activities list" (Admin)

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser?.isTechnician ?? false) {
        _selectedUserId = authService.currentUser?.id;
      }
      _fetchUsers(); // Only needed for admin really, but safe to call
      _fetchActivities();
    });
  }

  Future<void> _fetchUsers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.isAdmin ?? false) {
      try {
        final records = await authService.pb
            .collection('users')
            .getFullList(sort: 'name');
        setState(() {
          _users = records.map((r) => UserModel.fromRecord(r)).toList();
        });
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    // Format dates for PocketBase filter
    final startStr = formatDateTimeForPocketBase(startOfDay);
    final endStr = formatDateTimeForPocketBase(endOfDay);

    String filter = 'started >= "$startStr" && ended <= "$endStr"';

    if (_selectedUserId != null) {
      filter += ' && user = "$_selectedUserId"';
    } else if (authService.currentUser?.isTechnician ?? false) {
      // Technician can only see their own
      filter += ' && user = "${authService.currentUser?.id}"';
    }

    try {
      final records = await authService.pb
          .collection('activities')
          .getFullList(
            filter: filter,
            sort: _sortAscending ? 'started' : '-started',
            expand: 'type,user',
          );

      if (mounted) {
        setState(() {
          _activities = records
              .map((r) => ActivityModel.fromRecord(r))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar actividades: $e')),
        );
      }
    }
  }

  Future<void> _deleteActivity(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Está seguro de que desea eliminar esta actividad?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirm == true) {
      try {
        await Provider.of<AuthService>(
          context,
          listen: false,
        ).pb.collection('activities').delete(id);
        if (!mounted) return;
        _fetchActivities();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: UserAvatar(),
          ),
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
                _fetchActivities();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            locale: const Locale('es', 'PE'),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                              _fetchActivities();
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat.yMMMMEEEEd('es_PE').format(_selectedDate),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(
                            const Duration(days: 1),
                          );
                          _fetchActivities();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(
                            const Duration(days: 1),
                          );
                          _fetchActivities();
                        });
                      },
                    ),
                  ],
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por usuario',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._users.map(
                        (u) =>
                            DropdownMenuItem(value: u.id, child: Text(u.name)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUserId = value;
                        _fetchActivities();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activities.isEmpty
                ? const Center(child: Text('No hay actividades registradas'))
                : ListView.builder(
                    itemCount: _activities.length,
                    itemBuilder: (context, index) {
                      final activity = _activities[index];
                      final is24Hour = MediaQuery.of(
                        context,
                      ).alwaysUse24HourFormat;
                      final timeFormat = is24Hour
                          ? DateFormat.Hm()
                          : DateFormat.jm();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(activity.type?.name ?? 'Sin tipo'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${timeFormat.format(activity.started)} - ${timeFormat.format(activity.ended)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (activity.description.isNotEmpty)
                                Text(activity.description),
                              if (isAdmin && activity.user != null)
                                Text(
                                  'Usuario: ${activity.user!.name}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orangeAccent,
                                ),
                                onPressed: () async {
                                  await context.push(
                                    '/activity/edit',
                                    extra: activity,
                                  );
                                  _fetchActivities();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteActivity(activity.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/activity/new');
          _fetchActivities();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
