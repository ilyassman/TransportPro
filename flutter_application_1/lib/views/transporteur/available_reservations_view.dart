import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/available_reservation_controller.dart';
import '../../models/available_reservation_model.dart';
import '../../services/translation_service.dart';
import 'reservation_details_view.dart';
import 'my_reservations_view.dart';
import '../../utils/ville_utils.dart';

class AvailableReservationsView extends StatefulWidget {
  const AvailableReservationsView({super.key});

  @override
  State<AvailableReservationsView> createState() => _AvailableReservationsViewState();
}

class _AvailableReservationsViewState extends State<AvailableReservationsView> with SingleTickerProviderStateMixin {
  final AvailableReservationController controller = Get.put(AvailableReservationController());
  late TabController _tabController;
  int _currentTabIndex = 0;

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fond avec gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF3B82F6),
                  Color(0xFF60A5FA),
                ],
              ),
            ),
          ),
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                                 // Menu principal avec onglets - Style amélioré
                 Container(
                   margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                   padding: const EdgeInsets.all(24),
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
                     children: [
                       // Titre du menu
                       Row(
                         children: [
                           Icon(
                             Icons.list_alt,
                             color: const Color(0xFF1E3A8A),
                             size: 24,
                           ),
                           const SizedBox(width: 12),
                           Text(
                             'Gestion des réservations',
                             style: const TextStyle(
                               color: Color(0xFF1E293B),
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                               fontFamily: 'Montserrat',
                             ),
                           ),
                           const Spacer(),
                           Container(
                             decoration: BoxDecoration(
                               color: const Color(0xFF1E3A8A),
                               borderRadius: BorderRadius.circular(12),
                               boxShadow: [
                                 BoxShadow(
                                   color: const Color(0xFF1E3A8A).withOpacity(0.3),
                                   blurRadius: 8,
                                   offset: const Offset(0, 4),
                                 ),
                               ],
                             ),
                             child: IconButton(
                               onPressed: () => controller.refresh(),
                               icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
                               padding: const EdgeInsets.all(12),
                               tooltip: 'Actualiser',
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 20),
                       // Onglets stylisés
                       Container(
                         height: 50,
                         decoration: BoxDecoration(
                           color: const Color(0xFFF8FAFC),
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(
                             color: const Color(0xFFE2E8F0),
                             width: 1,
                           ),
                         ),
                         child: TabBar(
                           controller: _tabController,
                           indicator: BoxDecoration(
                             color: const Color(0xFF1E3A8A),
                             borderRadius: BorderRadius.circular(12),
                             boxShadow: [
                               BoxShadow(
                                 color: const Color(0xFF1E3A8A).withOpacity(0.3),
                                 blurRadius: 8,
                                 offset: const Offset(0, 2),
                               ),
                             ],
                           ),
                           labelColor: Colors.white,
                           unselectedLabelColor: const Color(0xFF64748B),
                           labelStyle: const TextStyle(
                             fontWeight: FontWeight.w600,
                             fontSize: 10,
                             fontFamily: 'Montserrat',
                             letterSpacing: 0.1,
                           ),
                           unselectedLabelStyle: const TextStyle(
                             fontWeight: FontWeight.w500,
                             fontSize: 10,
                             fontFamily: 'Montserrat',
                             letterSpacing: 0.1,
                           ),
                           indicatorSize: TabBarIndicatorSize.tab,
                           dividerColor: Colors.transparent,
                           tabs: [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.public, size: 12),
                                    const SizedBox(width: 3),
                                    const Text('Toutes les réservations'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person, size: 12),
                                    const SizedBox(width: 3),
                                    const Text('Mes réservations'),
                                  ],
                                ),
                              ),
                            ],
                         ),
                       ),
                     ],
                   ),
                 ),
                // Contenu avec onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet "Toutes les réservations"
                      Obx(() {
                        if (controller.isLoading.value) {
                          return _buildLoadingState();
                        }
                        
                        if (controller.reservations.isEmpty) {
                          return _buildEmptyState();
                        }
                        
                        return _buildReservationsList();
                      }),
                      // Onglet "Mes réservations"
                      _buildMyReservationsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              'Chargement des réservations...',
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
              'Aucune réservation en attente',
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune réservation avec le statut sélectionné n\'est disponible pour le moment.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => controller.refresh(),
              child: const Text(
                'Actualiser',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: controller.reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final reservation = controller.reservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(AvailableReservation reservation) {
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
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, color: Colors.white, size: 12),
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
              Column(
                children: [
                  // Bouton "Voir détails"
                  SizedBox(
                    width: double.infinity,
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
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Voir détails',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Boutons de proposition
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptReservation(reservation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
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
                              const Icon(Icons.check, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Accepter',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _proposeCustomPrice(reservation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
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
                              const Icon(Icons.edit, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Proposer tarif',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
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
            ],
          ),
        ),
      ),
    );
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

  Widget _buildMyReservationsTab() {
    return MyReservationsView();
  }

  Future<void> _acceptReservation(AvailableReservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter la réservation'),
        content: Text(
          'Êtes-vous sûr de vouloir accepter cette mission au tarif proposé ?\n\n'
          'Départ: ${VilleUtils.villeDepuisAdresse(reservation.lieuDepart)}\n'
          'Arrivée: ${VilleUtils.villeDepuisAdresse(reservation.lieuArrivee)}\n'
          'Tarif: ${reservation.getFormattedTarif()}\n\n'
          'Votre proposition sera envoyée au chargeur pour validation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.proposeForReservation(reservation.id);
      
      if (success) {
        // Optionnel : retirer la réservation de la liste ou la marquer comme proposée
        // Pour l'instant, on laisse la réservation visible
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

  Future<void> _proposeCustomPrice(AvailableReservation reservation) async {
    final TextEditingController priceController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    double? proposedPrice;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proposer un tarif personnalisé'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Départ: ${VilleUtils.villeDepuisAdresse(reservation.lieuDepart)}\n'
                'Arrivée: ${VilleUtils.villeDepuisAdresse(reservation.lieuArrivee)}\n'
                'Tarif original: ${reservation.getFormattedTarif()}\n\n'
                'Proposez votre tarif :',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tarif proposé (DH)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un tarif';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Veuillez entrer un tarif valide';
                  }
                  return null;
                },
                onChanged: (value) {
                  proposedPrice = double.tryParse(value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
            child: const Text('Proposer'),
          ),
        ],
      ),
    );

    if (confirmed == true && proposedPrice != null) {
      final success = await controller.proposeForReservation(reservation.id, prixPropose: proposedPrice);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proposition avec tarif ${proposedPrice!.toStringAsFixed(2)} DH envoyée avec succès !'),
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
} 