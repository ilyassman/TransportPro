import 'package:flutter/material.dart';
import '../../models/reservation_display_model.dart';
import '../../services/profile_service.dart';
import '../../services/translation_service.dart';
import '../../services/reservation_service.dart';
import 'trajet_camion_view.dart';

class SuivreView extends StatefulWidget {
  const SuivreView({super.key});

  @override
  State<SuivreView> createState() => _SuivreViewState();
}

class _SuivreViewState extends State<SuivreView> {
  List<ReservationDisplay> reservations = [];
  String? selectedStatus;
  bool isLoading = false;
  final ReservationService _reservationService = ReservationService();

  @override
  void initState() {
    super.initState();
    // Charger automatiquement les réservations au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservations();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger automatiquement quand la vue devient visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReservations();
      }
    });
  }

  Future<void> _loadReservations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final reservationsData = await _reservationService.getUserReservations();
      setState(() {
        reservations = reservationsData.map((data) => _mapToReservationDisplay(data)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des réservations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadReservationsByStatus(String? status) async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> reservationsData;
      if (status == null) {
        reservationsData = await _reservationService.getUserReservations();
      } else {
        reservationsData = await _reservationService.getUserReservationsByStatus(status);
      }
      setState(() {
        reservations = reservationsData.map((data) => _mapToReservationDisplay(data)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des réservations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ReservationDisplay _mapToReservationDisplay(Map<String, dynamic> data) {
    return ReservationDisplay(
      id: data['id'] ?? 0,
      status: data['statut'] ?? 'EN_ATTENTE',
      lieuDepart: data['lieuDepart'] ?? '',
      lieuArrivee: data['lieuArrivee'] ?? '',
      transporteurNom: data['camion']?['transporteur']?['username'] ?? 'Transporteur inconnu',
      transporteurPhone: data['camion']?['transporteur']?['phone'] ?? '',
      transporteurId: data['camion']?['transporteur']?['id'] ?? 0, // Ajouté
      rating: 4.5, // Note par défaut, à adapter selon vos besoins
      dateReservation: DateTime.parse(data['dateReservation'] ?? DateTime.now().toIso8601String()),
      typeMarchandise: data['typeMarchandise'] ?? 'Normal',
      poids: (data['poids'] ?? 0).toDouble(),
      volume: (data['volume'] ?? 0).toDouble(),
      camionId: data['camion'] != null ? data['camion']['id'] as int : 0,
    );
  }

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  String _getStatusText(String status) {
    // Pour l'affichage de l'interface (traduction)
    switch (status.toLowerCase()) {
      case 'confirmé':
      case 'confirmed':
      case 'confirme':
        return _getText('reservation_status_confirmed');
      case 'en cours':
      case 'in progress':
      case 'en_cours':
        return _getText('reservation_status_in_progress');
      case 'en transit':
      case 'in transit':
      case 'en_transit':
        return _getText('reservation_status_in_transit');
      case 'livré':
      case 'delivered':
      case 'terminee':
        return _getText('reservation_status_delivered');
      case 'en attente':
      case 'pending':
      case 'en_attente':
        return _getText('reservation_status_pending');
      default:
        return status;
    }
  }

  // Nouvelle fonction pour obtenir le statut en français pour la BDD
  String _getStatusForDB(String status) {
    // Pour la base de données (toujours en français)
    switch (status.toLowerCase()) {
      case 'confirmé':
      case 'confirmed':
      case 'confirme':
        return 'Confirmé';
      case 'en cours':
      case 'in progress':
      case 'en_cours':
        return 'En cours';
      case 'en transit':
      case 'in transit':
      case 'en_transit':
        return 'En transit';
      case 'livré':
      case 'delivered':
      case 'terminee':
        return 'Livré';
      case 'en attente':
      case 'pending':
      case 'en_attente':
        return 'En attente';
      default:
        return status;
    }
  }

  // === Ajout logique ville depuis code postal ===
  static const Map<String, String> _codePostalToVille = {
    '32000': 'Al Hoceïma',
    '22000': 'Azilal',
    '43150': 'Ben Guerir',
    '13000': 'Benslimane',
    '26100': 'Berrechid',
    '87200': 'Biougra',
    '71000': 'Boujdour',
    '33000': 'Boulemane',
    '91000': 'Chefchaouen',
    '41000': 'Chichaoua',
    '73000': 'Dakhla',
    '52000': 'Errachidia',
    '44000': 'Essaouira',
    '61000': 'Figuig',
    '81000': 'Guelmim',
    '53000': 'Ifrane',
    '43000': 'El Kelaâ des Sraghna',
    '92000': 'Larache',
    '45000': 'Ouarzazate',
    '26000': 'Settat',
    '31000': 'Séfrou',
    '85200': 'Sidi Ifni',
    '16000': 'Sidi Kacem',
    '14200': 'Sidi Slimane',
    '72000': 'Es-Semara',
    '34000': 'Taounate',
    '82000': 'Tan-Tan',
    '83000': 'Taroudant',
    '84000': 'Tata',
    '85000': 'Tiznit',
    // ... (ajoute d'autres codes uniques ici)
  };

  String? _villeDepuisCodePostal(String codePostal) {
    if (_codePostalToVille.containsKey(codePostal)) {
      return _codePostalToVille[codePostal];
    }
    final int cp = int.tryParse(codePostal) ?? -1;
    if (cp >= 20000 && cp <= 20999) return 'Casablanca';
    if (cp >= 10000 && cp <= 10999) return 'Rabat';
    if (cp >= 11000 && cp <= 11999) return 'Salé';
    if (cp >= 40000 && cp <= 40999) return 'Marrakech';
    if (cp >= 30000 && cp <= 30999) return 'Fès';
    if (cp >= 90000 && cp <= 90999) return 'Tanger';
    if (cp >= 14000 && cp <= 14999) return 'Kénitra';
    if (cp >= 15000 && cp <= 15999) return 'Khémisset';
    if (cp >= 25000 && cp <= 25999) return 'Khouribga';
    if (cp >= 24000 && cp <= 24999) return 'El Jadida';
    if (cp >= 50000 && cp <= 50999) return 'Meknès';
    if (cp >= 60000 && cp <= 60999) return 'Oujda';
    if (cp >= 28800 && cp <= 28899) return 'Mohammédia';
    if (cp >= 62000 && cp <= 62999) return 'Nador';
    if (cp >= 46000 && cp <= 46999) return 'Safi';
    if (cp >= 35000 && cp <= 35999) return 'Taza';
    if (cp >= 12000 && cp <= 12999) return 'Témara';
    if (cp >= 93000 && cp <= 93999) return 'Tétouan';
    if (cp >= 80100 && cp <= 80199) return 'Inezgane';
    if (cp >= 86300 && cp <= 86399) return 'Inezgane';
    if (cp >= 23000 && cp <= 23999) return 'Béni Mellal';
    if (cp >= 63300 && cp <= 63399) return 'Berkane';
    return null;
  }

  String? _extractCodePostal(String address) {
    final regex = RegExp(r'\b\d{5}\b');
    final match = regex.firstMatch(address);
    return match?.group(0);
  }

  String _villeDepuisAdresse(String address) {
    final codePostal = _extractCodePostal(address);
    if (codePostal != null) {
      return _villeDepuisCodePostal(codePostal) ?? codePostal;
    }
    return '';
  }

  bool _isTrackable(String status) {
    final s = status.toUpperCase();
    return s == 'CONFIRME' || s == 'EN_COURS' || s == 'EN_TRANSIT' || s == 'TERMINEE';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(
              child: _buildReservationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
          ),
          Expanded(
            child: Text(
              _getText('reservations_title'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              _loadReservations(); // Rafraîchir les données
            },
            icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(_getText('all'), null),
            const SizedBox(width: 8),
            _buildFilterChip(_getText('reservation_status_pending'), 'EN_ATTENTE'),
            const SizedBox(width: 8),
            _buildFilterChip(_getText('reservation_status_confirmed'), 'CONFIRME'),
            const SizedBox(width: 8),
            _buildFilterChip(_getText('reservation_status_in_progress'), 'EN_COURS'),
            const SizedBox(width: 8),
            _buildFilterChip(_getText('reservation_status_in_transit'), 'EN_TRANSIT'),
            const SizedBox(width: 8),
            _buildFilterChip(_getText('reservation_status_delivered'), 'TERMINEE'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = selectedStatus == status;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF6B7280),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStatus = selected ? status : null;
        });
        _loadReservationsByStatus(selected ? status : null);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1E3A8A),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE5E7EB),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildReservationsList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E3A8A),
        ),
      );
    }

    if (filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getText('no_reservations_found'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredReservations.length,
        itemBuilder: (context, index) {
          final reservation = filteredReservations[index];
          return _buildReservationCard(reservation, index);
        },
      ),
    );
  }

  List<ReservationDisplay> get filteredReservations {
    if (selectedStatus == null) return reservations;
    return reservations.where((r) => r.status.toUpperCase() == selectedStatus!.toUpperCase()).toList();
  }

  Widget _buildReservationCard(ReservationDisplay reservation, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: reservation.getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                reservation.getStatusIcon(),
                color: reservation.getStatusColor(),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: reservation.getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusText(reservation.status),
                          style: TextStyle(
                            color: reservation.getStatusColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${reservation.dateReservation.day}/${reservation.dateReservation.month}/${reservation.dateReservation.year}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // Affiche uniquement la ville extraite de l'adresse
                    '${_villeDepuisAdresse(reservation.lieuDepart)} → ${_villeDepuisAdresse(reservation.lieuArrivee)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        reservation.transporteurNom,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        reservation.rating.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${reservation.poids.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${reservation.volume.toStringAsFixed(1)} m³',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reservation.typeMarchandise,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: (_isTrackable(reservation.status))
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrajetCamionView(reservation: reservation),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTrackable(reservation.status)
                    ? const Color(0xFF1E3A8A)
                    : Colors.grey[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
              ),
              child: Text(
                _getText('track_button'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackingDialog(ReservationDisplay reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getText('tracking_title')} - ${reservation.lieuDepart} → ${reservation.lieuArrivee}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getText('carrier_label')}: ${reservation.transporteurNom}'),
            const SizedBox(height: 8),
            Text('${_getText('status_label')}: ${_getStatusText(reservation.status)}'),
            const SizedBox(height: 8),
            Text('${_getText('rating_label')}: ${reservation.rating} ⭐'),
            const SizedBox(height: 16),
            Text(
              _getText('tracking_feature_coming'),
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_getText('close')),
          ),
        ],
      ),
    );
  }
} 