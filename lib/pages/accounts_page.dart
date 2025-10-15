import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';
import 'package:mi_billetera_digital/pages/account_detail_page.dart';
import 'package:mi_billetera_digital/widgets/account_logo_widget.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');
  late final Stream<List<Map<String, dynamic>>> _accountsStream;

  static const _defaultAccounts = ['Efectivo', 'Transferencia'];

  @override
  void initState() {
    super.initState();
    _accountsStream = supabase
        .from('accounts')
        .stream(primaryKey: ['id'])
        .order('name');
    _ensureDefaultAccounts();
  }

  Future<void> _ensureDefaultAccounts() async {
    final userId = supabase.auth.currentUser!.id;

    final rows = await supabase
        .from('accounts')
        .select('id,name')
        .eq('user_id', userId);

    final existing = (rows as List)
        .map((e) => (e['name'] as String).toLowerCase())
        .toSet();

    final toInsert = <Map<String, dynamic>>[];
    for (final name in _defaultAccounts) {
      if (!existing.contains(name.toLowerCase())) {
        toInsert.add({'name': name, 'balance': 0.0, 'user_id': userId});
      }
    }

    if (toInsert.isNotEmpty) {
      await supabase
          .from('accounts')
          .upsert(toInsert, onConflict: 'user_id,name');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cuentas')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _accountsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmer();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          var accounts = (snapshot.data ?? []).toList();

          if (accounts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Aún no tienes cuentas.\n¡Usa el botón + para crear la primera!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.subtextColor, fontSize: 16),
                ),
              ),
            );
          }

          accounts.sort((a, b) {
            int rank(String name) {
              final n = name.toLowerCase();
              if (n == 'efectivo') return 0;
              if (n == 'transferencia') return 1;
              return 2;
            }

            final ra = rank(a['name']);
            final rb = rank(b['name']);
            if (ra != rb) return ra.compareTo(rb);
            return (a['name'] as String).compareTo(b['name'] as String);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              return _buildAccountListItem(context, accounts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAccountListItem(
    BuildContext context,
    Map<String, dynamic> account,
  ) {
    final nameLower = (account['name'] as String).toLowerCase();
    final isDefault = nameLower == 'efectivo' || nameLower == 'transferencia';
    final holder = (account['holder_full_name'] as String?);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AccountDetailPage(account: account),
            ),
          );
        },
        onLongPress: () {
          _showAccountOptions(context, account);
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AccountLogoWidget(accountName: account['name']),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account['name'],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (holder != null && holder.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              holder,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.75),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(
                      (account['balance'] as num).toDouble(),
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              if (isDefault) ...[
                const SizedBox(height: 10),
                _AccountHistoryPreview(
                  accountId: account['id'] as String,
                  currencyFormat: currencyFormat,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountOptions(BuildContext context, Map<String, dynamic> account) {
    final nameLower = (account['name'] as String).toLowerCase();
    final isDefault = nameLower == 'efectivo' || nameLower == 'transferencia';

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Editar Cuenta'),
              onTap: () {
                Navigator.of(context).pop();
                _showAccountDialog(account: account);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: isDefault ? Colors.grey : Colors.redAccent,
              ),
              title: Text(
                isDefault ? 'Eliminar Cuenta (bloqueado)' : 'Eliminar Cuenta',
                style: TextStyle(
                  color: isDefault ? Colors.grey : Colors.redAccent,
                ),
              ),
              onTap: isDefault
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _deleteAccount(context, account);
                    },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(
    BuildContext context,
    Map<String, dynamic> account,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Seguro que quieres eliminar la cuenta "${account['name']}"? '
          'Las transacciones asociadas no se borrarán, pero quedarán sin cuenta asignada.',
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

    if (confirm == true && mounted) {
      try {
        await supabase.from('accounts').delete().match({'id': account['id']});
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Cuenta eliminada')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  Future<void> _showAccountDialog({Map<String, dynamic>? account}) async {
    final formKey = GlobalKey<FormState>();
    final isEditing = account != null;
    final nameController = TextEditingController(
      text: isEditing ? account['name'] : '',
    );
    final balanceController = TextEditingController(
      text: isEditing ? (account['balance'] as num).toString() : '0',
    );
    final holderController = TextEditingController(
      text: isEditing ? (account['holder_full_name'] ?? '') : '',
    );

    const List<String> suggestions = [
      'Mercado Pago',
      'Ualá',
      'Naranja X',
      'Brubank',
      'Banco Nación',
      'Banco Galicia',
      'Banco Provincia',
      'Santander',
      'BBVA',
      'Banco Macro',
      'ICBC',
      'HSBC',
      'Banco Credicoop',
      'Banco Patagonia',
      'Banco Ciudad',
      'Banco Comafi',
      'Banco Hipotecario',
      'Efectivo',
      'Transferencia',
    ];

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Cuenta' : 'Nueva Cuenta'),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 24.0,
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: nameController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final q = textEditingValue.text.trim();
                      if (q.isEmpty) return suggestions;
                      return suggestions.where(
                        (o) => o.toLowerCase().contains(q.toLowerCase()),
                      );
                    },
                    onSelected: (sel) {
                      nameController.text = sel;
                      FocusScope.of(context).nextFocus();
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          if (controller.text != nameController.text) {
                            controller.text = nameController.text;
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          }
                          focusNode.addListener(() {
                            if (focusNode.hasFocus &&
                                controller.text.trim().isEmpty) {
                              controller.text = ' ';
                              controller.selection = TextSelection.collapsed(
                                offset: controller.text.length,
                              );
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                controller.text = '';
                                controller.selection =
                                    const TextSelection.collapsed(offset: 0);
                              });
                            }
                          });
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la Cuenta',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Ingresa un nombre'
                                : null,
                            onChanged: (v) => nameController.text = v,
                            onTap: () {
                              if (controller.text.trim().isEmpty) {
                                controller.text = ' ';
                                controller.selection = TextSelection.collapsed(
                                  offset: controller.text.length,
                                );
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  controller.text = '';
                                  controller.selection =
                                      const TextSelection.collapsed(offset: 0);
                                });
                              }
                            },
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (context, i) {
                                final option = options.elementAt(i);
                                // ===== CAMBIO PRINCIPAL AQUÍ =====
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    // Añadimos Padding para dar más altura
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: ListTile(
                                      leading: AccountLogoWidget(
                                        accountName: option,
                                        size: 24,
                                      ),
                                      title: Text(option),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: holderController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre y apellido (opcional)',
                      hintText: 'Ej: Juan Pérez',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: balanceController,
                    decoration: InputDecoration(
                      labelText: isEditing ? 'Saldo Actual' : 'Saldo Inicial',
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          double.tryParse(value) == null) {
                        return 'Ingresa un saldo válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final data = <String, dynamic>{
                    'name': nameController.text.trim(),
                    'balance': double.parse(balanceController.text),
                    'user_id': supabase.auth.currentUser!.id,
                    'holder_full_name': holderController.text.trim().isEmpty
                        ? null
                        : holderController.text.trim(),
                  };
                  try {
                    if (isEditing) {
                      await supabase.from('accounts').update(data).match({
                        'id': account['id'],
                      });
                    } else {
                      await supabase.from('accounts').insert(data);
                    }
                    if (mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al guardar: $e')),
                      );
                    }
                  }
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      },
    );
  }
}

class _AccountHistoryPreview extends StatelessWidget {
  final String accountId;
  final NumberFormat currencyFormat;

  const _AccountHistoryPreview({
    required this.accountId,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final stream = supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('account_id', accountId)
        .order('created_at', ascending: false)
        .limit(10);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final txs = snapshot.data ?? [];
        if (txs.isEmpty) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sin movimientos',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          );
        }

        return Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Últimos movimientos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            ...txs.take(5).map((t) {
              final isIncome = t['type'] == 'income';
              final amount = (t['amount'] as num).toDouble();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    Icon(
                      isIncome ? Icons.north_west : Icons.south_east,
                      size: 16,
                      color: isIncome ? Colors.green : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (t['description'] as String?)?.trim().isNotEmpty == true
                            ? t['description']
                            : 'Movimiento',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(amount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (txs.length > 5)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ver más…',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                ),
              ),
          ],
        );
      },
    );
  }
}
