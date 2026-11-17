import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Contenedor de las 4 pestañas con la barra de navegación Material 3.
/// Cada pestaña conserva su pila y su scroll (IndexedStack de go_router).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore_rounded),
      label: 'Mapa',
    ),
    NavigationDestination(
      icon: Icon(Icons.sports_esports_outlined),
      selectedIcon: Icon(Icons.sports_esports_rounded),
      label: 'Juegos',
    ),
    NavigationDestination(
      icon: Icon(Icons.military_tech_outlined),
      selectedIcon: Icon(Icons.military_tech_rounded),
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x140B3B66),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          destinations: _destinations,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.blueSoft,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            // Tocar la pestaña activa vuelve a su raíz.
            shell.goBranch(i, initialLocation: i == shell.currentIndex);
          },
        ),
      ),
    );
  }
}
