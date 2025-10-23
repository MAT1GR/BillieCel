import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/widgets/account_logo_widget.dart';

class AddAccountPage extends StatefulWidget {
  final Map<String, dynamic>? account;

  const AddAccountPage({super.key, this.account});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final formKey = GlobalKey<FormState>();
  late final bool isEditing;
  late final TextEditingController nameController;
  late final TextEditingController balanceController;
  late final TextEditingController holderController;

  static const List<String> suggestions = [
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

  @override
  void initState() {
    super.initState();
    isEditing = widget.account != null;
    nameController = TextEditingController(
      text: isEditing ? widget.account!['name'] : '',
    );
    balanceController = TextEditingController(
      text: isEditing ? (widget.account!['balance'] as num).toString() : '0',
    );
    holderController = TextEditingController(
      text: isEditing ? (widget.account!['holder_full_name'] ?? '') : '',
    );
  }

  Future<void> _saveAccount() async {
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
            'id': widget.account!['id'],
          });
        } else {
          await supabase.from('accounts').insert(data);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cuenta' : 'Nueva Cuenta'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveAccount),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: ListTile(
                                      leading: AccountLogoWidget(
                                        accountName: option,
                                        size: 24,
                                        iconPath: null,
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
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: holderController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre y apellido (opcional)',
                      hintText: 'Ej: Juan Pérez',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAccount,
                      child: Text(
                        isEditing ? 'Guardar Cambios' : 'Crear Cuenta',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
