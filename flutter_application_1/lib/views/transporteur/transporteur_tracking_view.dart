import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/available_reservation_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../services/camion_service.dart';
import '../../models/camion_model.dart';
import '../../utils/ville_utils.dart';
import '../../utils/map_status_indicators.dart';

class TransporteurTrackingView extends StatefulWidget {
  final AvailableReservation reservation;
  const TransporteurTrackingView({super.key, required this.reservation});

  @override
  State<TransporteurTrackingView> createState() => _TransporteurTrackingViewState();
}

class _TransporteurTrackingViewState extends State<TransporteurTrackingView> {
  LatLng? departCoord;
  LatLng? arriveeCoord;
  List<LatLng> routePoints = [];
  bool loading = true;
  String? error;
  
  // Pour le WebSocket
  WebSocketChannel? _channel;
  int? camionId;
  double? camionLat;
  double? camionLng;
  Image? camionIcon;
  MapController mapController = MapController();
  
  // Pour la mise à jour automatique de position
  Timer? _positionUpdateTimer;
  Timer? _animationTimer;
  bool _isAutoUpdating = false;
  
  // Pour l'animation fluide
  LatLng? _currentPosition;
  LatLng? _targetPosition;
  double _animationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTruckIcon();
    _fetchInitialCamionPosition();
    _fetchCoords();
    _connectWebSocket();
    
    // Démarrer automatiquement le suivi de position après un délai
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startAutoPositionUpdate();
      }
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _positionUpdateTimer?.cancel();
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTruckIcon() async {
    setState(() {
      camionIcon = Image.asset('assets/truck_top.png');
    });
  }

  Future<void> _fetchInitialCamionPosition() async {
    try {
      // Récupérer le camion du transporteur connecté
      final camion = await CamionService().getMyCamion();
      if (camion != null) {
        print('Position initiale du camion récupérée: ${camion.latitude}, ${camion.longitude}');
        setState(() {
          camionId = camion.id;
          camionLat = camion.latitude;
          camionLng = camion.longitude;
          departCoord = LatLng(camion.latitude, camion.longitude);
          _currentPosition = LatLng(camion.latitude, camion.longitude);
          _targetPosition = LatLng(camion.latitude, camion.longitude); // Initialiser aussi la position cible
        });
        print('Positions initialisées: _currentPosition = $_currentPosition, _targetPosition = $_targetPosition');
      } else {
        setState(() {
          error = 'Aucun camion trouvé pour ce transporteur';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erreur lors de la récupération du camion: $e';
        loading = false;
      });
    }
  }

  void _connectWebSocket() {
    final wsUrl = 'ws://192.168.1.100:8082/ws/camions';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _channel!.stream.listen((message) {
      try {
        final data = json.decode(message);
        
        if (data is Map<String, dynamic> && data['id'] == camionId) {
          final lat = data['latitude']?.toDouble();
          final lng = data['longitude']?.toDouble();
        
          if (lat != null && lng != null) {
            setState(() {
              camionLat = lat;
              camionLng = lng;
              departCoord = LatLng(lat, lng);
            });
          } else {
            print('Latitude ou longitude null');
          }
        } else {
          print('ID ne correspond pas ou data n\'est pas un Map');
        }
      } catch (e) {
        print('Erreur décodage WebSocket: $e');
      }
    },
    onError: (err) {
      print('Erreur WebSocket: $err');
    },
    onDone: () {
      print('WebSocket fermé');
    });
  }

  Future<void> _fetchCoords() async {
    setState(() { loading = true; error = null; });
    try {
      // Géocoder l'arrivée
      final arr = await _geocode(widget.reservation.lieuArrivee);
      if (arr != null) {
        arriveeCoord = arr;
        // Si on a déjà la position du camion, on peut tracer la route
        if (departCoord != null) {
          final route = await _getRoutePoints(departCoord!, arriveeCoord!);
          setState(() {
            routePoints = route;
            loading = false;
          });
        } else {
          setState(() {
            loading = false;
          });
        }
      } else {
        setState(() {
          error = 'Impossible de géocoder l\'adresse d\'arrivée.';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erreur: $e';
        loading = false;
      });
    }
  }

  Future<LatLng?> _geocode(String address) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}');
    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.tryParse(data[0]['lat'] ?? '');
        final lon = double.tryParse(data[0]['lon'] ?? '');
        if (lat != null && lon != null) {
          return LatLng(lat, lon);
        }
      }
    }
    return null;
  }

  Future<List<LatLng>> _getRoutePoints(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson'
      );
      final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          return coordinates.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
        }
      }
    } catch (e) {
      print('Erreur lors du routage: $e');
    }
    return [start, end]; // Fallback si erreur
  }

  Future<void> _updateMyPosition() async {
    try {
      print('=== Mise à jour position côté Flutter ===');
      print('Camion ID: $camionId');
      
      // Récupérer le token d'authentification
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        print('Erreur: Token d\'authentification manquant');
        if (!_isAutoUpdating) { // Éviter les messages multiples en mode auto
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: Token d\'authentification manquant'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Récupérer la position actuelle du transporteur
      final position = await _getCurrentPosition();
      print('Position récupérée: $position');
      
      if (position != null && camionId != null) {
        // Mettre à jour l'animation fluide
        setState(() {
          // Si c'est la première position, initialiser _currentPosition
          if (_currentPosition == null) {
            _currentPosition = position;
          } else {
            // Sinon, déplacer la position actuelle vers la cible
            _currentPosition = _targetPosition ?? _currentPosition;
          }
          _targetPosition = position;
          _animationProgress = 0.0;
        });
        
        print('Animation: _currentPosition = $_currentPosition, _targetPosition = $_targetPosition');
        
        final url = 'http://192.168.1.100:8082/api/camions/$camionId/position';
        final body = json.encode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
        
        print('URL: $url');
        print('Body: $body');
        print('Token: ${token.substring(0, 20)}...');
        
        // Mettre à jour la position du camion via l'API
        final response = await http.put(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );
        
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          if (!_isAutoUpdating) { // Éviter les messages multiples en mode auto
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Position mise à jour !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (!_isAutoUpdating) { // Éviter les messages multiples en mode auto
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${response.body}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('Erreur: position ou camionId null');
        print('Position: $position');
        print('Camion ID: $camionId');
      }
    } catch (e) {
      print('Exception lors de la mise à jour: $e');
      if (!_isAutoUpdating) { // Éviter les messages multiples en mode auto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<LatLng?> _getCurrentPosition() async {
    try {
      // Utiliser la vraie position GPS
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('Position GPS récupérée: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Erreur lors de la récupération de la position GPS: $e');
      
      // Fallback: demander la permission et réessayer
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            );
            return LatLng(position.latitude, position.longitude);
          }
        }
      } catch (e2) {
        print('Erreur lors de la demande de permission: $e2');
      }
      
      // Si tout échoue, retourner null
      return null;
    }
  }

  // Démarrer la mise à jour automatique de position
  void _startAutoPositionUpdate() {
    if (_isAutoUpdating) return; // Éviter les doublons
    
    setState(() {
      _isAutoUpdating = true;
    });
    
    // Mettre à jour immédiatement
    _updateMyPosition();
    
    // Puis programmer les mises à jour toutes les 2 secondes pour plus de fluidité
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isAutoUpdating) {
        _updateMyPosition();
      } else {
        timer.cancel();
      }
    });
    
    // Démarrer l'animation fluide
    _startSmoothAnimation();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Suivi automatique activé - Animation fluide activée'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Démarrer l'animation fluide
  void _startSmoothAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && _isAutoUpdating && _currentPosition != null && _targetPosition != null) {
        setState(() {
          _animationProgress += 0.05; // Progression plus lente pour une animation plus fluide
          if (_animationProgress >= 1.0) {
            _animationProgress = 0.0;
            _currentPosition = _targetPosition;
          }
        });
        print('Animation progress: $_animationProgress');
      } else {
        timer.cancel();
      }
    });
  }

  // Obtenir la position animée
  LatLng? _getAnimatedPosition() {
    if (_currentPosition == null) return departCoord;
    if (_targetPosition == null || _animationProgress == 0.0) return _currentPosition;
    
    // Interpolation linéaire pour une animation fluide
    final lat = _currentPosition!.latitude + (_targetPosition!.latitude - _currentPosition!.latitude) * _animationProgress;
    final lng = _currentPosition!.longitude + (_targetPosition!.longitude - _currentPosition!.longitude) * _animationProgress;
    
    final animatedPosition = LatLng(lat, lng);
    print('Animated position: $animatedPosition (progress: $_animationProgress)');
    return animatedPosition;
  }

  // Arrêter la mise à jour automatique de position
  void _stopAutoPositionUpdate() {
    if (!_isAutoUpdating) return;
    
    setState(() {
      _isAutoUpdating = false;
    });
    
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = null;
    _animationTimer?.cancel();
    _animationTimer = null;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏹️ Suivi automatique désactivé'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi en direct'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          if (camionId != null) ...[
            // Bouton pour mettre à jour manuellement
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () => _updateMyPosition(),
              tooltip: 'Mettre à jour ma position GPS',
            ),
            // Bouton pour activer/désactiver le suivi automatique
            IconButton(
              icon: Icon(_isAutoUpdating ? Icons.stop : Icons.play_arrow),
              onPressed: _isAutoUpdating ? _stopAutoPositionUpdate : _startAutoPositionUpdate,
              tooltip: _isAutoUpdating ? 'Arrêter le suivi automatique' : 'Démarrer le suivi automatique',
            ),
          ],
        ],
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement du suivi...',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Bannière de statut du suivi automatique
                    if (_isAutoUpdating)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.green.withOpacity(0.9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sync, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                                                         const Text(
                               '🔄 Suivi automatique actif - Animation fluide',
                               style: TextStyle(
                                 color: Colors.white,
                                 fontSize: 12,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                          ],
                        ),
                      ),
                                         // Carte
                     Expanded(
                       child: FlutterMap(
                         mapController: mapController,
                         options: MapOptions(
                           bounds: (departCoord != null && arriveeCoord != null)
                               ? LatLngBounds(departCoord!, arriveeCoord!)
                               : null,
                           boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(80)),
                         ),
                         children: [
                           TileLayer(
                             urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                             userAgentPackageName: 'com.example.app',
                           ),
                           if (departCoord != null && arriveeCoord != null)
                             PolylineLayer(
                               polylines: [
                                 Polyline(
                                   points: routePoints.isNotEmpty ? routePoints : [departCoord!, arriveeCoord!],
                                   color: MapStatusIndicators.getRouteColor(widget.reservation.statut),
                                   strokeWidth: 4,
                                 ),
                               ],
                             ),
                           // Indicateur de transit au centre de la route
                           if (routePoints.isNotEmpty && routePoints.length >= 2)
                             MarkerLayer(
                               markers: [
                                 Marker(
                                   point: MapStatusIndicators.getRouteCenterPoint(routePoints),
                                   width: 50,
                                   height: 50,
                                   child: MapStatusIndicators.createTransitIndicator(
                                     status: widget.reservation.statut,
                                     size: 50,
                                   ),
                                 ),
                               ],
                             ),
                                                       if (_getAnimatedPosition() != null)
                              MarkerLayer(
                                markers: [
                                  // Marqueur animé du camion
                                  Marker(
                                    point: _getAnimatedPosition()!,
                                    width: 50,
                                    height: 50,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A8A),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.local_shipping,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  // Marqueur de debug pour voir la position cible (optionnel)
                                  if (_targetPosition != null && _currentPosition != null && _targetPosition != _currentPosition)
                                    Marker(
                                      point: _targetPosition!,
                                      width: 30,
                                      height: 30,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.red, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.circle,
                                          color: Colors.red,
                                          size: 15,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                           if (arriveeCoord != null)
                             MarkerLayer(
                               markers: [
                                 Marker(
                                   point: arriveeCoord!,
                                   width: 60,
                                   height: 60,
                                   child: MapStatusIndicators.createStatusBadge(
                                     status: widget.reservation.statut,
                                     text: 'ARRIVÉE',
                                     icon: MapStatusIndicators.getArrivalIcon(widget.reservation.statut),
                                     size: 60,
                                   ),
                                 ),
                               ],
                             ),
                         ],
                       ),
                     ),
                   ],
                 ),
             floatingActionButton: (_getAnimatedPosition() != null)
           ? FloatingActionButton(
               onPressed: () {
                 mapController.move(_getAnimatedPosition()!, 16);
               },
               backgroundColor: const Color(0xFF1E3A8A),
               tooltip: 'Centrer sur ma position',
               child: const Icon(Icons.center_focus_strong, color: Colors.white),
             )
           : null,
    );
  }
} 