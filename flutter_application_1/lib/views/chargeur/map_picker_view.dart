import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';
import '../../models/camion_model.dart';
import '../../services/camion_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MapPickerView extends StatefulWidget {
  final String title;
  const MapPickerView({super.key, this.title = 'Choisir un lieu'});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  LatLng? pickedLocation;
  String? pickedAddress;
  bool loadingAddress = false;
  bool loadingLocation = false;
  MapController mapController = MapController();
  bool isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _searching = false;
  Timer? _debounce;
  List<Camion> _camionsProches = [];
  bool _loadingCamions = false;
  late WebSocketChannel camionChannel;

  // Supprimer toutes les variables, méthodes, timers et widgets liés aux camions et à leur trajectoire (simulation, animation, marqueurs, etc.). Le code redevient une simple carte avec sélection de lieu.

  @override
  void initState() {
    super.initState();
    _initializeWithCurrentLocation();
    // Connexion WebSocket pour les camions
    camionChannel = WebSocketChannel.connect(
              Uri.parse('ws://192.168.100.19:8082/ws/camions'), 
    );
    camionChannel.stream.listen((message) {
      try {
        final data = jsonDecode(message);
        final Camion updatedCamion = Camion.fromJson(data);
        setState(() {
          if (updatedCamion.id != null) {
            final index = _camionsProches.indexWhere((c) => c.id == updatedCamion.id);
            if (index != -1) {
              _camionsProches[index] = updatedCamion;
            } else {
              _camionsProches.add(updatedCamion);
            }
          }
        });
      } catch (e) {
        // ignore les messages invalides
      }
    });
  }

  @override
  void dispose() {
    camionChannel.sink.close();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeWithCurrentLocation() async {
    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return; // Garder la position par défaut (Tunis)
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return; // Garder la position par défaut
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return; // Garder la position par défaut
      }

      // Récupérer la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
      
      final latLng = LatLng(position.latitude, position.longitude);
      
      // Centrer la carte sur la position actuelle
      mapController.move(latLng, 15);
      
      // Placer le marqueur et récupérer l'adresse
      _onTapMap(latLng);
      
      // Récupérer les camions proches dynamiquement
      await _fetchCamionsProches(latLng);
      setState(() {
        isInitialized = true;
      });
      
    } catch (e) {
      print('Erreur lors de l\'initialisation avec la position actuelle: $e');
      // En cas d'erreur, garder la position par défaut
    }
  }

  Future<String?> getAddressFromLatLng(LatLng latLng) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latLng.latitude}&lon=${latLng.longitude}&accept-language=fr');
      final response = await http.get(url, headers: {
        'User-Agent': 'FlutterApp',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'adresse: $e');
    }
    return null;
  }

  void _onTapMap(LatLng latLng) async {
    setState(() {
      pickedLocation = latLng;
      pickedAddress = null;
      loadingAddress = true;
      _camionsProches.clear(); // Efface les camions existants
    });
    final address = await getAddressFromLatLng(latLng);
    setState(() {
      pickedAddress = address;
      loadingAddress = false;
    });
    await _fetchCamionsProches(latLng); // Affiche les camions proches de la nouvelle zone
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    setState(() {
      _searching = true;
    });
    // Utiliser Photon API (plus rapide que Nominatim)
    final url = Uri.parse('https://photon.komoot.io/api/?q=$query&lang=fr&limit=10&lat=33.5731&lon=-7.5898&bbox=-13.1684,27.6621,0.9984,35.9225');
    try {
      final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'}).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'] ?? [];
        setState(() {
          _suggestions = features.map((feature) {
            final properties = feature['properties'] ?? {};
            final geometry = feature['geometry'] ?? {};
            final coordinates = geometry['coordinates'] ?? [0, 0];
            return {
              'display_name': properties['name'] ?? properties['street'] ?? '',
              'lat': coordinates[1].toString(),
              'lon': coordinates[0].toString(),
              'type': properties['type'] ?? '',
              'city': properties['city'] ?? properties['state'] ?? '',
              'full_address': properties['name'] != null ? '${properties['name']}, ${properties['city'] ?? ''}' : properties['street'] ?? '',
            };
          }).toList();
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _suggestions = [];
      });
    }
    setState(() {
      _searching = false;
    });
  }

  void _onSuggestionTap(Map<String, dynamic> suggestion) {
    final double lat = double.parse(suggestion['lat']);
    final double lon = double.parse(suggestion['lon']);
    final LatLng latLng = LatLng(lat, lon);
    mapController.move(latLng, 15);
    _onTapMap(latLng);
    setState(() {
      _searchController.text = suggestion['display_name'] ?? '';
      _suggestions = [];
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (loadingLocation) return; // Éviter les appels multiples
    
    setState(() {
      loadingLocation = true;
    });

    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          loadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez activer la localisation dans les paramètres'),
            duration: Duration(seconds: 3),
          ),
        );
        await Geolocator.openLocationSettings();
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            loadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de localisation refusée'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          loadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission de localisation définitivement refusée. Veuillez l\'activer dans les paramètres.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Récupérer la position avec timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));
      
      final latLng = LatLng(position.latitude, position.longitude);
      
      // Centrer la carte
      mapController.move(latLng, 15);
      
      // Marquer la position
      _onTapMap(latLng);

      // Vider la liste des camions affichés
      setState(() {
        _camionsProches.clear();
      });

      // Relancer la requête pour les camions proches
      await _fetchCamionsProches(latLng);
      
      setState(() {
        loadingLocation = false;
      });
      
    } catch (e) {
      setState(() {
        loadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération de la position: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _fetchCamionsProches(LatLng center) async {
    setState(() { _loadingCamions = true; });
    try {
      final camions = await CamionService().getCamionsProches(
        latitude: center.latitude,
        longitude: center.longitude,
        rayonKm: 10,
      );
      setState(() {
        _camionsProches = camions;
      });
    } catch (e) {
      setState(() { _camionsProches = []; });
    }
    setState(() { _loadingCamions = false; });
  }

  // Supprimer la méthode _drawRouteToAzemmour

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          // Barre de recherche toujours visible
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une adresse...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _suggestions = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 400), () {
                        if (value.length > 2) {
                          _searchAddress(value);
                        } else {
                          setState(() {
                            _suggestions = [];
                          });
                        }
                      });
                    },
                  ),
                ),
                if (_searching)
                  const LinearProgressIndicator(minHeight: 2),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        final String mainName = suggestion['display_name'] ?? '';
                        final String fullAddress = suggestion['full_address'] ?? suggestion['display_name'] ?? '';
                        final String type = suggestion['type'] ?? '';
                        final String city = suggestion['city'] ?? '';
                        
                        return ListTile(
                          title: Text(mainName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (type.isNotEmpty) Text(type, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                              Text(fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          onTap: () => _onSuggestionTap(suggestion),
                        );
                      },
                    ),
                  ),
                if (!_searching && _searchController.text.length > 2 && _suggestions.isEmpty && _debounce?.isActive == false)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Aucun résultat trouvé pour votre recherche.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
              ],
            ),
          ),
          // Carte et boutons
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8), // Pour éviter le chevauchement
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      center: LatLng(36.8065, 10.1815), // Tunis par défaut
                      zoom: 12,
                      onTap: (tapPosition, latLng) => _onTapMap(latLng),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.app',
                      ),
                      // Marqueurs camions dynamiques
                      if (_camionsProches.isNotEmpty)
                        MarkerLayer(
                          markers: _camionsProches.asMap().entries.map((entry) {
                            final i = entry.key;
                            final camion = entry.value;
                            return Marker(
                              width: 48,
                              height: 48,
                              point: LatLng(camion.latitude, camion.longitude),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(milliseconds: 400 + i * 80),
                                builder: (context, value, child) => Opacity(
                                  opacity: value,
                                  child: Transform.scale(
                                    scale: value,
                                    child: child,
                                  ),
                                ),
                                child: Image.asset('assets/truck_top.png', width: 40, height: 40),
                              ),
                            );
                          }).toList(),
                        ),
                      // Marqueur utilisateur
                      if (pickedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 40,
                              height: 40,
                              point: pickedLocation!,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      // Supprimer la déclaration et l'utilisation de _routePoints et _loadingRoute
                      // Supprimer le FloatingActionButton.extended pour le trajet
                      // Supprimer le PolylineLayer pour le trajet
                      // Tracé du trajet
                      // Supprimer toute la logique d'animation du camion sur le trajet El Jadida-Azemmour
                      // Supprimer la polyline, le marqueur animé, les méthodes _fetchTrajetElJadidaAzemmour, _startCamionTrajetAnimation, _calculateAngle, et les variables associées (_trajetPoints, _camionTrajetIndex, _camionAngle)
                    ],
                  ),
                ),
                // Indicateur de chargement pendant l'initialisation
                if (!isInitialized && pickedLocation == null)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Récupération de votre position...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (pickedLocation != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: loadingAddress
                                ? const Center(child: CircularProgressIndicator())
                                : Text(
                                    pickedAddress ?? 'Adresse introuvable',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Valider ce lieu'),
                          onPressed: pickedAddress != null
                              ? () {
                                  Navigator.pop(context, {
                                    'address': pickedAddress,
                                    'latlng': pickedLocation,
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: FloatingActionButton(
                    heroTag: 'currentLocation',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    onPressed: loadingLocation ? null : _goToCurrentLocation,
                    tooltip: loadingLocation ? 'Récupération de la position...' : 'Ma position',
                    child: loadingLocation 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                            ),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
                // Supprimer le FloatingActionButton.extended pour le trajet
              ],
            ),
          ),
        ],
      ),
    );
  }
} 