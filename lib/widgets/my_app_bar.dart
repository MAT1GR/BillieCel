import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const MyAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  State<MyAppBar> createState() => _MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MyAppBarState extends State<MyAppBar> {
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoAssetPath =
        isDarkMode ? 'assets/images/oscuro.png' : 'assets/images/logo.png';

    final coupleModeProvider = context.watch<CoupleModeProvider>();

    List<Widget> appBarActions = [...(widget.actions ?? [])];

    if (coupleModeProvider.isCoupleActive) {
      appBarActions.add(
        Row(
          children: [
            Text(
              coupleModeProvider.isJointMode ? 'Conjunto' : 'Personal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
            Switch(
              value: coupleModeProvider.isJointMode,
              onChanged: (value) {
                coupleModeProvider.setMode(
                  value ? CoupleMode.joint : CoupleMode.personal,
                );
              },
              activeColor: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      );
    }

    return AppBar(
      leading: !canPop
          ? FutureBuilder(
              future: precacheImage(
                AssetImage(logoAssetPath),
                context,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.asset(logoAssetPath),
                    ),
                  );
                } else {
                  return const SizedBox(); // Show an empty box while loading
                }
              },
            )
          : null,
      title: Text(widget.title),
      actions: appBarActions,
      centerTitle: false,
    );
  }
}