import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/profile_service.dart';
import 'package:flutter_application_1/services/translation_service.dart';
import 'package:flutter_application_1/services/camion_service.dart';
import 'package:flutter_application_1/services/reservation_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_picker_view.dart';
import '../../models/camion_model.dart';
import '../../models/reservation_model.dart';
import 'camion_search_results_page.dart';

class ReservationView extends StatefulWidget {
  const ReservationView({super.key});

  @override
  State<ReservationView> createState() => _ReservationViewState();
}

class _ReservationViewState extends State<ReservationView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _departController = TextEditingController();
  final TextEditingController _arriveeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _poidsController = TextEditingController();
  String _typeMarchandise = 'Normal';

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  // Méthode pour obtenir la valeur française pour la BDD
  String _getTypeMarchandiseForDB() {
    switch (_typeMarchandise.toLowerCase()) {
      case 'normal':
      case 'عادي':
        return 'Normal';
      case 'réfrigéré':
      case 'refrigerated':
      case 'مبرد':
        return 'Réfrigéré';
      default:
        return _typeMarchandise;
    }
  }

  // Méthode pour obtenir la valeur affichée (traduite)
  String _getTypeMarchandiseDisplay() {
    switch (_typeMarchandise.toLowerCase()) {
      case 'normal':
      case 'عادي':
        return _getText('normal');
      case 'réfrigéré':
      case 'refrigerated':
      case 'مبرد':
        return _getText('refrigerated');
      default:
        return _typeMarchandise;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE3E9F9), Color(0xFFD1D8F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String?>(
                    future: ProfileService().getCurrentUsername(),
                    builder: (context, snapshot) {
                      final username = snapshot.data ?? '';
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF1E3A8A),
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '',
                              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getText('TransportPro'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Montserrat'),
                          ),
                          const Spacer(),
                          // IconButton(
                          //   icon: const Icon(Icons.notifications_none),
                          //   onPressed: () {},
                          // ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _getText('new_reservation'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, fontFamily: 'Montserrat'),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _inputField(_departController, _getText('depart_place'), isLieu: true),
                        const SizedBox(height: 18),
                        _inputField(_arriveeController, _getText('arrival_place'), isLieu: true),
                        const SizedBox(height: 18),
                        _dateField(context),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _typeButton('Normal', _getText('normal')),
                            const SizedBox(width: 12),
                            _typeButton('Réfrigéré', _getText('refrigerated')),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(child: _inputField(_volumeController, _getText('volume'), keyboardType: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(child: _inputField(_poidsController, _getText('weight'), keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // Créer et sauvegarder la réservation d'abord
                                final reservation = ReservationModel(
                                  camionId: null,  // pas de camion pour l'instant
                                  lieuDepart: _departController.text,
                                  lieuArrivee: _arriveeController.text,
                                  dateReservation: DateTime.now(),
                                  typeMarchandise: _getTypeMarchandiseForDB(),
                                  poids: double.tryParse(_poidsController.text) ?? 0,
                                  volume: double.tryParse(_volumeController.text) ?? 0,
                                );

                                Map<String, dynamic> savedReservation;
                                try {
                                  savedReservation = await ReservationService().reserver(reservation);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(_getText('error_saving_reservation'))),
                                  );
                                  return;
                                }

                                // Extraire la latitude/longitude du lieu de départ via Nominatim
                                final address = _departController.text;
                                double? latitude;
                                double? longitude;
                                try {
                                  final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}');
                                  final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
                                  if (response.statusCode == 200) {
                                    final List data = json.decode(response.body);
                                    if (data.isNotEmpty) {
                                      latitude = double.tryParse(data[0]['lat'] ?? '');
                                      longitude = double.tryParse(data[0]['lon'] ?? '');
                                    }
                                  }
                                } catch (e) {
                                  print('Erreur géocodage: $e');
                                }

                                List<Camion> camions = [];
                                if (latitude != null && longitude != null) {
                                  try {
                                    camions = await CamionService().getCamionsProches(
                                      latitude: latitude,
                                      longitude: longitude,
                                      rayonKm: 10,
                                    );
                                  } catch (e) {
                                    print('Erreur recherche camions: $e');
                                  }
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CamionSearchResultsPage(
                                      reservationDraft: ReservationDraft(
                                        reservationId: savedReservation['id'],
                                        lieuDepart: _departController.text,
                                        lieuArrivee: _arriveeController.text,
                                        dateReservation: DateTime.now(),
                                        typeMarchandise: _getTypeMarchandiseForDB(),
                                        poids: double.tryParse(_poidsController.text) ?? 0,
                                        volume: double.tryParse(_volumeController.text) ?? 0,
                                      ),
                                      camions: camions,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              _getText('search_trucks'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, bool isLieu = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: isLieu,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Montserrat', color: Color(0xFF6B7280)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        suffixIcon: isLieu
            ? IconButton(
                icon: const Icon(Icons.map, color: Color(0xFF1E3A8A)),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapPickerView(title: 'Choisir $label'),
                    ),
                  );
                  if (result != null && result['address'] != null) {
                    setState(() {
                      controller.text = result['address'];
                    });
                  }
                },
              )
            : null,
      ),
      validator: (value) => value == null || value.isEmpty ? _getText('required_field') : null,
      onTap: isLieu
          ? () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapPickerView(title: 'Choisir $label'),
                ),
              );
              if (result != null && result['address'] != null) {
                setState(() {
                  controller.text = result['address'];
                });
              }
            }
          : null,
    );
  }

  Widget _dateField(BuildContext context) {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: _getText('loading_date'),
        labelStyle: const TextStyle(fontFamily: 'Montserrat', color: Color(0xFF6B7280)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Color(0xFF1E3A8A)),
          onPressed: () => _selectDate(context),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? _getText('required_field') : null,
    );
  }

  Widget _typeButton(String typeValue, String displayText) {
    final bool selected = _typeMarchandise == typeValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _typeMarchandise = typeValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
              width: 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              displayText,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 