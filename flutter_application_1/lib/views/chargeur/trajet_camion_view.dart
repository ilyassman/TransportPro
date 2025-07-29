import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/reservation_display_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../services/camion_service.dart';
import '../../models/camion_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_view.dart';

class TrajetCamionView extends StatefulWidget {
  final ReservationDisplay reservation;
  const TrajetCamionView({Key? key, required this.reservation}) : super(key: key);

  @override
  State<TrajetCamionView> createState() => _TrajetCamionViewState();
}

class _TrajetCamionViewState extends State<TrajetCamionView> {
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
  MapController mapController = MapController(); // Ajouté

  @override
  void initState() {
    super.initState();
    camionId = widget.reservation.camionId; // Assurez-vous que ReservationDisplay a bien ce champ
    _loadTruckIcon();
    _fetchInitialCamionPosition(); // Ajouté
    _fetchCoords();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _loadTruckIcon() async {
    setState(() {
      camionIcon = Image.asset('assets/truck_top.png');
    });
  }

  Future<void> _fetchInitialCamionPosition() async {
    if (camionId == null) return;
    final camion = await CamionService().getCamionById(camionId!);
    if (camion != null && camion.latitude != null && camion.longitude != null) {
      print('Position initiale du camion récupérée: ${camion.latitude}, ${camion.longitude}');
      setState(() {
        camionLat = camion.latitude;
        camionLng = camion.longitude;
        departCoord = LatLng(camion.latitude!, camion.longitude!);
      });
    }
  }

  void _connectWebSocket() {
    // Remplacez l'URL par celle de votre backend si besoin
    final wsUrl = 'ws://10.0.2.2:8082/ws/camions'; // Utilise 10.0.2.2 pour l'émulateur Android
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
              departCoord = LatLng(lat, lng); // On utilise la position réelle du camion
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
      // On ne géocode que l'arrivée, le départ sera la position réelle du camion
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
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=' + Uri.encodeComponent(address));
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

  Future<void> _simulateCamionMovement() async {
    if (camionId == null) return;
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/api/camions/$camionId/simulate-movement'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulation de mouvement démarrée !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour appeler le transporteur
  Future<void> _callTransporteur() async {
    if (widget.reservation.transporteurPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone du transporteur non disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final phoneNumber = widget.reservation.transporteurPhone;
    
    // Afficher un dialogue de confirmation
    bool? shouldCall = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Appeler le transporteur'),
          content: Text('Voulez-vous appeler ${widget.reservation.transporteurNom} au ${phoneNumber} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Appeler'),
            ),
          ],
        );
      },
    );

    if (shouldCall != true) return;
    
    try {
      // Demander les permissions téléphoniques
      PermissionStatus phoneStatus = await Permission.phone.request();
      if (phoneStatus.isDenied || phoneStatus.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission d\'appel téléphonique requise'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Nettoyer le numéro de téléphone
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Ajouter le préfixe si nécessaire
      if (!cleanNumber.startsWith('+')) {
        if (cleanNumber.startsWith('0')) {
          cleanNumber = '+212' + cleanNumber.substring(1);
        } else if (cleanNumber.startsWith('212')) {
          cleanNumber = '+' + cleanNumber;
        } else {
          cleanNumber = '+212' + cleanNumber;
        }
      }
      
      // Essayer plusieurs formats d'URL
      List<String> urlFormats = [
        'tel:$cleanNumber',
        'tel:${cleanNumber.replaceAll('+', '')}',
        'tel:${cleanNumber.replaceAll('+212', '0')}',
      ];
      
      bool launched = false;
      for (String urlFormat in urlFormats) {
        try {
          final url = Uri.parse(urlFormat);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            launched = true;
            break;
          }
        } catch (e) {
          print('Erreur avec le format $urlFormat: $e');
          continue;
        }
      }
      
      if (!launched) {
        // Dernière tentative avec un format simple
        try {
          final simpleUrl = Uri.parse('tel:${cleanNumber.replaceAll(RegExp(r'[^\d]'), '')}');
          if (await canLaunchUrl(simpleUrl)) {
            await launchUrl(simpleUrl, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Aucun format d\'URL valide trouvé');
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir l\'application téléphone pour: $cleanNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'appel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trajet du Camion'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          // Bouton de chat
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatView(reservation: widget.reservation),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            tooltip: 'Chat avec le transporteur',
          ),
          // Bouton d'appel
          if (widget.reservation.transporteurPhone.isNotEmpty)
            IconButton(
              onPressed: _callTransporteur,
              icon: const Icon(Icons.phone),
              tooltip: 'Appeler le transporteur',
            ),
          // Bouton de simulation (existant)
          if (camionId != null)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _simulateCamionMovement(),
              tooltip: 'Simuler le mouvement du camion',
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : FlutterMap(
                  mapController: mapController, // Ajouté
                  options: MapOptions(
                    bounds: (departCoord != null && arriveeCoord != null)
                        ? LatLngBounds(departCoord!, arriveeCoord!)
                        : null,
                    boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(80)),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.flutter_application_1',
                    ),
                    if (departCoord != null && arriveeCoord != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints.isNotEmpty ? routePoints : [departCoord!, arriveeCoord!],
                            color: Colors.blue,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    if (departCoord != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: departCoord!,
                            width: 50,
                            height: 50,
                            child: camionIcon ?? Image.asset('assets/truck_top.png'),
                          ),
                        ],
                      ),
                    if (arriveeCoord != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: arriveeCoord!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.flag, color: Colors.red, size: 32),
                          ),
                        ],
                      ),
                  ],
                ),
      floatingActionButton: (departCoord != null)
          ? FloatingActionButton(
              onPressed: () {
                mapController.move(departCoord!, 16); // Zoom fort sur le camion
              },
              backgroundColor: const Color(0xFF1E3A8A),
              child: const Icon(Icons.center_focus_strong, color: Colors.white),
              tooltip: 'Centrer sur le camion',
            )
          : null,
    );
  }
} 