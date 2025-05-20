import 'dart:async';
import 'package:flutter/foundation.dart'; // Necessário para usar 'ChangeNotifier'
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart'; // Para AlignOnUpdate

// Enum para representar o status da permissão de forma mais clara para a UI
enum LocationStatus {
  initial, // Estado inicial, antes de qualquer verificação
  checking, // Verificando permissão ou status do serviço
  granted, // Permissão concedida e serviço GPS ativo
  denied, // Permissão negada pelo usuário (pode pedir de novo)
  permanentlyDenied, // Permissão permanentemente negada (precisa ir às config. do app)
  serviceDisabled, // Serviço de localização (GPS) do dispositivo está desligado
  error, // Erro genérico durante a verificação
}

// Enum para os modos de UI da funcionalidade de localização/navegação no mapa
enum LocationUIMode {
  Off, // Localização desligada, marcador não visível.
  ShowingAndCentered, // Localização visível, mapa centralizado no usuário uma vez, mapa livre para mover.
  ShowingAndPanned, // Localização visível, mas usuário moveu o mapa (não está centralizado), mapa livre.
  FollowingPosition, // Mapa segue a posição do usuário, sem rotação pela bússola.
  FollowingPositionAndHeading, // Mapa segue a posição e rotaciona com a bússola/direção.
}

class LocationService with ChangeNotifier {
  // Propriedades privadas para armazenar o estado interno do serviço
  LocationStatus _status = LocationStatus.initial;
  String _errorMessage = '';

  // Getters públicos
  LocationStatus get status => _status;
  String get errorMessage => _errorMessage;
  // Getter de conveniência para verificar rapidamente se a localização pode ser acessada.
  // A UI pode usar isso para, por exemplo, habilitar/desabilitar botões.
  bool get canAccessLocation => _status == LocationStatus.granted;

  // --- ESTADO DO MODO DE UI DA LOCALIZAÇÃO/NAVEGAÇÃO ---
  LocationUIMode _currentUIMode = LocationUIMode.Off;
  AlignOnUpdate _mapAlignPosition = AlignOnUpdate.never;
  AlignOnUpdate _mapAlignDirection = AlignOnUpdate.never;

  // StreamController para comandar a centralização/zoom inicial quando um modo é ativado.
  // Usamos .broadcast() para permitir múltiplos ouvintes, embora geralmente seja um.
  final StreamController<double?> _navigationAlignCommandController =
      StreamController<double?>.broadcast();

  // Getters públicos para o estado do modo de UI
  LocationUIMode get currentLocationUIMode => _currentUIMode;
  AlignOnUpdate get mapAlignPosition => _mapAlignPosition;
  AlignOnUpdate get mapAlignDirection => _mapAlignDirection;
  Stream<double?> get navigationAlignCommandStream =>
      _navigationAlignCommandController.stream;
  // --- FIM DO ESTADO DO MODO DE UI ---

  @override
  void dispose() {
    _navigationAlignCommandController.close();
    super.dispose();
  }

  /// Método principal para verificar e solicitar permissões.
  /// Atualiza o estado (_status, _errorMessage) e notifica os widgets "ouvintes".
  /// Retorna `true` se a permissão foi concedida e o GPS está ativo.
  Future<bool> checkAndRequestPermission() async {
    // Se já estiver verificando, não faz nada para evitar múltiplas solicitações.
    if (_status == LocationStatus.checking) return canAccessLocation;

    // Atualiza o status para 'checking' e notifica os ouvintes.
    // Widgets que estão "assistindo" (watch) a este LocationService serão reconstruídos
    // e podem mostrar um indicador de carregamento, por exemplo.
    _updateStatus(LocationStatus.checking);

    try {
      // 1. Verifica se o serviço de GPS do dispositivo está ligado.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateStatus(LocationStatus.serviceDisabled,
            "O serviço de localização (GPS) está desligado. Por favor, ative-o.");
        return false; // Não podemos prosseguir sem GPS.
      }

      // 2. Verifica o status atual da permissão de localização do aplicativo.
      PermissionStatus permission = await Permission.location.status;

      // 3. Se a permissão foi negada anteriormente (mas não permanentemente),
      //    solicita a permissão ao usuário novamente.
      if (permission.isDenied || permission.isRestricted) {
        // .isDenied cobre o caso de nunca ter sido pedido também
        permission = await Permission.location.request();
      }

      // 4. Com base no status final da permissão, atualiza o estado do serviço.
      if (permission.isGranted) {
        _updateStatus(LocationStatus.granted); // Tudo OK!
      } else if (permission.isPermanentlyDenied) {
        _updateStatus(LocationStatus.permanentlyDenied,
            "Permissão de localização negada permanentemente. Você precisa habilitá-la nas configurações do aplicativo.");
      } else {
        // Outros casos: negada novamente, restrita, etc.
        _updateStatus(
            LocationStatus.denied, "Permissão de localização negada.");
      }
      // Retorna true se a permissão foi concedida.
      return canAccessLocation;
    } catch (e) {
      // Se ocorrer qualquer erro inesperado durante o processo.
      print("Erro em checkAndRequestPermission (LocationService): $e");
      _updateStatus(LocationStatus.error,
          "Ocorreu um erro ao verificar a permissão de localização: ${e.toString()}");
      return false;
    }
  }

  void _updateStatus(LocationStatus newStatus, [String message = '']) {
    // Só atualiza e notifica se o status ou a mensagem realmente mudaram,
    // ou se estamos explicitamente mudando para 'checking' ou 'initial' que podem precisar de notificação.
    bool shouldNotify = _status != newStatus || _errorMessage != message;
    _status = newStatus;
    _errorMessage = message;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// Obtém a posição atual do usuário (uma única vez).
  /// Primeiro, chama `checkAndRequestPermission` para garantir que tudo está OK.
  Future<Position> getCurrentPosition() async {
    // Garante que as permissões sejam verificadas (e solicitadas, se necessário).
    // O estado do LocationService será atualizado por checkAndRequestPermission.
    final hasPermission = await checkAndRequestPermission();

    if (!hasPermission) {
      // Se não obteve permissão, lança uma exceção com a mensagem de erro atual do serviço.
      // A UI que chama este método deve estar preparada para tratar essa exceção.
      throw Exception(_errorMessage.isNotEmpty
          ? _errorMessage
          : "Permissão de localização não concedida.");
    }

    // Se tem permissão, busca a posição atual.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Retorna um Stream (fluxo contínuo) de atualizações de posição.
  /// IMPORTANTE: A UI deve verificar `canAccessLocation` ANTES de começar a "ouvir" este stream.
  Stream<Position> getPositionStream() {
    // Se não temos permissão, retornamos um stream vazio para evitar erros.
    // O widget consumidor deve idealmente nem tentar ouvir este stream se canAccessLocation for false.
    if (!canAccessLocation) {
      return Stream.empty();
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Atualiza a cada 2 metros de deslocamento.
      ),
    );
  }

  /// Retorna um Stream (fluxo contínuo) de atualizações da bússola.
  Stream<CompassEvent?> getCompassStream() {
    // A bússola pode não estar disponível em todos os dispositivos.
    return FlutterCompass.events ?? Stream.empty();
  }

  // Métodos utilitários para abrir as configurações do sistema operacional.
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // --- MÉTODOS PARA CONTROLAR O MODO DE UI DA LOCALIZAÇÃO/NAVEGAÇÃO ---

  /// Alterna para o próximo modo de UI de localização/navegação.
  /// Dispara a verificação de permissão se a localização estiver desligada.
  Future<void> cycleLocationMode({double defaultZoom = 17.0}) async {
    LocationUIMode nextMode;

    // Se a localização está desligada, o primeiro passo é tentar ligá-la e obter permissão.
    if (_currentUIMode == LocationUIMode.Off) {
      final bool permissionGranted = await checkAndRequestPermission();
      if (permissionGranted) {
        nextMode = LocationUIMode.ShowingAndCentered;
      } else {
        // Permissão não foi concedida. O _status reflete isso (ex: denied, permanentlyDenied).
        // O LocationPermissionGuard usará esse _status para mostrar a UI apropriada.
        // Não precisamos mudar o _currentUIMode aqui, ele permanece Off.
        // Chamamos notifyListeners() para garantir que qualquer widget observando
        // o LocationService (como o MapControlButton, que pode depender de _currentUIMode
        // para seu ícone/tooltip) seja reconstruído, mesmo que _currentUIMode não tenha mudado,
        // mas uma tentativa de ciclo ocorreu. Isso é uma salvaguarda.
        notifyListeners(); // Garante que a UI que depende do modo seja atualizada
        return;
      }
    } else if (_currentUIMode == LocationUIMode.ShowingAndCentered) {
      // Se já está mostrando e centralizado, o próximo passo é seguir a posição.
      // A permissão já é 'granted' para estar neste estado.
      nextMode = LocationUIMode.FollowingPosition;
    } else if (_currentUIMode == LocationUIMode.ShowingAndPanned) {
      // Se o mapa foi movido pelo usuário, o próximo clique recentraliza.
      nextMode = LocationUIMode.ShowingAndCentered;
    } else if (_currentUIMode == LocationUIMode.FollowingPosition) {
      // Se está seguindo a posição, o próximo passo é seguir com a bússola.
      nextMode = LocationUIMode.FollowingPositionAndHeading;
    } else if (_currentUIMode == LocationUIMode.FollowingPositionAndHeading) {
      // Se está seguindo com a bússola, o próximo passo é voltar para mostrar e centralizar (mapa livre).
      nextMode = LocationUIMode.ShowingAndCentered;
    } else {
      // Caso inesperado, volta para Off.
      nextMode = LocationUIMode.Off;
    }

    _currentUIMode = nextMode;

    // Configura os comportamentos de alinhamento do mapa com base no novo modo.
    switch (_currentUIMode) {
      case LocationUIMode.Off:
        _mapAlignPosition = AlignOnUpdate.never;
        _mapAlignDirection = AlignOnUpdate.never;
        break;
      case LocationUIMode.ShowingAndCentered:
        _mapAlignPosition =
            AlignOnUpdate.never; // O mapa é livre após a centralização inicial.
        _mapAlignDirection = AlignOnUpdate.never;
        // Comanda uma centralização única com o zoom padrão.
        if (!_navigationAlignCommandController.isClosed) {
          _navigationAlignCommandController.add(defaultZoom);
        }
        break;
      case LocationUIMode.ShowingAndPanned:
        // O comando de centralização virá do próximo clique, que levará a ShowingAndCentered.
        _mapAlignPosition = AlignOnUpdate.never;
        _mapAlignDirection = AlignOnUpdate.never;
        break;
      case LocationUIMode.FollowingPosition:
        _mapAlignPosition = AlignOnUpdate.always;
        _mapAlignDirection = AlignOnUpdate.never;
        // Comanda uma centralização ao ativar o modo de seguimento.
        if (!_navigationAlignCommandController.isClosed) {
          _navigationAlignCommandController.add(defaultZoom);
        }
        break;
      case LocationUIMode.FollowingPositionAndHeading:
        _mapAlignPosition = AlignOnUpdate.always;
        _mapAlignDirection = AlignOnUpdate.always;
        // Comanda uma centralização ao ativar o modo de seguimento com bússola.
        if (!_navigationAlignCommandController.isClosed) {
          _navigationAlignCommandController.add(defaultZoom);
        }
        break;
    }
    notifyListeners(); // Notifica a UI sobre a mudança de modo.
  }

  /// Chamado pela UI quando o usuário interage (arrasta) o mapa.
  /// Se um modo de seguimento estiver ativo, ele é alterado para 'ShowingAndPanned'.
  void userInteractedWithMap() {
    if (_currentUIMode == LocationUIMode.FollowingPosition ||
        _currentUIMode == LocationUIMode.FollowingPositionAndHeading) {
      _currentUIMode = LocationUIMode.ShowingAndPanned;
      _mapAlignPosition = AlignOnUpdate.never; // Para o seguimento
      _mapAlignDirection = AlignOnUpdate.never; // Para a rotação da bússola
      notifyListeners();
      debugPrint(
          "LocationService: Usuário moveu o mapa, modo alterado para ShowingAndPanned.");
    }
  }
}
