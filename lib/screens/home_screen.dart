import 'package:flutter/material.dart';
import 'package:home_inventory/screens/locations_screen.dart';

import '../services/api_service.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();

  static const List<_NavigationDestination> _destinations = [
    _NavigationDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _NavigationDestination(
      label: 'Items',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    _NavigationDestination(
      label: 'Categories',
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
    ),
    _NavigationDestination(
      label: 'Locations',
      icon: Icons.place_outlined,
      selectedIcon: Icons.place,
    ),
    _NavigationDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final body = _buildPage();

        return Scaffold(
          appBar: AppBar(title: const Text('Home Inventory')),
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _selectDestination,
                      labelType: NavigationRailLabelType.all,
                      destinations: _destinations.map((destination) {
                        return NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        );
                      }).toList(),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  destinations: _destinations.map((destination) {
                    return NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return const _PlaceholderPage(
          title: 'Dashboard',
          message: 'Your home inventory at a glance.',
          icon: Icons.dashboard_outlined,
        );
      case 1:
        return const _PlaceholderPage(
          title: 'Items',
          message: 'Your inventory items will appear here.',
          icon: Icons.inventory_2_outlined,
        );
      case 2:
        return CategoriesScreen(apiService: _apiService);

      case 3:
        return LocationsScreen(apiService: _apiService);

      case 4:
        return const _PlaceholderPage(
          title: 'Settings',
          message: 'Application settings will appear here.',
          icon: Icons.settings_outlined,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _NavigationDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _PlaceholderPage({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
