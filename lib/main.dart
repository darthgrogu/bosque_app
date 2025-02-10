import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bosque Da Ciência APP',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Bosque da Ciência'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;

  void _searchPlant() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.green,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.public),
            icon: Icon(Icons.public),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Espécies',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('2'),
              child: Icon(Icons.newspaper),
            ),
            label: 'News',
          ),
        ],
      ),
      body: Center(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(-3.0976310, -59.98608),
            initialZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _searchPlant,
          tooltip: 'Increment',
          child: const Icon(Icons.search),
          shape),
    );
  }
}
