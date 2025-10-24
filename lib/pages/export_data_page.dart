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
      final response = await supabase.from('transactions').select().order('date', ascending: false);

      if (response.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions to export.')),
          );
        }
        return;
      }

      // Fetch categories and accounts for mapping
      final categoriesResponse = await supabase.from('categories').select();
      final accountsResponse = await supabase.from('accounts').select();

      final Map<String, String> categoryNames = {
        for (var category in categoriesResponse) category['id'].toString(): category['name'] as String
      };
      final Map<String, String> accountNames = {
        for (var account in accountsResponse) account['id'].toString(): account['name'] as String
      };

      List<List<dynamic>> rows = [];
      // Add header row
      rows.add(['ID', 'Amount', 'Description', 'Date', 'Category', 'Account', 'Type']);

      for (var transaction in response) {
        final categoryName = categoryNames[transaction['category_id'].toString()] ?? 'Unknown';
        final accountName = accountNames[transaction['account_id'].toString()] ?? 'Unknown';

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
        await Share.shareXFiles([XFile(path)], text: 'Here are your transactions.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transactions exported and shared.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting transactions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _exportTransactions,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.download),
          label: Text(_isLoading ? 'Exporting...' : 'Export Transactions to CSV'),
        ),
      ),
    );
  }
}
