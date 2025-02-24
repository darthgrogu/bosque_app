import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bosque_app/core/models/arvore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  
  final List<String> _imagensLocais = [
    'assets/images/85466808.jpg',
    'assets/images/93296991.jpg',
    'assets/images/93296992.jpg',
    'assets/images/93296993.jpg',
  ];

  final TextEditingController _searchController = TextEditingController();
  late final MapController _mapController;

  List<Arvore> _arvores = [];
  List<Arvore> _searchResults = [];
  bool _mapReady = false; // Variável para controlar se o mapa está pronto. IMPORTANTE

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadData();
  }

  Future<void> _loadData() async {
    final String jsonString =
        await rootBundle.loadString('assets/arvores.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    final List<Arvore> arvores =
        jsonData.map((item) => Arvore.fromMap(item)).toList();
    setState(() {
      _arvores = arvores;
      //_searchResults = List.from(_arvores);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _arvores.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(-3.097025, -59.986980),
                    initialZoom: 16.5,
                    // onMapReady é a chave!
                    onMapReady: () {
                      
                    },
                    onTap: (_, __) => {},
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.inpa.bosque_app',
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(context),
                      rotate: true,
                    ),
                  ],
                ),
          Positioned(
            //Barra de Busca
            top: 28,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por código/nome...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10.0),
                      ),
                      onSubmitted: (value) {
                        _searchPlant(value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: () {
                      _searchPlant(_searchController.text);
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            //Botao
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                print("Botão flutuante pressionado!");
              },
              backgroundColor: Colors.lightBlue[200],
              child: const Icon(Icons.near_me,
                  color: Color.fromARGB(255, 51, 48, 48)),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    return _arvores.map((arvore) {
      final isSearchResult = _searchResults.contains(arvore);
      final iconColor = isSearchResult ? Colors.blue : Colors.green;
      final iconSize = isSearchResult ? 28.0 : 24.0;

      return Marker(
        key: ValueKey(arvore.id),
        width: 40.0,
        height: 40.0,
        point: LatLng(arvore.latitude, arvore.longitude),
        child: GestureDetector(
          onTap: () {
            _showDetailsBottomSheet(context, arvore);
          },
          child: Icon(Icons.circle, size: iconSize, color: iconColor),
        ),
      );
    }).toList();
  }

  void _showDetailsBottomSheet(BuildContext context, Arvore arvore) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Detalhes da Árvore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_imagensLocais.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 200.0,
                      enlargeCenterPage: true,
                      autoPlay: false,
                      aspectRatio: 16 / 9,
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enableInfiniteScroll: true,
                      viewportFraction: 0.8,
                    ),
                    items: _imagensLocais.map((url) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: AssetImage(url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                Text('Nome Científico: ${arvore.calcFullName}',
                    style: TextStyle(fontSize: 16)),
                Text('Nome Popular: ${arvore.vernacularName ?? 'N/A'}',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Outras informações...'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

// Função de busca (agora com implementação)
  void _searchPlant(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final results = _arvores.where((arvore) {
      return arvore.accession.toLowerCase().contains(lowerCaseQuery) ||
          arvore.calcFullName.toLowerCase().contains(lowerCaseQuery) ||
          (arvore.vernacularName?.toLowerCase().contains(lowerCaseQuery) ??
              false);
    }).toList();

    setState(() {
      _searchResults = results;
      // Move a câmera para o primeiro resultado DEPOIS de redesenhar a tela, e verifica se o mapa está pronto.
      if (_mapReady && _searchResults.isNotEmpty) {
        // Usa _mapReady
        final firstResult = _searchResults[0];
        _mapController.move(
            LatLng(firstResult.latitude, firstResult.longitude), 19);
      }
    });
  }
}
