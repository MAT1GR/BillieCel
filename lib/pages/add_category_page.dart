import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCategoryPage extends StatefulWidget {
  final Map<String, dynamic>? category;

  const AddCategoryPage({super.key, this.category});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.category != null;
    _nameController = TextEditingController(text: _isEditing ? widget.category!['name'] : '');
    _selectedIcon = _isEditing ? widget.category!['icon'] : 'category';
    _selectedColor = _isEditing ? widget.category!['color'] : '0xFF42A5F5';
  }
  final Map<String, IconData> _iconMap = {
    'category': Icons.category,
    'fastfood': Icons.fastfood,
    'directions_bus': Icons.directions_bus,
    'hotel': Icons.hotel,
    'healing': Icons.healing,
    'theaters': Icons.theaters,
    'shopping_cart': Icons.shopping_cart,
    'home': Icons.home,
    'school': Icons.school,
    'pets': Icons.pets,
    'fitness_center': Icons.fitness_center,
    'card_giftcard': Icons.card_giftcard,
    'attach_money': Icons.attach_money,
    'savings': Icons.savings,
    'lightbulb': Icons.lightbulb,
    'receipt': Icons.receipt,
    'build': Icons.build,
    'flight': Icons.flight,
  };

  final List<String> _colorList = [
    '0xFFD32F2F', // red
    '0xFFC2185B', // pink
    '0xFF7B1FA2', // purple
    '0xFF512DA8', // deepPurple
    '0xFF303F9F', // indigo
    '0xFF1976D2', // blue
    '0xFF0288D1', // lightBlue
    '0xFF0097A7', // cyan
    '0xFF00796B', // teal
    '0xFF388E3C', // green
    '0xFF689F38', // lightGreen
    '0xFFFBC02D', // yellow
    '0xFFFFA000', // amber
    '0xFFF57C00', // orange
    '0xFFE64A19', // deepOrange
    '0xFF5D4037', // brown
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Categoría' : 'Añadir Categoría'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('Ícono', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _iconMap.length,
                  itemBuilder: (context, index) {
                    final iconName = _iconMap.keys.elementAt(index);
                    final iconData = _iconMap[iconName];
                    return IconButton(
                      icon: Icon(iconData, color: _selectedIcon == iconName ? Theme.of(context).primaryColor : null),
                      onPressed: () {
                        setState(() {
                          _selectedIcon = iconName;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text('Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _colorList.length,
                  itemBuilder: (context, index) {
                    final color = _colorList[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: Color(int.parse(color.substring(2), radix: 16)),
                        child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final userId = supabase.auth.currentUser!.id;
                    final coupleModeProvider = context.read<CoupleModeProvider>();

                    final data = {
                      'name': _nameController.text,
                      'icon': _selectedIcon,
                      'color': _selectedColor,
                      'type': 'expense', // Assuming categories added here are always expense
                    };

                    if (coupleModeProvider.isJointMode) {
                      data['couple_id'] = coupleModeProvider.coupleId!;
                      data['user_id'] = userId; // Still associate with user for RLS/tracking
                    } else {
                      data['user_id'] = userId;
                    }

                    try {
                      if (_isEditing) {
                        PostgrestFilterBuilder updateQuery = supabase.from('categories').update(data).match({'id': widget.category!['id']});
                        if (coupleModeProvider.isJointMode) {
                          updateQuery = updateQuery.eq('couple_id', coupleModeProvider.coupleId!); // Ensure updating correct couple category
                        } else {
                          updateQuery = updateQuery.eq('user_id', userId); // Ensure updating correct personal category
                        }
                        await updateQuery;
                      } else {
                        await supabase.from('categories').insert(data);
                      }
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al guardar la categoría: $e')),
                        );
                      }
                    }
                  }
                },
                child: Text(_isEditing ? 'Guardar Cambios' : 'Guardar Categoría'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}