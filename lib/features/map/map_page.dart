import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bosque_app/core/models/arvore.dart';

class MapPage extends StatelessWidget {
  MapPage({Key? key}) : super(key: key);

  final List<Arvore> _arvores = [
    // Seus dados de exemplo
    Arvore(
      id: 1,
      nomeCientifico: 'Handroanthus serratifolius',
      nomePopular: 'Ipê-amarelo',
      latitude: -3.0976,
      longitude: -59.9860,
      fotos: [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Handroanthus_serratifolius_01.jpg/800px-Handroanthus_serratifolius_01.jpg'
      ],
    ),
    Arvore(
      id: 2,
      nomeCientifico: 'Ceiba pentandra',
      nomePopular: 'Samaúma',
      latitude: -3.0980,
      longitude: -59.9855,
      fotos: ['https://upload.wikimedia.org/wikipedia/commons/9/95/Kapok_tree_-_panoramio.jpg'],
    ),
    Arvore(
      id: 3,
      nomeCientifico: 'Hymenaea courbaril',
      nomePopular: 'Jatobá',
      latitude: -3.0973,
      longitude: -59.9867,
      fotos: ['https://upload.wikimedia.org/wikipedia/commons/1/1e/Hymenaea_courbaril_-_Jatob%C3%A1.jpg'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(-3.0976310, -59.98608),
        initialZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.suaempresa.seujardimbotanico',
        ),
        MarkerLayer( // Apenas MarkerLayer
          markers: _buildMarkers(context), // Passa o context para _buildMarkers
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(BuildContext context) { // Recebe o context
    return _arvores.map((arvore) {
      return Marker(
        key: ValueKey(arvore.id),
        width: 80.0,
        height: 80.0,
        point: LatLng(arvore.latitude, arvore.longitude),
        child: GestureDetector(
          onTap: () {
            _showDetailsBottomSheet(context, arvore); // Chama o bottom sheet
          },
          child: const Icon(Icons.location_on, size: 40, color: Colors.green),
        ),
      );
    }).toList();
  }

  // A função _showDetailsBottomSheet permanece inalterada
  void _showDetailsBottomSheet(BuildContext context, Arvore arvore) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Detalhes da Árvore',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Nome Científico: ${arvore.nomeCientifico}'),
            Text(
                'Nome Popular: ${arvore.nomePopular ?? 'N/A'}'), // Trata nome popular nulo
            const SizedBox(height: 10),
            SizedBox(
              height: 150, // Altura para o carrossel de imagens
              child: PageView.builder(
                // PageView para visualizar as imagens.
                itemCount: arvore.fotos.length,
                pageSnapping: true,
                itemBuilder: (context, pagePosition) {
                  return Container(
                    // Exibe a imagem
                      margin: const EdgeInsets.all(8),
                      child: Image.network(arvore.fotos[pagePosition],
                          fit: BoxFit.cover));
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Outras informações...'), // Placeholder
            ),
          ],
        );
      },
    );
  }
}