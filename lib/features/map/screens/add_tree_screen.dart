import 'dart:convert'; // Para jsonEncode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:bosque_app/core/models/arvore.dart';
import 'package:bosque_app/core/services/location_service.dart';
import 'package:bosque_app/features/map/screens/select_location_on_map_screen.dart';

class AddTreeScreen extends StatefulWidget {
  const AddTreeScreen({super.key});

  @override
  State<AddTreeScreen> createState() => _AddTreeScreenState();
}

class _AddTreeScreenState extends State<AddTreeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _accessionController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _calcFullNameController = TextEditingController();
  final _vernacularNameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isSubmittingForm = false; // Renomeado de _isLoading para clareza
  bool _isGettingLocation =
      false; // NOVO: Estado para o carregamento da localização atual

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmittingForm = true;
      });

      final Arvore novaArvore = Arvore(
        accession: _accessionController.text,
        familyName: _familyNameController.text,
        calcFullName: _calcFullNameController.text,
        vernacularName: _vernacularNameController.text.isNotEmpty
            ? _vernacularNameController.text
            : null,
        latitude: double.parse(_latitudeController.text.replaceAll(',', '.')),
        longitude: double.parse(_longitudeController.text.replaceAll(',', '.')),
      );

      Map<String, dynamic> treeDataForApi = novaArvore.toMapForCreate();

      const String apiUrl =
          'http://melostrader.pythonanywhere.com/api/v1/bosque/trees/';

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization':
                'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzQ3NzU5NzAxLCJpYXQiOjE3NDc3NTI1MDEsImp0aSI6IjQzNjEzZTU5NzhmYjQ0NTdhNjQ4MjVkYjQ3YzE1MTgxIiwidXNlcl9pZCI6MX0.CUb4_IuG0VQ42Po8umCXIp8MAsKQOse1DHYax9X148s',
          },
          body: jsonEncode(treeDataForApi), // Envia o Map gerado pelo modelo
        );

        if (mounted) {
          if (response.statusCode == 201 || response.statusCode == 200) {
            // Tenta obter o ID da árvore criada a partir da resposta, se disponível
            String createdTreeIdentifier = novaArvore.calcFullName; // Fallback
            try {
              final responseData = jsonDecode(response.body);
              if (responseData['id'] != null) {
                createdTreeIdentifier =
                    "${novaArvore.calcFullName} (ID: ${responseData['id']})";
              } else if (responseData['calcFullName'] != null) {
                createdTreeIdentifier = responseData['calcFullName'];
              }
            } catch (e) {
              // Ignora erro de parsing da resposta, usa o nome do formulário
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Árvore "$createdTreeIdentifier" adicionada com sucesso!',
                      style: TextStyle(color: Colors.green[900])),
                  backgroundColor: Colors.lightGreen[300]),
            );
            Navigator.of(context).pop();
          } else {
            String errorMessage =
                'Falha ao adicionar árvore. Código: ${response.statusCode}';
            try {
              final responseBody = jsonDecode(response.body);
              final apiError = responseBody['message'] ??
                  responseBody['error'] ??
                  response.body;
              errorMessage += '\nDetalhes: $apiError';
            } catch (e) {
              errorMessage += '\nCorpo da resposta: ${response.body}';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(errorMessage,
                      style: TextStyle(color: Colors.yellow)),
                  backgroundColor: Colors.red[700]),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro de conexão: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmittingForm = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, corrija os erros no formulário.')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isGettingLocation = true;
    });

    final locationService = context.read<LocationService>();

    try {
      // 1. Verifica e solicita permissão
      // O checkAndRequestPermission já atualiza o status e errorMessage no LocationService
      // e chama notifyListeners. O LocationPermissionGuard lidaria com a UI de permissão
      // em outras partes do app, mas aqui precisamos de uma resposta direta.
      final bool permissionGranted =
          await locationService.checkAndRequestPermission();

      if (!mounted) return; // Verifica novamente se o widget ainda está montado

      if (!permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationService.errorMessage.isNotEmpty
                ? locationService.errorMessage
                : 'Permissão de localização não concedida.'),
            backgroundColor: Colors.orange[700],
          ),
        );
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      // 2. Se a permissão foi concedida, obtém a posição atual
      final Position currentPosition =
          await locationService.getCurrentPosition();
      if (!mounted) return;

      // 3. Atualiza os campos de texto
      _latitudeController.text = currentPosition.latitude
          .toStringAsFixed(9); // 7 casas decimais é uma boa precisão
      _longitudeController.text = currentPosition.longitude.toStringAsFixed(9);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Latitude e Longitude preenchidas com a localização atual!'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao obter localização: ${e.toString()}'),
            backgroundColor: Colors.red[700]),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _selectLocationOnMap() async {
    if (!mounted) return;

    // Define um centro inicial para o mapa de seleção.
    // Pode ser a localização atual do usuário, o centro do mapa principal,
    // ou as coordenadas já preenchidas se existirem.
    LatLng initialMapCenter;
    final double? currentLat =
        double.tryParse(_latitudeController.text.replaceAll(',', '.'));
    final double? currentLng =
        double.tryParse(_longitudeController.text.replaceAll(',', '.'));

    if (currentLat != null && currentLng != null) {
      initialMapCenter = LatLng(currentLat, currentLng);
    } else {
      // Tenta obter a última localização conhecida ou usa um padrão
      // Aqui, para simplificar, vamos usar um padrão fixo, mas você pode
      // buscar a última localização do LocationService se ele a expuser,
      // ou passar a localização atual do mapa principal.
      initialMapCenter =
          const LatLng(-3.097025, -59.986980); // Padrão da MapPage
    }

    // Navega para a tela de seleção e aguarda o resultado (LatLng)
    final selectedLocation = await Navigator.push<LatLng>(
      // Espera um LatLng de volta
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelectOnMapScreen(initialCenter: initialMapCenter),
      ),
    );

    if (selectedLocation != null && mounted) {
      _latitudeController.text = selectedLocation.latitude.toStringAsFixed(7);
      _longitudeController.text = selectedLocation.longitude.toStringAsFixed(7);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Localização selecionada no mapa!'),
          backgroundColor: Colors.blue[700],
        ),
      );
    }
  }

  @override
  void dispose() {
    _accessionController.dispose();
    _familyNameController.dispose();
    _calcFullNameController.dispose();
    _vernacularNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Nova Árvore'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // accession
                TextFormField(
                  controller: _accessionController,
                  decoration: const InputDecoration(
                      labelText: 'Accession',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bookmark_border)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Insira o Accession.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // familyName
                TextFormField(
                  controller: _familyNameController,
                  decoration: const InputDecoration(
                      labelText: 'Nome da Família',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.eco_outlined)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Insira o nome da família.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // calcFullName
                TextFormField(
                  controller: _calcFullNameController,
                  decoration: const InputDecoration(
                      labelText: 'Nome Científico Completo',
                      hintText: 'Ex: Handroanthus serratifolius',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.park_outlined)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Insira o nome científico.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // vernacularName (Opcional)
                TextFormField(
                  controller: _vernacularNameController,
                  decoration: const InputDecoration(
                      labelText: 'Nome Vernacular (Opcional)',
                      hintText: 'Ex: Ipê Amarelo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline)),
                ),
                const SizedBox(height: 16),

                // latitude
                TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.gps_fixed)),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Insira a latitude.';
                    // Permitir vírgula como separador decimal para entrada do usuário
                    if (double.tryParse(value.replaceAll(',', '.')) == null)
                      return 'Latitude inválida.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // longitude
                TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.gps_fixed)),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Insira a longitude.';
                    // Permitir vírgula como separador decimal para entrada do usuário
                    if (double.tryParse(value.replaceAll(',', '.')) == null)
                      return 'Longitude inválida.';
                    return null;
                  },
                ),
                const SizedBox(height: 24), // Espaço antes dos botões
                //Botões para obter localização
                _isGettingLocation
                    ? const Center(
                        child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ))
                    : Column(
                        // Usando Column para empilhar os botões se necessário, ou Row para lado a lado
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.my_location),
                            label: const Text('USAR LOCALIZAÇÃO ATUAL'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _getCurrentLocation,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            // Usando OutlinedButton para diferenciar visualmente
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('SELECIONAR NO MAPA'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _selectLocationOnMap,
                          ),
                        ],
                      ),

                const SizedBox(height: 32),

                _isSubmittingForm
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt_outlined),
                        label: const Text('Salvar Árvore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        onPressed: _submitForm,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
