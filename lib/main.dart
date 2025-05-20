import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bosque_app/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart'; // Para o tipo de dado Position (do stream)
import 'package:flutter_compass/flutter_compass.dart';
import 'app_navigation.dart'; // Usaremos app_navigation.dart
import 'core/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocationService>(
          create: (_) => LocationService(),
        ),
        StreamProvider<Position?>(
          create: (context) {
            final locationService = context.read<LocationService>();
            return locationService.canAccessLocation
                ? locationService.getPositionStream()
                : Stream.value(null);
          },
          initialData: null,
          catchError: (_, error) {
            print("Erro no StreamProvider de Posição: $error");
            return null;
          },
        ),
        StreamProvider<CompassEvent?>(
          create: (context) {
            final locationService = context.read<LocationService>();
            return locationService.getCompassStream();
          },
          initialData: null,
          catchError: (_, error) {
            print("Erro no StreamProvider da Bússola: $error");
            return null;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Jardim Botânico App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: AppNavigation(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
