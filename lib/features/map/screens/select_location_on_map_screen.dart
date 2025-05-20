// lib/features/map/screens/select_on_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelectOnMapScreen extends StatefulWidget {
  final LatLng initialCenter;

  const SelectOnMapScreen({
    super.key,
    this.initialCenter =
        const LatLng(-3.1190, -60.0217), // Ponto inicial padrão
  });

  @override
  State<SelectOnMapScreen> createState() => _SelectOnMapScreenState();
}

class _SelectOnMapScreenState extends State<SelectOnMapScreen> {
  late MapController _mapController;
  // ATIVADO: Variável de estado para armazenar e exibir o centro atual do mapa
  late LatLng _currentMapCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Inicializa _currentMapCenter com o valor passado ou o padrão
    _currentMapCenter = widget.initialCenter;

    // Opcional: Se precisar de atualizações mais frequentes ou de outros eventos do mapa,
    // você pode usar o mapEventStream. Para apenas a posição central,
    // onPositionChanged no MapOptions é geralmente suficiente e mais simples.
    /*
    _mapController.mapEventStream.listen((MapEvent mapEvent) {
      if (mapEvent is MapEventMove || mapEvent is MapEventCameraMove || mapEvent is MapEventScrollWheelZoom) {
        if (mounted) {
          setState(() {
            _currentMapCenter = _mapController.camera.center;
          });
        }
      }
    });
    */
  }

  @override
  void dispose() {
    // _mapController.dispose(); // Verifique a documentação da sua versão do flutter_map
    super.dispose();
  }

  void _confirmSelection() {
    // Usa _currentMapCenter que já está sendo atualizado,
    // ou pode pegar diretamente do controller se preferir, para garantir o valor mais recente.
    // Pegar do controller no momento da confirmação é mais seguro.
    final LatLng selectedCenter = _mapController.camera.center;
    Navigator.pop(context, selectedCenter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione a Localização'),
        backgroundColor: Colors.green[700], // Consistente com AddTreeScreen
        foregroundColor: Colors.white, // Para o texto e ícones da AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom:
                  17.5, // Aumentei um pouco o zoom inicial para mais precisão
              minZoom: 5,
              maxZoom: 22,
              // ATIVADO: Callback para atualizar _currentMapCenter quando o mapa é movido
              onPositionChanged: (position, hasGesture) {
                // Atualiza o _currentMapCenter sempre que a posição da câmera do mapa mudar.
                // 'position.center' é o LatLng no centro da visualização do mapa.
                if (mounted && position.center != null) {
                  setState(() {
                    _currentMapCenter = position.center!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.inpa.bosque_app',
              ),
            ],
          ),

          // Marcador Fixo Centralizado (como antes)
          IgnorePointer(
            child: Icon(
              Icons.location_pin,
              color: Colors.red[700],
              size: 50,
              shadows: const [
                Shadow(
                    blurRadius: 8.0,
                    color: Colors.black54,
                    offset: Offset(0, 3.0)),
              ],
            ),
          ),

          // NOVO: Widget de Texto para exibir as coordenadas em tempo real
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 2,
              color: Colors.white.withOpacity(0.85), // Fundo semitransparente
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Text(
                  // Usa toStringAsFixed para controlar o número de casas decimais
                  'Lat: ${_currentMapCenter.latitude.toStringAsFixed(6)}, Lon: ${_currentMapCenter.longitude.toStringAsFixed(6)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          ),

          // Botão para Confirmar a Seleção (como antes, mas ajustei o bottom padding)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('CONFIRMAR ESTA LOCALIZAÇÃO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _confirmSelection,
            ),
          ),
        ],
      ),
    );
  }
}
