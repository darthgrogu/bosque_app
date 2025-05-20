// lib/core/widgets/location_permission_guard.dart
// ignore_for_file: unreachable_switch_default

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bosque_app/core/services/location_service.dart'; // Ajuste o caminho

/// Um widget que guarda seu `child` com base no status da permissão de localização.
///
/// Observa o [LocationService] e:
/// - Se o status da permissão for [LocationStatus.initial] (nenhuma tentativa de permissão ainda),
///   renderiza um [SizedBox.shrink()] (nada visível).
/// - Se a permissão for concedida ([LocationStatus.granted]), renderiza o [child].
/// - Caso contrário (negada, GPS desligado, erro, etc.), exibe uma UI informativa
///   com opções para o usuário resolver o problema de permissão.
///
/// A solicitação de permissão ([LocationService.checkAndRequestPermission]) deve ser
/// acionada por uma ação explícita do usuário. (Ex.: botão "ativar navegação" na tela pai)
class LocationPermissionGuard extends StatelessWidget {
  /// O widget a ser renderizado quando a permissão de localização for concedida.
  final Widget child;

  const LocationPermissionGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Observa o LocationService para reagir a mudanças no status da permissão.
    final locationService = context.watch<LocationService>();

    // Determina qual UI exibir com base no status do LocationService.
    switch (locationService.status) {
      case LocationStatus.initial:
        // Se o estado é inicial (nenhuma tentativa de permissão ainda),
        // não mostre nada. A camada de localização do usuário só aparecerá
        // após uma ação explícita do usuário que dispare checkAndRequestPermission()
        // e altere o status.
        return const SizedBox.shrink();

      case LocationStatus.checking:
        // Se estiver ativamente verificando (ex: após um clique em "Tentar Novamente").
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando status da localização...'),
            ],
          ),
        );

      case LocationStatus.granted:
        // Permissão concedida! Renderiza o widget filho.
        return child;

      case LocationStatus.serviceDisabled:
        // O serviço de GPS do dispositivo está desligado.
        return _buildPermissionFeedbackUI(
          context: context,
          icon: Icons.location_off_outlined, // Ícone atualizado
          title: 'GPS Desligado',
          message: locationService.errorMessage.isNotEmpty
              ? locationService.errorMessage
              : 'O serviço de localização (GPS) do seu dispositivo está desligado. Por favor, ative-o para que possamos mostrar sua localização.',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Abrir Config. de Localização'),
              onPressed: () {
                locationService.openLocationSettings();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Verificar Novamente'),
              onPressed: () {
                locationService.checkAndRequestPermission();
              },
            ),
          ],
        );

      case LocationStatus.denied:
        // Permissão negada pelo usuário (pode ser solicitada novamente).
        return _buildPermissionFeedbackUI(
          context: context,
          icon: Icons.location_disabled_outlined, // Ícone atualizado
          title: 'Permissão Necessária',
          message: locationService.errorMessage.isNotEmpty
              ? locationService.errorMessage
              : 'Para mostrar sua localização no mapa, precisamos da sua permissão. Por favor, conceda o acesso à localização.',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('Conceder Permissão'),
              onPressed: () {
                locationService.checkAndRequestPermission();
              },
            ),
          ],
        );

      case LocationStatus.permanentlyDenied:
        // Permissão negada permanentemente. O usuário precisa ir às configurações do app.
        return _buildPermissionFeedbackUI(
          context: context,
          icon: Icons.block_flipped, // Ícone atualizado
          title: 'Permissão Bloqueada',
          message: locationService.errorMessage.isNotEmpty
              ? locationService.errorMessage
              : 'A permissão de localização foi negada permanentemente. Para usar este recurso, você precisa habilitá-la manualmente nas configurações do aplicativo.',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.app_settings_alt_outlined),
              label: const Text('Abrir Config. do App'),
              onPressed: () {
                locationService.openAppSettings();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Verificar Após Alterar'),
              onPressed: () {
                locationService.checkAndRequestPermission();
              },
            ),
          ],
        );

      case LocationStatus.error:
        // Ocorreu um erro genérico.
        return _buildPermissionFeedbackUI(
          context: context,
          icon: Icons.error_outline,
          title: 'Erro de Localização',
          message: locationService.errorMessage.isNotEmpty
              ? locationService.errorMessage
              : 'Ocorreu um erro inesperado ao tentar acessar sua localização.',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              onPressed: () {
                locationService.checkAndRequestPermission();
              },
            ),
          ],
        );

      default:
        // Caso algum status não seja tratado (não deve acontecer).
        return _buildPermissionFeedbackUI(
            context: context,
            icon: Icons.help_outline,
            title: 'Status Desconhecido',
            message:
                'Status de localização desconhecido. Tente verificar novamente.',
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Verificar Status'),
                onPressed: () {
                  locationService.checkAndRequestPermission();
                },
              ),
            ]);
    }
  }

  /// Widget auxiliar para construir a UI de feedback de permissão de forma padronizada.
  Widget _buildPermissionFeedbackUI({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required List<Widget> actions,
  }) {
    return Center(
      child: SingleChildScrollView(
        // Garante que não haverá overflow em telas menores
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon,
                size: 72,
                color: Theme.of(context)
                    .colorScheme
                    .primary), // Ajuste de cor e tamanho
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            // Os botões são passados como uma lista para flexibilidade
            ...actions.map((action) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    // Garante uma largura mínima para os botões
                    width: double.infinity, // Ou um valor fixo como 200
                    child: action,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
