import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const MyAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return AppBar(
      leading: !canPop
          ? FutureBuilder(
              future: precacheImage(
                const AssetImage('assets/images/logo.png'),
                context,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.asset('assets/images/logo.png'),
                    ),
                  );
                } else {
                  return const SizedBox(); // Show an empty box while loading
                }
              },
            )
          : null,
      title: Text(title),
      actions: actions,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}