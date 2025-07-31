import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/available_reservation_controller.dart';
import '../../models/available_reservation_model.dart';
import '../../services/translation_service.dart';
import 'reservation_details_view.dart';
import '../../models/reservation_display_model.dart'; // Correction de l'import
import '../../utils/ville_utils.dart';

class MyReservationsView extends StatefulWidget {
  const MyReservationsView({super.key});

  @override
  State<MyReservationsView> createState() => _MyReservationsViewState();
}

class _MyReservationsViewState extends State<MyReservationsView> with SingleTickerProviderStateMixin {
  final AvailableReservationController controller = Get.find<AvailableReservationController>();
  late TabController _statusTabController;
  String _selectedStatus = 'CONFIRME';

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 3, vsync: this); // Changé de 4 à 3
    _selectedStatus = _getStatusOptions().first; // Sera maintenant 'EN_COURS'
    
    // Ajouter un listener pour gérer les changements d'onglets
    _statusTabController.addListener(() {
      if (_statusTabController.indexIsChanging) {
        final newStatus = _getStatusOptions()[_statusTabController.index];
        setState(() {
          _selectedStatus = newStatus;
        });
        _loadMyReservations();
      }
    });
    
    _loadMyReservations();
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyReservations() async {
    await controller.loadMyReservationsByStatus(_selectedStatus);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRME':
        return const Color(0xFF10B981); // Vert
      case 'EN_COURS':
        return const Color(0xFFF59E0B); // Orange
      case 'EN_TRANSIT':
        return const Color(0xFF3B82F6); // Bleu
      case 'TERMINEE':
        return const Color(0xFF6B7280); // Gris
      default:
        return const Color(0xFF64748B); // Gris par défaut
    }
  }

  String _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRME':
        return '✓';
      case 'EN_COURS':
        return '🔄';
      case 'EN_TRANSIT':
        return '🚚';
      case 'TERMINEE':
        return '🏁';
      default:
        return '⏳';
    }
  }
  
  Color _getStatusIconColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRME':
        return const Color(0xFF10B981);
      case 'EN_COURS':
        return const Color(0xFFF59E0B);
      case 'EN_TRANSIT':
        return const Color(0xFF3B82F6);
      case 'TERMINEE':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF64748B);
    }
  }

  List<String> _getStatusOptions() {
    return ['EN_COURS', 'EN_TRANSIT', 'TERMINEE'];
  }

  List<AvailableReservation> _getFilteredReservations() {
    return controller.reservations.where((r) => r.statut.toUpperCase() == _selectedStatus).toList();
  }

  Future<void> _changeReservationStatus(AvailableReservation reservation, String newStatus) async {
    try {
      final success = await controller.updateReservationStatus(reservation.id, newStatus);
      
      if (success) {
        // Recharger les réservations
        await _loadMyReservations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du changement de statut: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtres par statut - Style amélioré
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre avec icône
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: const Color(0xFF1E3A8A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtrer par statut',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Onglets de statut stylisés
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: TabBar(
                   controller: _statusTabController,
                   isScrollable: true,
                   indicator: BoxDecoration(
                     color: const Color(0xFF1E3A8A),
                     borderRadius: BorderRadius.circular(10),
                     boxShadow: [
                       BoxShadow(
                         color: const Color(0xFF1E3A8A).withOpacity(0.3),
                         blurRadius: 6,
                         offset: const Offset(0, 2),
                       ),
                     ],
                   ),
                   labelColor: Colors.white,
                   unselectedLabelColor: const Color(0xFF64748B),
                   labelStyle: const TextStyle(
                     fontWeight: FontWeight.w600,
                     fontSize: 12,
                     fontFamily: 'Montserrat',
                     letterSpacing: 0.2,
                   ),
                   unselectedLabelStyle: const TextStyle(
                     fontWeight: FontWeight.w500,
                     fontSize: 12,
                     fontFamily: 'Montserrat',
                     letterSpacing: 0.2,
                   ),
                   indicatorSize: TabBarIndicatorSize.tab,
                   dividerColor: Colors.transparent,
                   tabs: _getStatusOptions().map((status) {
                     return Tab(
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text(
                               _getStatusIcon(status),
                               style: TextStyle(
                                 color: _getStatusIconColor(status),
                                 fontSize: 14,
                               ),
                             ),
                             const SizedBox(width: 4),
                             Text(
                               status,
                               style: const TextStyle(
                                 fontSize: 11,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ],
                         ),
                       ),
                     );
                   }).toList(),
                 ),
              ),
            ],
          ),
        ),
        // Liste des réservations
        Expanded(
          child: Obx(() {
            final filteredReservations = _getFilteredReservations();
            
            if (controller.isLoading.value) {
              return _buildLoadingState();
            }
            
            if (filteredReservations.isEmpty) {
              return _buildEmptyState();
            }
            
            return _buildMyReservationsList(filteredReservations);
          }),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement de vos réservations...',
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
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
              Icons.inbox_outlined,
              color: const Color(0xFF64748B),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune réservation trouvée',
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune réservation avec le statut "$_selectedStatus".',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyReservationsList(List<AvailableReservation> reservations) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return _buildMyReservationCard(reservation);
      },
    );
  }

  Widget _buildMyReservationCard(AvailableReservation reservation) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec statut et chargeur
              Row(
                children: [
                  // Badge statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reservation.statut),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getStatusIcon(reservation.statut),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation.statut.toUpperCase(),
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
                  // Nom du chargeur
                  Row(
                    children: [
                      Text(
                        reservation.chargeurNom,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.person,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Informations essentielles
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Départ',
                      VilleUtils.villeDepuisAdresse(reservation.lieuDepart),
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
                    child: _buildInfoColumn(
                      'Arrivée',
                      VilleUtils.villeDepuisAdresse(reservation.lieuArrivee),
                      Icons.location_on,
                      const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tarif et type de marchandise
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Tarif',
                      reservation.getFormattedTarif(),
                      Icons.attach_money,
                      textColor: Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Type',
                      reservation.typeMarchandise,
                      Icons.inventory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewDetails(reservation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.visibility, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Détails',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openChat(reservation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Chat',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChangeButton(AvailableReservation reservation) {
    String nextStatus = _getNextStatus(reservation.statut);
    Color buttonColor = _getStatusColor(nextStatus);
    
    return ElevatedButton(
      onPressed: () => _showStatusChangeDialog(reservation),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getStatusIcon(nextStatus),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            'Changer statut',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'CONFIRME':
        return 'EN_COURS';
      case 'EN_COURS':
        return 'EN_TRANSIT';
      case 'EN_TRANSIT':
        return 'TERMINEE';
      default:
        return 'EN_COURS';
    }
  }

  Future<void> _showStatusChangeDialog(AvailableReservation reservation) async {
    final String nextStatus = _getNextStatus(reservation.statut);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le statut vers $nextStatus'),
        content: Text(
          'Êtes-vous sûr de vouloir changer le statut de cette réservation ?\n\n'
          'Statut actuel: ${reservation.statut}\n'
          'Nouveau statut: $nextStatus\n\n'
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
              backgroundColor: _getStatusColor(nextStatus),
            ),
            child: Text('Changer vers $nextStatus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _changeReservationStatus(reservation, nextStatus);
    }
  }

  Widget _buildInfoColumn(String label, String value, IconData icon, Color color) {
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
          value,
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

  Widget _buildDetailItem(String label, String value, IconData icon, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor ?? const Color(0xFF1E293B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _viewDetails(AvailableReservation reservation) async {
    final result = await Get.to(() => ReservationDetailsView(reservation: reservation));
    
    // Si l'utilisateur a proposé depuis la page de détails
    if (result == true) {
      final success = await controller.proposeForReservation(reservation.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proposition envoyée avec succès !'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi de la proposition'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openChat(AvailableReservation reservation) async {
    try {
      // Convertir AvailableReservation en ReservationDisplay pour la vue chat
      final reservationDisplay = ReservationDisplay(
        id: reservation.id,
        status: reservation.statut,
        lieuDepart: VilleUtils.villeDepuisAdresse(reservation.lieuDepart),
        lieuArrivee: VilleUtils.villeDepuisAdresse(reservation.lieuArrivee),
        transporteurNom: reservation.chargeurNom,
        transporteurPhone: '', // Pas de téléphone disponible
        transporteurId: reservation.chargeurId, // ID du chargeur
        rating: 4.5,
        dateReservation: reservation.dateReservation,
        typeMarchandise: reservation.typeMarchandise,
        poids: reservation.poids,
        volume: reservation.volume,
        camionId: 0, // Pas de camion pour les réservations du transporteur
      );
      
      Get.toNamed('/transporteur-chat', arguments: {
        'reservation': reservationDisplay,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture du chat: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
} 