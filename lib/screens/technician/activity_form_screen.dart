import 'package:flutter/material.dart';
import 'package:tareo/utils/date_utils.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/activity_model.dart';
import '../../models/activity_type_model.dart';

class ActivityFormScreen extends StatefulWidget {
  final ActivityModel? activity;

  const ActivityFormScreen({super.key, this.activity});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  String? _selectedTypeId;

  List<ActivityTypeModel> _activityTypes = [];
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _fetchActivityTypes();
      if (widget.activity != null) {
        _selectedDate = widget.activity!.started;
        _startTime = TimeOfDay.fromDateTime(widget.activity!.started);
        _endTime = TimeOfDay.fromDateTime(widget.activity!.ended);
        _selectedTypeId = widget.activity!.typeId;
        _descriptionController.text = widget.activity!.description;
      }
      _isInit = false;
    }
  }

  Future<void> _fetchActivityTypes() async {
    try {
      final records = await Provider.of<AuthService>(
        context,
        listen: false,
      ).pb.collection('activityTypes').getFullList(sort: 'name');

      if (mounted) {
        setState(() {
          _activityTypes = records
              .map((r) => ActivityTypeModel.fromRecord(r))
              .toList();
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un tipo de actividad')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser posterior a la de inicio'),
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final body = {
      'user': authService.currentUser!.id,
      'started': formatDateTimeForPocketBase(startDateTime),
      'ended': formatDateTimeForPocketBase(endDateTime),
      'type': _selectedTypeId,
      'description': _descriptionController.text,
    };

    try {
      if (widget.activity != null) {
        await authService.pb
            .collection('activities')
            .update(widget.activity!.id, body: body);
      } else {
        await authService.pb.collection('activities').create(body: body);
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
    return is24Hour ? DateFormat.Hm().format(dt) : DateFormat.jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activity != null ? 'Editar Actividad' : 'Nueva Actividad',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedTypeId,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Actividad',
                ),
                items: _activityTypes
                    .map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTypeId = value;
                  });
                },
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text(
                  DateFormat.yMMMMEEEEd('es_PE').format(_selectedDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
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
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Inicio'),
                      subtitle: Text(_formatTime(_startTime)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _startTime = picked;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Fin'),
                      subtitle: Text(_formatTime(_endTime)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _endTime = picked;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
