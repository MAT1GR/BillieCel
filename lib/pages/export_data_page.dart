import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  bool _isLoading = false;

  Future<void> _exportTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('transactions')
          .select()
          .order('date', ascending: false);

      if (response.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No hay transacciones para exportar.')),
          );
        }
        return;
      }

      // Fetch categories and accounts for mapping
      final categoriesResponse = await supabase.from('categories').select();
      final accountsResponse = await supabase.from('accounts').select();

      final Map<String, String> categoryNames = {
        for (var category in categoriesResponse)
          category['id'].toString(): category['name'] as String
      };
      final Map<String, String> accountNames = {
        for (var account in accountsResponse)
          account['id'].toString(): account['name'] as String
      };

      List<List<dynamic>> rows = [];
      // Add header row
      rows.add([
        'ID',
        'Monto',
        'Descripción',
        'Fecha',
        'Categoría',
        'Cuenta',
        'Tipo'
      ]);

      for (var transaction in response) {
        final categoryName =
            categoryNames[transaction['category_id'].toString()] ?? 'Desconocida';
        final accountName =
            accountNames[transaction['account_id'].toString()] ?? 'Desconocida';

        rows.add([
          transaction['id'],
          transaction['amount'],
          transaction['description'],
          transaction['date'],
          categoryName,
          accountName,
          transaction['type'],
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/transactions.csv';
      final file = File(path);
      await file.writeAsString(csv);

      if (mounted) {
        await Share.shareXFiles([XFile(path)],
            text: 'Aquí están tus transacciones.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transacciones exportadas y compartidas.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar transacciones: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Datos'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opciones de Exportación',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _isLoading ? null : _exportTransactions,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined,
                              size: 40, color: Colors.blueAccent),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exportar Transacciones',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Exporta todo tu historial de transacciones a un archivo CSV.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.download_for_offline_outlined,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    SizedBox(height: 20),
                    Text(
                      'Exportando datos...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
