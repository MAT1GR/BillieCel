import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/pages/finances_content_page.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';

class FinancesPage extends StatelessWidget {
  const FinancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final coupleModeProvider = context.watch<CoupleModeProvider>();

    if (coupleModeProvider.isCoupleActive) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Finanzas'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Personal'),
                Tab(text: 'Pareja'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              FinancesContentPage(mode: CoupleMode.personal),
              FinancesContentPage(mode: CoupleMode.joint),
            ],
          ),
        ),
      );
    } else {
      return const FinancesContentPage(mode: CoupleMode.personal);
    }
  }
}
