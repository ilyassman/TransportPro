import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/available_reservation_model.dart';
import '../../services/translation_service.dart';
import '../../services/available_reservation_service.dart';
import 'transporteur_tracking_view.dart';
import '../../utils/ville_utils.dart';

class ReservationDetailsView extends StatefulWidget {
  final AvailableReservation reservation;

  const ReservationDetailsView({
    super.key,
    required this.reservation,
  });

  @override
  State<ReservationDetailsView> createState() => _ReservationDetailsViewState();
}

class _ReservationDetailsViewState extends State<ReservationDetailsView> {
  LatLng? departureLocation;
  LatLng? arrivalLocation;
  bool isLoadingMap = true;
  List<LatLng> routePoints = [];
  MapController mapController = MapController();
  final AvailableReservationService _reservationService = AvailableReservationService();

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  @override
  void initState() {
    super.initState();
    // Charger la carte de manière asynchrone pour ne pas bloquer l'interface
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMapData();
    });
  }

  Future<void> _loadMapData() async {
    try {
      // Géocoder les adresses pour obtenir les coordonnées
      final departureCoords = await _geocodeAddress(widget.reservation.lieuDepart);
      final arrivalCoords = await _geocodeAddress(widget.reservation.lieuArrivee);

      if (departureCoords != null && arrivalCoords != null) {
        setState(() {
          departureLocation = departureCoords;
          arrivalLocation = arrivalCoords;
          isLoadingMap = false;
        });

        // Charger les points de route (route réelle) de manière asynchrone
        _loadRoutePoints();
      } else {
        setState(() {
          isLoadingMap = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de la carte: $e');
      setState(() {
        isLoadingMap = false;
      });
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1'),
        headers: {'User-Agent': 'TransportPro/1.0'},
      ).timeout(const Duration(seconds: 5)); // Timeout de 5 secondes

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      print('Erreur géocodage: $e');
    }
    return null;
  }

  Future<void> _loadRoutePoints() async {
    if (departureLocation != null && arrivalLocation != null) {
      try {
        // Obtenir la vraie route routière via OSRM
        final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${departureLocation!.longitude},${departureLocation!.latitude};${arrivalLocation!.longitude},${arrivalLocation!.latitude}?overview=full&geometries=geojson'
        );
        
        final response = await http.get(
          url,
          headers: {'User-Agent': 'TransportPro/1.0'},
        ).timeout(const Duration(seconds: 10)); // Timeout de 10 secondes

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final geometry = route['geometry'];
            
            if (geometry['coordinates'] != null) {
              final coordinates = geometry['coordinates'] as List;
              final points = coordinates.map((coord) {
                return LatLng(coord[1].toDouble(), coord[0].toDouble());
              }).toList();
              
              setState(() {
                routePoints = points;
              });
              
              print('Route chargée avec ${points.length} points');
            }
          }
        }
      } catch (e) {
        print('Erreur lors du chargement de la route: $e');
        // Ne pas afficher d'erreur à l'utilisateur, juste continuer sans route
      }
    }
  }

  String _extractCityFromAddress(String address) {
    // Utiliser la logique d'extraction de ville depuis le code postal
    return VilleUtils.villeDepuisAdresse(address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Détails de la réservation',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        actions: [
          IconButton(
            onPressed: () {
              // Action pour proposer
            },
            icon: const Icon(Icons.send, color: Color(0xFF1E3A8A)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildMapSection(),
            _buildDetailsSection(),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      widget.reservation.statut.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Par ${widget.reservation.chargeurNom}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLocationInfo(
                  'Départ',
                  widget.reservation.lieuDepart,
                  Icons.location_on,
                  const Color(0xFFEF4444),
                ),
              ),
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Expanded(
                child: _buildLocationInfo(
                  'Arrivée',
                  widget.reservation.lieuArrivee,
                  Icons.location_on,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String label, String address, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _extractCityFromAddress(address),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 300,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isLoadingMap
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                ),
              )
                            : departureLocation != null && arrivalLocation != null
                    ? FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          center: LatLng(
                            (departureLocation!.latitude + arrivalLocation!.latitude) / 2,
                            (departureLocation!.longitude + arrivalLocation!.longitude) / 2,
                          ),
                          zoom: 10,
                        ),
                    children: [
                                             TileLayer(
                         urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                         userAgentPackageName: 'com.example.app',
                       ),
                                             // Marqueur de départ avec icône camion
                       MarkerLayer(
                         markers: [
                           Marker(
                             point: departureLocation!,
                             width: 40,
                             height: 40,
                             child: Container(
                               decoration: BoxDecoration(
                                 color: const Color(0xFF1E3A8A),
                                 shape: BoxShape.circle,
                                 border: Border.all(color: Colors.white, width: 2),
                               ),
                               child: const Icon(
                                 Icons.local_shipping,
                                 color: Colors.white,
                                 size: 20,
                               ),
                             ),
                           ),
                           // Marqueur d'arrivée
                           Marker(
                             point: arrivalLocation!,
                             width: 30,
                             height: 30,
                             child: Container(
                               decoration: BoxDecoration(
                                 color: const Color(0xFF10B981),
                                 shape: BoxShape.circle,
                                 border: Border.all(color: Colors.white, width: 2),
                               ),
                               child: const Icon(
                                 Icons.location_on,
                                 color: Colors.white,
                                 size: 16,
                               ),
                             ),
                           ),
                         ],
                       ),
                      // Ligne de route
                      if (routePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 3,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ],
                        ),
                    ],
                  )
                : const Center(
                    child: Text(
                      'Impossible de charger la carte',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de la mission',
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Type de marchandise', widget.reservation.typeMarchandise, Icons.inventory),
          const SizedBox(height: 12),
          _buildDetailRow('Volume', widget.reservation.getFormattedVolume(), Icons.straighten),
          const SizedBox(height: 12),
          _buildDetailRow('Poids', widget.reservation.getFormattedPoids(), Icons.scale),
          const SizedBox(height: 12),
          _buildDetailRow('Tarif proposé', widget.reservation.getFormattedTarif(), Icons.attach_money, textColor: Colors.amber),
          const SizedBox(height: 12),
          _buildDetailRow('Date de réservation', widget.reservation.getFormattedDate(), Icons.access_time),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? textColor}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: textColor ?? const Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bouton "Suivre" pour les réservations EN_TRANSIT
          if (widget.reservation.statut.toUpperCase() == 'EN_TRANSIT')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => _openTrackingView(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Suivre en direct',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Boutons de changement d'état selon la logique
          if (widget.reservation.statut.toUpperCase() == 'EN_COURS')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => _changeReservationStatus('EN_TRANSIT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_shipping, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Commencer le transport',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (widget.reservation.statut.toUpperCase() == 'EN_TRANSIT')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => _changeReservationStatus('TERMINEE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Marquer comme terminée',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Message informatif pour les réservations terminées
          if (widget.reservation.statut.toUpperCase() == 'TERMINEE')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mission terminée',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _changeReservationStatus(String newStatus) async {
    try {
      // Afficher un dialogue de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Changer le statut vers $newStatus'),
          content: Text(
            'Êtes-vous sûr de vouloir changer le statut de cette réservation ?\n\n'
            'Statut actuel: ${widget.reservation.statut}\n'
            'Nouveau statut: $newStatus\n\n'
            'Cette action ne peut pas être annulée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(newStatus),
              ),
              child: Text('Changer vers $newStatus'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          // Appeler l'API pour changer le statut
          final result = await _reservationService.updateReservationStatus(widget.reservation.id, newStatus);
          
          // Vérifier si la mise à jour a réussi
          // Le service peut retourner un Map avec différentes structures selon l'API
          bool success = false;
          if (result != null) {
            // Vérifier différentes possibilités de réponse
            if (result['success'] == true) {
              success = true;
            } else if (result['message'] != null) {
              // Si on a un message, c'est probablement un succès
              success = true;
            } else if (result['id'] != null) {
              // Si on a un ID retourné, c'est probablement un succès
              success = true;
            }
          }
          
          if (success) {
            // Afficher un message de succès
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Statut changé vers $newStatus avec succès !'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Retourner à la page précédente pour rafraîchir la liste
            Get.back();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors du changement de statut'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          print('Erreur lors du changement de statut: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors du changement de statut: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'EN_COURS':
        return const Color(0xFFF59E0B);
      case 'EN_TRANSIT':
        return const Color(0xFF3B82F6);
      case 'TERMINEE':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF1E3A8A);
    }
  }

  void _openTrackingView() {
    Get.to(() => TransporteurTrackingView(reservation: widget.reservation));
  }
} 