import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/account_detail_page.dart';
import 'package:mi_billetera_digital/pages/add_account_page.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:mi_billetera_digital/widgets/account_logo_widget.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';
import 'package:provider/provider.dart';

class AccountsPage extends StatefulWidget {
  final CoupleMode mode;
  const AccountsPage({super.key, this.mode = CoupleMode.personal});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');
  late Stream<List<Map<String, dynamic>>> _accountsStream;

  static const _defaultAccounts = ['Efectivo', 'Transferencia'];

  @override
  void initState() {
    super.initState();
    _setupStream();
    if (widget.mode == CoupleMode.personal) {
      _ensureDefaultAccounts();
    }
  }

  void _setupStream() {
    final userId = supabase.auth.currentUser!.id;
    final coupleModeProvider = context.read<CoupleModeProvider>();

    List<String> userIds = [userId];
    if (widget.mode == CoupleMode.joint && coupleModeProvider.isCoupleActive) {
      userIds.add(coupleModeProvider.partnerId!);
    }

    _accountsStream = supabase
        .from('accounts')
        .stream(primaryKey: ['id'])
        .inFilter('user_id', userIds)
        .order('name');
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
      floatingActionButton: widget.mode == CoupleMode.personal
          ? FloatingActionButton(
              onPressed: () => _navigateToAddAccount(),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAccountListItem(
    BuildContext context,
    Map<String, dynamic> account,
  ) {
    final nameLower = (account['name'] as String).toLowerCase();
    final isDefault = nameLower == 'efectivo' || nameLower == 'transferencia';
    final holder = (account['holder_full_name'] as String?);
    final isOwnAccount = account['user_id'] == supabase.auth.currentUser!.id;

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
        onLongPress: isOwnAccount && widget.mode == CoupleMode.personal
            ? () {
                _showAccountOptions(context, account);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AccountLogoWidget(
                    accountName: account['name'],
                    iconPath: null,
                  ),
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
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
              leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              title: const Text('Editar Cuenta'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToAddAccount(account: account);
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

  void _navigateToAddAccount({Map<String, dynamic>? account}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddAccountPage(account: account)),
    );
    _setupStream(); // Refresh stream after adding/editing account
  }
}
