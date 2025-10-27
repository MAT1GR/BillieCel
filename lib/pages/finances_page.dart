import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/pages/finances_content_page.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';

class FinancesPage extends StatefulWidget {
  const FinancesPage({super.key});

  @override
  State<FinancesPage> createState() => _FinancesPageState();
}

class _FinancesPageState extends State<FinancesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      final coupleModeProvider = context.read<CoupleModeProvider>();
      if (_tabController.index == 0) {
        coupleModeProvider.setMode(CoupleMode.personal);
      } else {
        coupleModeProvider.setMode(CoupleMode.joint);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupleModeProvider = context.watch<CoupleModeProvider>();

    // Set initial mode based on the provider's state when the widget builds
    final initialIndex = coupleModeProvider.isJointMode ? 1 : 0;
    if (_tabController.index != initialIndex) {
      _tabController.index = initialIndex;
    }

    if (coupleModeProvider.isCoupleActive) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Finanzas'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Personal'),
              Tab(text: 'Pareja'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            FinancesContentPage(),
            FinancesContentPage(),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Finanzas'),
        ),
        body: const FinancesContentPage(),
      );
    }
  }
}
