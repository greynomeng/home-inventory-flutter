import 'package:flutter/material.dart';
import 'package:home_inventory/screens/home_screen.dart';
import 'package:home_inventory/theme/app_theme.dart';

class HomeInventoryApp extends StatelessWidget {
  const HomeInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Inventory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
