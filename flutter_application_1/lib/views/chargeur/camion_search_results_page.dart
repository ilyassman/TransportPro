import 'package:flutter/material.dart';
import '../../models/camion_model.dart';

class ReservationDraft {
  final String lieuDepart;
  final String lieuArrivee;
  final DateTime dateReservation;
  final String typeMarchandise;
  final double poids;
  final double volume;

  ReservationDraft({
    required this.lieuDepart,
    required this.lieuArrivee,
    required this.dateReservation,
    required this.typeMarchandise,
    required this.poids,
    required this.volume,
  });
}

class CamionSearchResultsPage extends StatelessWidget {
  final ReservationDraft reservationDraft;
  final List<Camion> camions;
  const CamionSearchResultsPage({Key? key, required this.reservationDraft, required this.camions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Recherche', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
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
    final villeDepart = villeDepuisAdresse(reservationDraft.lieuDepart);
    final villeArrivee = villeDepuisAdresse(reservationDraft.lieuArrivee);
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
                    '${reservationDraft.dateReservation.day} ${_monthName(reservationDraft.dateReservation.month)} ${reservationDraft.dateReservation.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.inventory_2, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('${reservationDraft.typeMarchandise} · ${reservationDraft.poids} kg', style: const TextStyle(color: Colors.blueGrey)),
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
            onPressed: () {},
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text('Filtrer'),
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
                  const Text('Trier par', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Icon(Icons.expand_more, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamionList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      itemCount: camions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final camion = camions[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 110,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  color: const Color(0xFFE3E9F9),
                ),
                child: camion.type.toLowerCase().contains('camionnette')
                    ? Image.asset('assets/camionnette.png', fit: BoxFit.contain)
                    : Image.asset('assets/camion.png', fit: BoxFit.contain),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camion.type,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${camion.marque} ${camion.modele}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('${camion.capacite} kg', style: const TextStyle(color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 18),
                          const SizedBox(width: 4),
                          Text('4.${index + 2}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            onPressed: () {
                              // Action de réservation
                            },
                            child: const Text('Réserver Maintenante'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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