import 'package:flutter/material.dart';
import 'app_navigation.dart'; // Usaremos app_navigation.dart
import 'core/routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jardim Botânico App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: AppNavigation(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
