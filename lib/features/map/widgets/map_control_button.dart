// ignore_for_file: unreachable_switch_default

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bosque_app/core/services/location_service.dart';

/// Um botão flutuante que controla os modos de visualização da localização no mapa.
///
/// Ele observa o [LocationService] para:
/// - Exibir o ícone apropriado com base no [LocationUIMode] atual.
/// - Chamar [LocationService.cycleLocationMode()] ao ser pressionado.
class MapControlButton extends StatelessWidget {
  const MapControlButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Observa o LocationService para reagir às mudanças de modo e status.
    final locationService = context.watch<LocationService>();

    IconData iconData;
    String tooltip;

    // Determina o ícone e o tooltip com base no modo de UI atual.
    switch (locationService.currentLocationUIMode) {
      case LocationUIMode.Off:
        iconData = Icons.gps_not_fixed;
        tooltip = 'Mostrar minha localização';
        break;
      case LocationUIMode.ShowingAndCentered:
        iconData = Icons.gps_fixed;
        tooltip = 'Minha localização (mapa livre). Toque para seguir.';
        break;
      case LocationUIMode.ShowingAndPanned:
        iconData = Icons.my_location; // Ícone para "recentralizar"
        tooltip = 'Centralizar em minha localização';
        break;
      case LocationUIMode.FollowingPosition:
        iconData = Icons.navigation_outlined; // Seta de navegação
        tooltip = 'Seguindo sua posição. Toque para ativar bússola.';
        break;
      case LocationUIMode.FollowingPositionAndHeading:
        iconData = Icons.explore_outlined; // Bússola/explorar
        tooltip = 'Seguindo posição e direção. Toque para liberar mapa.';
        break;
      default:
        iconData = Icons.help_outline; // Ícone de fallback
        tooltip = 'Modo de localização desconhecido';
    }

    // O botão só é funcional se o serviço de localização estiver potencialmente disponível.
    // Se o status for 'permanentlyDenied' ou 'serviceDisabled' e não houver como resolver,
    // o botão pode ser desabilitado ou não ser a principal forma de interação.
    // No entanto, o `cycleLocationMode` já lida com a solicitação de permissão.

    return FloatingActionButton(
      heroTag: 'mapControlButton', // Tag para evitar conflitos com outros FABs
      mini: true, // Botão um pouco menor, comum para controles de mapa
      backgroundColor: Theme.of(context).colorScheme.secondary, // Cor de fundo
      foregroundColor:
          Theme.of(context).colorScheme.onSecondary, // Cor do ícone
      elevation: 4.0,
      tooltip: tooltip,
      onPressed: () {
        // Ao pressionar, chama o método para ciclar o modo no LocationService.
        // `read` é usado aqui porque não precisamos reconstruir este widget
        // em resposta a esta chamada, apenas disparar a ação.
        // O `watch` no início do build já garante a reconstrução quando o modo muda.
        context.read<LocationService>().cycleLocationMode();
      },
      child: Icon(iconData),
    );
  }
}
