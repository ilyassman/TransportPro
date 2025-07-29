import 'package:flutter/material.dart';
import '../../models/camion_model.dart';
import 'dart:math';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../../services/translation_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class ReservationDraft {
  final int reservationId;
  final String lieuDepart;
  final String lieuArrivee;
  final DateTime dateReservation;
  final String typeMarchandise;
  final double poids;
  final double volume;

  ReservationDraft({
    required this.reservationId,
    required this.lieuDepart,
    required this.lieuArrivee,
    required this.dateReservation,
    required this.typeMarchandise,
    required this.poids,
    required this.volume,
  });
}

class CamionSearchResultsPage extends StatefulWidget {
  final ReservationDraft reservationDraft;
  final List<Camion> camions;
  const CamionSearchResultsPage({Key? key, required this.reservationDraft, required this.camions}) : super(key: key);

  @override
  State<CamionSearchResultsPage> createState() => _CamionSearchResultsPageState();
}

class _CamionSearchResultsPageState extends State<CamionSearchResultsPage> {
  late List<Camion> filteredCamions;
  String? selectedType;
  String? selectedMarque;
  double? minCapacite;
  String sortBy = 'capacite+'; // 'capacite+', 'capacite-'
  WebSocketChannel? _channel;
  bool _waitingForResponse = true;

  // Suppression du calcul de distance et extraction de coordonnées
  void _applySort() {
    setState(() {
      if (sortBy == 'capacite+') {
        filteredCamions.sort((a, b) => a.capacite.compareTo(b.capacite));
      } else if (sortBy == 'capacite-') {
        filteredCamions.sort((a, b) => b.capacite.compareTo(a.capacite));
      }
    });
  }

  void _connectWebSocket() {
    print('Connexion au WebSocket...');
    final wsUrl = 'ws://10.0.2.2:8082/ws/camions';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    _channel!.stream.listen(
      (message) {
        print('Message reçu du WebSocket: $message');
        try {
          final data = jsonDecode(message);
          // Ignorer les messages qui ne sont pas du type RESERVATION_ACCEPTED
          if (data['type'] != 'RESERVATION_ACCEPTED') {
            return;
          }
          
          if (data['camion'] != null) {
            final camionData = data['camion'];
            final nouveauCamion = Camion(
              id: camionData['id'],
              immatriculation: camionData['immatriculation'],
              type: camionData['type'],
              capacite: camionData['capacite'].toDouble(),
              marque: camionData['marque'],
              modele: camionData['modele'],
              disponible: camionData['disponible'],
              latitude: camionData['latitude'],
              longitude: camionData['longitude'],
            );
            
            setState(() {
              _waitingForResponse = false;
              // Vérifier si le camion existe déjà dans la liste
              bool camionExists = filteredCamions.any((c) => c.id == nouveauCamion.id);
              if (!camionExists) {
                // Ajouter le nouveau camion uniquement s'il n'existe pas déjà
                filteredCamions.add(nouveauCamion);
                _applySort(); // Appliquer le tri si nécessaire
              }
            });
          }
        } catch (e) {
          print('Erreur de décodage du message: $e');
        }
      },
      onError: (error) {
        print('Erreur WebSocket: $error');
        setState(() {
          _waitingForResponse = false;
        });
      },
      onDone: () {
        print('WebSocket fermé');
        setState(() {
          _waitingForResponse = false;
        });
      }
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialiser avec une liste vide pour n'avoir que les camions du WebSocket
    filteredCamions = [];
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  void _openFilterSheet() async {
    final types = widget.camions.map((c) => c.type).toSet().toList();
    final marques = widget.camions.map((c) => c.marque).toSet().toList();
    String? tempType = selectedType;
    String? tempMarque = selectedMarque;
    double? tempMinCapacite = minCapacite;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 8),
                  Text(_getText('filters'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedType = null;
                        selectedMarque = null;
                        minCapacite = null;
                        filteredCamions = List.from(widget.camions);
                      });
                      Navigator.pop(context);
                    },
                    child: Text(_getText('reset')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: tempType,
                items: [DropdownMenuItem<String?>(value: null, child: Text(_getText('type_label')))] +
                    types.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t))).toList(),
                onChanged: (v) => tempType = v,
                decoration: InputDecoration(labelText: _getText('type_label')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: tempMarque,
                items: [DropdownMenuItem<String?>(value: null, child: Text(_getText('brand_label')))] +
                    marques.map((m) => DropdownMenuItem<String?>(value: m, child: Text(m))).toList(),
                onChanged: (v) => tempMarque = v,
                decoration: InputDecoration(labelText: _getText('brand_label')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: tempMinCapacite?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _getText('min_capacity_label')),
                onChanged: (v) => tempMinCapacite = double.tryParse(v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedType = tempType;
                    selectedMarque = tempMarque;
                    minCapacite = tempMinCapacite;
                    filteredCamions = widget.camions.where((c) {
                      final typeOk = selectedType == null || c.type == selectedType;
                      final marqueOk = selectedMarque == null || c.marque == selectedMarque;
                      final capaciteOk = minCapacite == null || c.capacite >= minCapacite!;
                      return typeOk && marqueOk && capaciteOk;
                    }).toList();
                  });
                  Navigator.pop(context);
                },
                child: Text(_getText('apply')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_getText('search'), style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildFilters(context),
          Expanded(child: _buildCamionList(context)),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CamionSearchResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ne pas réinitialiser la liste des camions lors de la mise à jour du widget
  }

  // Map code postal -> ville (extrait, à compléter)
  static const Map<String, String> codePostalToVille = {
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

  String? villeDepuisCodePostal(String codePostal) {
    if (codePostalToVille.containsKey(codePostal)) {
      return codePostalToVille[codePostal];
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

  String? extractCodePostal(String address) {
    final regex = RegExp(r'\b\d{5}\b');
    final match = regex.firstMatch(address);
    return match != null ? match.group(0) : null;
  }

  String villeDepuisAdresse(String address) {
    final codePostal = extractCodePostal(address);
    if (codePostal != null) {
      return villeDepuisCodePostal(codePostal) ?? codePostal;
    }
    return '';
  }

  Widget _buildHeader(BuildContext context) {
    final villeDepart = villeDepuisAdresse(widget.reservationDraft.lieuDepart);
    final villeArrivee = villeDepuisAdresse(widget.reservationDraft.lieuArrivee);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: const Color(0xFF1E3A8A), size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '$villeDepart → $villeArrivee',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.reservationDraft.dateReservation.day} ${_monthName(widget.reservationDraft.dateReservation.month)} ${widget.reservationDraft.dateReservation.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.inventory_2, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('${widget.reservationDraft.typeMarchandise} · ${widget.reservationDraft.poids} kg', style: const TextStyle(color: Colors.blueGrey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.filter_list, size: 18),
            label: Text(_getText('filter')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3A8A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Color(0xFF1E3A8A), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.sort, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: sortBy,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'capacite+', child: Text('Capacité croissante')),
                      DropdownMenuItem(value: 'capacite-', child: Text('Capacité décroissante')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          sortBy = v;
                        });
                        _applySort();
                      }
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamionList(BuildContext context) {
    if (_waitingForResponse) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 20),
            Text(
              _getText('waiting_for_truck'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      itemCount: filteredCamions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final camion = filteredCamions[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + index * 80),
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
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar camion
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF1E3A8A).withOpacity(0.18),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.local_shipping, size: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 18),
                  // Infos camion
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Badge type
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: camion.type == 'FTL' ? Color(0xFF3B82F6) : Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                camion.type,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          camion.marque,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          camion.modele,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.scale, color: Color(0xFF3B82F6), size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${camion.capacite.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 2),
                            Text(
                              (4.2 + index * 0.1).toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () async {
                                  try {
                                    // Mettre à jour la réservation existante avec l'ID du camion choisi
                                    await ReservationService().updateReservation(
                                      widget.reservationDraft.reservationId,
                                      camion.id,false
                                    );
                                    // Afficher le message de succès
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(_getText('reservation_success')),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                    await Future.delayed(const Duration(milliseconds: 1500));
                                    Navigator.of(context).pushReplacementNamed('/chargeur-home');
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${_getText('reservation_error')} $e'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  _getText('reserve_now'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _monthName(int month) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month];
  }
} 