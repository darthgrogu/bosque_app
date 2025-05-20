import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:provider/provider.dart';

import 'package:bosque_app/features/map/widgets/example_popup.dart';
import 'package:bosque_app/core/models/arvore.dart';
import 'package:bosque_app/features/map/screens/add_tree_screen.dart';

// Importações para localização
import 'package:bosque_app/core/services/location_service.dart'; // Ajuste o caminho
import 'package:bosque_app/core/widgets/location_permission_guard.dart'; // Importe o guardião
import 'package:bosque_app/features/map/widgets/location_marker_layer.dart'; // Importe a camada de localização
import 'package:bosque_app/features/map/widgets/map_control_button.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

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
  late final PopupController _popupController;

  List<Arvore> _arvores = [];
  List<Arvore> _searchResults = [];
  bool _mapIsReady = false;

  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addPostFrameCallback((_) {
    //  Future.delayed(Duration(seconds: 2), () {
    //    _exibirBoasVindas(context);
    //  });
    //});
    _mapController = MapController();
    _popupController = PopupController();
    _loadData();
  }

  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          (_arvores.isEmpty && !_mapIsReady)
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(-3.097025, -59.986980),
                    initialZoom: 16.5,
                    onMapReady: () {
                      // setState é importante aqui se alguma lógica de UI depende
                      // de o mapa estar pronto (ex: mover o mapa após busca).
                      if (mounted) {
                        // Verifica se o widget ainda está na árvore
                        setState(() {
                          _mapIsReady = true;
                        });
                      }
                      debugPrint("Mapa pronto!");
                    },
                    onTap: (_, __) => _popupController.hideAllPopups(),
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture) {
                        // Notifica o LocationService que o usuário interagiu (moveu/deu zoom) no mapa.
                        // Isso permite que o LocationService mude o modo de seguimento, se estiver ativo.
                        // Usamos 'read' pois é uma ação e não precisamos reconstruir a MapPage por isso.
                        context.read<LocationService>().userInteractedWithMap();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.inpa.bosque_app',
                    ),
                    //MarkerLayer(
                    //  markers: _buildMarkers(context),
                    //  rotate: true,
                    //),
                    if (_mapIsReady)
                      PopupMarkerLayer(
                        options: PopupMarkerLayerOptions(
                          markers: _buildMarkers(context),
                          popupController: _popupController,
                          popupDisplayOptions: PopupDisplayOptions(
                            builder: (BuildContext context, Marker marker) =>
                                ExamplePopup(marker, _arvores, _popupController,
                                    _showDetailsBottomSheet),
                            animation: PopupAnimation.fade(
                                duration: Duration(milliseconds: 250)),
                          ),
                        ),
                      ),
                    if (_mapIsReady)
                      LocationPermissionGuard(
                        child: const LocationMarkerLayer(),
                      ),
                  ],
                ),
          // Caixa de busca
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar por código/nome...',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                        ),
                        onChanged: (value) {
                          // Opcional: busca em tempo real enquanto digita (com debounce)
                          // Por ora, a busca é feita no onSubmitted ou no botão.
                        },
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _searchPlant(value.trim());
                          } else {
                            // Limpa a busca se o campo estiver vazio ao submeter
                            _searchPlant("");
                          }
                        },
                      ),
                    ),
                    // Botão para limpar a busca
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchPlant("");
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Botão de controle do mapa
          Positioned(
            // Ajuste 'bottom' para que fique acima do seu SpeedDial ou onde preferir.
            // Se o SpeedDial tiver altura X e espaçamento Y, este pode ser bottom: X + Y + algum_padding.
            // Exemplo: SpeedDial tem cerca de 56 (FAB) + 15 (spacing) * N filhos.
            // Vamos colocar a 90 por enquanto, ajuste conforme necessário.
            bottom: 95, // Ajuste este valor!
            right: 20.0,
            child: const MapControlButton(), // Adiciona o novo botão
          ),
          //SpeedDial
          Positioned(
            bottom: 20,
            right: 20.0,
            child: Column(
              children: [
                SpeedDial(
                  icon: Icons.add,
                  activeIcon: Icons.close,
                  backgroundColor: Colors.purple.shade800,
                  foregroundColor: Colors.white,
                  overlayColor: Colors.black,
                  overlayOpacity: 0.4,
                  spacing: 15,
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.park),
                      label: 'Árvore',
                      shape: CircleBorder(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddTreeScreen()),
                        );
                      },
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.remove_red_eye),
                      shape: CircleBorder(),
                      label: 'Evento',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/arvores.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      // Adicionando um pequeno delay para simular carregamento e ver o CircularProgressIndicator
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return; // Verifica se o widget ainda está montado
      final List<Arvore> arvores =
          jsonData.map((item) => Arvore.fromMap(item)).toList();

      setState(() {
        _arvores = arvores;
        _searchResults = List.from(_arvores);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados das árvores: $e')),
      );
    }
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final random = Random();

    final List<String> _treeIcons = [
      'assets/images/tree1.png',
      'assets/images/tree2.png',
      'assets/images/tree3.png',
      'assets/images/tree4.png',
      'assets/images/tree5.png',
      'assets/images/tree6.png',
    ];

    if (_treeIcons.isEmpty) return [];

    return _arvores.map((arvore) {
      // Se _searchResults está vazio após uma busca sem resultados,
      // ou se nenhuma busca foi feita e você quer destacar apenas resultados de busca.
      // Para o comportamento inicial: se _searchResults está vazio, significa NENHUMA busca ativa ainda.
      // Nesse caso, todos os marcadores são "normais".
      // Quando uma busca é feita, _searchResults é preenchido.

      // Se uma busca foi realizada (mesmo que vazia), e a árvore não está nos resultados
      final bool isSearchResultContext = _searchController.text.isNotEmpty;
      final bool isInSearchResults = _searchResults.contains(arvore);
      final bool shouldBeDimmed = isSearchResultContext && !isInSearchResults;

      final iconSize = isInSearchResults && isSearchResultContext ? 60.0 : 30.0;
      final selectedImage = _treeIcons.isNotEmpty
          ? _treeIcons[random.nextInt(_treeIcons.length)]
          : 'assets/images/tree1.png'; // Fallback

      return Marker(
        key: ValueKey(arvore.id ?? arvore.accession), // Garanta uma chave única
        width: 50.0,
        height: iconSize,
        point: LatLng(arvore.latitude, arvore.longitude),
        child: GestureDetector(
          onLongPress: () {
            _showDetailsBottomSheet(context, arvore);
          },
          child: Opacity(
            opacity: shouldBeDimmed ? 0.3 : 1.0,
            child: Image.asset(
              selectedImage,
              width: iconSize,
              height: iconSize,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 20),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ignore: unused_element
  void _exibirBoasVindas(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, // Permite transparência para a animação
        pageBuilder: (context, animation, secondaryAnimation) =>
            BoasVindasScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation, // Anima a opacidade
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 500), // Duração da animação
      ),
    );
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

  void _searchPlant(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final results = _arvores.where((arvore) {
      return (arvore.accession.toLowerCase().contains(lowerCaseQuery)) ||
          arvore.calcFullName.toLowerCase().contains(lowerCaseQuery) ||
          (arvore.vernacularName?.toLowerCase().contains(lowerCaseQuery) ??
              false);
    }).toList();

    setState(() {
      _searchResults = results;
      if (_mapIsReady && _searchResults.isNotEmpty) {
        final firstResult = _searchResults.first;
        _mapController.move(LatLng(firstResult.latitude, firstResult.longitude),
            19.0); // Zoom mais alto para o resultado
      } else if (_mapIsReady && query.isNotEmpty && _searchResults.isEmpty) {
        // Opcional: Informar ao usuário que nada foi encontrado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nenhuma árvore encontrada com este termo.')),
        );
      }
    });
  }
}

class BoasVindasScreen extends StatefulWidget {
  @override
  _BoasVindasScreenState createState() => _BoasVindasScreenState();
}

class _BoasVindasScreenState extends State<BoasVindasScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // Cor de fundo opaca
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  Center(
                      child: Text('Bem-vindo ao nosso aplicativo! - Tela 1')),
                  Center(
                      child: Text('Descubra novas funcionalidades. - Tela 2')),
                  Center(
                      child: Text(
                          'Explore o mapa e encontre locais interessantes. - Tela 3')),
                  Center(
                      child: Text('Personalize suas preferências. - Tela 4')),
                  Center(child: Text('Aproveite ao máximo! - Tela 5')),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text('Anterior'),
                  ),
                if (_currentPage < 4)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text('Próximo'),
                  ),
                if (_currentPage == 4)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Volta para a tela do mapa
                    },
                    child: Text('Vamos lá!'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Initialize and fetch user location
