import 'dart:async'; // Necessário para Stream
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:provider/provider.dart';
import 'package:bosque_app/core/services/location_service.dart'; // Ajuste o caminho

/// Widget responsável por exibir o marcador de localização do usuário no mapa.
///
/// Ele assume que a permissão de localização já foi tratada por um widget pai
/// (como [LocationPermissionGuard]) e que [LocationService.status] é [LocationStatus.granted]
/// quando este widget é efetivamente renderizado com a intenção de mostrar a localização.
///
/// Utiliza o [LocationService] para obter os streams de posição e bússola,
/// e também para controlar o comportamento de alinhamento do mapa (modo de navegação).
class LocationMarkerLayer extends StatelessWidget {
  const LocationMarkerLayer({super.key});

  @override
  Widget build(BuildContext context) {
    // Acessa o LocationService.
    final locationService = context.watch<LocationService>();

    // Salvaguarda: Se, por alguma razão, este widget for construído e o status
    // não for 'granted', ele não tentará renderizar o CurrentLocationLayer.
    // Isso não deveria acontecer se LocationPermissionGuard for usado corretamente.
    if (locationService.status != LocationStatus.granted ||
        locationService.currentLocationUIMode == LocationUIMode.Off) {
      // Log para depuração, caso ocorra.
      debugPrint(
          "LocationMarkerLayer: Status não é 'granted', retornando SizedBox.shrink(). Status: ${locationService.status}");
      return const SizedBox.shrink();
    }

    // Adapta o stream de posição do LocationService para o formato esperado pelo CurrentLocationLayer.
    // O LocationService já garante que getPositionStream() retorna Stream.empty()
    // se canAccessLocation for false (o que não será o caso aqui, devido à guarda acima).
    final Stream<LocationMarkerPosition?> adaptedPositionStream =
        locationService.getPositionStream().map((position) {
      // 'position' aqui é do tipo Position (geolocator)
      return LocationMarkerPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    }).asBroadcastStream(); // .asBroadcastStream() permite múltiplos ouvintes se necessário

    // Adapta o stream da bússola do LocationService.
    final Stream<LocationMarkerHeading?> adaptedHeadingStream =
        locationService.getCompassStream().map((compassEvent) {
      if (compassEvent == null || compassEvent.heading == null) {
        return null; // Retorna null se não houver dados da bússola
      }
      // 'compassEvent.heading' é em graus.
      // 'LocationMarkerHeading.accuracy' é o ângulo do setor de direção em radianos.
      // A acurácia do flutter_compass (graus +/-) pode ser usada para definir o setor visual.
      // Ex: setor de 30 graus (PI/6 radianos)
      double visualAccuracyRadians =
          (compassEvent.accuracy ?? 30.0) * (3.141592653589793 / 180.0) / 2.0;

      return LocationMarkerHeading(
        heading: compassEvent.heading!, // Graus
        accuracy: visualAccuracyRadians, // Radianos
      );
    }).asBroadcastStream();

    // Retorna o CurrentLocationLayer configurado.
    // As propriedades de alinhamento (mapAlignPosition, mapAlignDirection, navigationAlignCommandStream)
    // são controladas pelo LocationService, permitindo que um botão externo
    // (a ser implementado) altere o modo de navegação.
    return CurrentLocationLayer(
      alignPositionStream: locationService.navigationAlignCommandStream,
      alignPositionOnUpdate: locationService.mapAlignPosition,
      alignDirectionOnUpdate: locationService.mapAlignDirection,
      positionStream: adaptedPositionStream,
      headingStream: adaptedHeadingStream,
      style: LocationMarkerStyle(
        markerSize: const Size(22, 22), // Tamanho do marcador principal
        accuracyCircleColor:
            Colors.blue.withOpacity(0.15), // Cor do círculo de precisão
        headingSectorColor:
            Colors.blue.withOpacity(0.3), // Cor do setor de direção
        headingSectorRadius: 60, // Raio do setor de direção
        marker: DefaultLocationMarker(
          color: Colors.blue.shade700, // Cor do pino do marcador
          child: const Icon(
            // Ícone dentro do pino
            Icons.navigation,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
