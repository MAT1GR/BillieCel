import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTaskPage extends StatefulWidget {
  final Map<String, dynamic>? task; // Acepta una tarea para editar

  const AddTaskPage({super.key, this.task});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final task = widget.task!;
      _titleController.text = task['title'];
      _descriptionController.text = task['description'] ?? '';
      if (task['due_date'] != null) {
        _selectedDate = DateTime.parse(task['due_date']);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _submitTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userId = supabase.auth.currentUser!.id;
        final coupleModeProvider = context.read<CoupleModeProvider>();

        final data = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'due_date': _selectedDate?.toIso8601String(),
          'completed': false, // New tasks are not completed
        };

        if (coupleModeProvider.isJointMode) {
          data['couple_id'] = coupleModeProvider.coupleId!;
          data['user_id'] = userId; // Still associate with user for RLS/tracking
        } else {
          data['user_id'] = userId;
        }

        if (_isEditing) {
          PostgrestFilterBuilder updateQuery = supabase.from('tasks').update(data).match({
            'id': widget.task!['id'],
          });
          if (coupleModeProvider.isJointMode) {
            updateQuery = updateQuery.eq('couple_id', coupleModeProvider.coupleId!); // Ensure updating correct couple task
          } else {
            updateQuery = updateQuery.eq('user_id', userId); // Ensure updating correct personal task
          }
          await updateQuery;
        } else {
          await supabase.from('tasks').insert(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea guardada con éxito')),
          );
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al guardar la tarea'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Tarea' : 'Nueva Tarea')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título*'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingresa un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de Vencimiento (opcional)',
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white,
                ),
                onPressed: _presentDatePicker,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedDate == null
                        ? 'Seleccionar fecha'
                        : DateFormat.yMMMd('es_AR').format(_selectedDate!),
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitTask,
                    child: Text(
                      _isEditing ? 'Guardar Cambios' : 'Guardar Tarea',
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
