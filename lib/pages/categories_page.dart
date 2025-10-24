import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/add_category_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final Stream<List<Map<String, dynamic>>> _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream = supabase
        .from('categories')
        .stream(primaryKey: ['id']).order('name');
    _ensureDefaultCategories();
  }

  Future<void> _ensureDefaultCategories() async {
    final userId = supabase.auth.currentUser!.id;
    final categories = await supabase.from('categories').select().eq('user_id', userId);
    if (categories.isEmpty) {
      final List<Map<String, dynamic>> defaultCategories = [
        {'user_id': userId, 'name': 'Comida', 'icon': 'fastfood', 'color': '0xFFD32F2F'},
        {'user_id': userId, 'name': 'Transporte', 'icon': 'directions_bus', 'color': '0xFF0288D1'},
        {'user_id': userId, 'name': 'Alojamiento', 'icon': 'hotel', 'color': '0xFF388E3C'},
        {'user_id': userId, 'name': 'Salud', 'icon': 'healing', 'color': '0xFFFBC02D'},
        {'user_id': userId, 'name': 'Entretenimiento', 'icon': 'theaters', 'color': '0xFF7B1FA2'},
        {'user_id': userId, 'name': 'Compras', 'icon': 'shopping_cart', 'color': '0xFFF57C00'},
        {'user_id': userId, 'name': 'Hogar', 'icon': 'home', 'color': '0xFF5D4037'},
        {'user_id': userId, 'name': 'Educación', 'icon': 'school', 'color': '0xFF303F9F'},
        {'user_id': userId, 'name': 'Mascotas', 'icon': 'pets', 'color': '0xFF616161'},
        {'user_id': userId, 'name': 'Gimnasio', 'icon': 'fitness_center', 'color': '0xFFE64A19'},
        {'user_id': userId, 'name': 'Regalos', 'icon': 'card_giftcard', 'color': '0xFFC2185B'},
        {'user_id': userId, 'name': 'Sueldo', 'icon': 'attach_money', 'color': '0xFF689F38'},
        {'user_id': userId, 'name': 'Ahorros', 'icon': 'savings', 'color': '0xFF1976D2'},
        {'user_id': userId, 'name': 'Servicios', 'icon': 'lightbulb', 'color': '0xFFFFA000'},
        {'user_id': userId, 'name': 'Facturas', 'icon': 'receipt', 'color': '0xFF0097A7'},
        {'user_id': userId, 'name': 'Otros', 'icon': 'category', 'color': '0xFF455A64'},
      ];
      await supabase.from('categories').insert(defaultCategories);
    }
  }

  // Mapa de iconos para convertir de String a IconData
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _categoriesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final categories = snapshot.data ?? [];

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: Icon(
                  _iconMap[category['icon']] ?? Icons.category,
                  color: Color(int.parse(category['color']?.substring(2) ?? 'FFFFFFFF', radix: 16)),
                ),
                title: Text(category['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddCategoryPage(category: category),
                          ),
                        );
                        _categoriesStream = supabase.from('categories').stream(primaryKey: ['id']).order('name'); // Refresh stream
                      },
                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirmar eliminación'),
                                            content: Text(
                                              '¿Seguro que quieres eliminar la categoría "${category['name']}"?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          try {
                                            await supabase.from('categories').delete().match({'id': category['id']});
                                            _categoriesStream = supabase.from('categories').stream(primaryKey: ['id']).order('name'); // Refresh stream
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error al eliminar la categoría: $e')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddCategoryPage()),
          );
          _categoriesStream = supabase.from('categories').stream(primaryKey: ['id']).order('name'); // Refresh stream
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
