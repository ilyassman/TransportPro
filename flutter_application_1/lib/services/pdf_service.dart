import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';

class PdfService {
  static Future<void> generateReservationRecap(Map<String, dynamic> reservationData) async {
    try {
      // Demander les permissions
      await Permission.storage.request();
      
      // Créer le document PDF
      final pdf = pw.Document();
      
      // Ajouter la page principale
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (context) => [
            _buildHeader(reservationData),
            pw.SizedBox(height: 20),
            _buildMapSection(reservationData),
            pw.SizedBox(height: 20),
            _buildReservationDetails(reservationData),
            pw.SizedBox(height: 20),
            _buildTransporteurDetails(reservationData),
            pw.SizedBox(height: 20),
            _buildCamionDetails(reservationData),
            pw.SizedBox(height: 20),
            _buildFooter(reservationData),
          ],
        ),
      );
      
      // Sauvegarder le PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/recap_${reservationData['reservationId']}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Ouvrir le PDF
      await OpenFile.open(file.path);
      
    } catch (e) {
      print('Erreur lors de la génération du PDF: $e');
      throw Exception('Erreur lors de la génération du PDF');
    }
  }

  // Méthode de test avec des données d'exemple
  static Future<void> generateTestPdf() async {
    final testData = {
      'reservationId': 'RES-2024-001',
      'dateReservation': DateTime.now(),
      'statut': 'TERMINEE',
      'trajetInfo': 'Marrakech → Fès',
      'lieuDepart': 'Marrakech, 40000',
      'lieuArrivee': 'Fès, 30000',
      'typeMarchandise': 'Électronique',
      'poids': 1500.0,
      'volume': 25.5,
      'tarif': 2500.0,
      'modePaiement': 'Virement bancaire',
      'transporteurName': 'Transport Maroc Express',
      'transporteurCompany': 'Transport Maroc Express SARL',
      'transporteurPhone': '+212 6 12 34 56 78',
      'transporteurEmail': 'contact@transportmaroc.ma',
      'camionMarque': 'Mercedes-Benz',
      'camionModele': 'Actros',
      'camionImmatriculation': '12345-A-6',
      'camionCapacite': 25.0,
      'camionType': 'FTL',
    };
    
    await generateReservationRecap(testData);
  }

  // Méthode pour obtenir les coordonnées depuis une adresse
  static Future<Map<String, double>?> _getCoordinates(String address) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1'
      );
      final response = await http.get(url, headers: {'User-Agent': 'TransportPro'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final location = data[0];
          return {
            'lat': double.parse(location['lat']),
            'lon': double.parse(location['lon']),
          };
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des coordonnées: $e');
    }
    return null;
  }

  // Méthode pour obtenir l'itinéraire entre deux points
  static Future<List<Map<String, dynamic>>?> _getRoute(String startAddress, String endAddress) async {
    try {
      final startCoords = await _getCoordinates(startAddress);
      final endCoords = await _getCoordinates(endAddress);
      
      if (startCoords != null && endCoords != null) {
        final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${startCoords['lon']},${startCoords['lat']};${endCoords['lon']},${endCoords['lat']}?overview=full&geometries=geojson'
        );
        final response = await http.get(url, headers: {'User-Agent': 'TransportPro'});
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
            return coordinates.map((coord) => {
              'lat': coord[1].toDouble(),
              'lon': coord[0].toDouble(),
            }).toList();
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'itinéraire: $e');
    }
    return null;
  }
  
  static pw.Widget _buildHeader(Map<String, dynamic> data) {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(30),
            ),
            child: pw.Center(
              child: pw.Text(
                'TP',
                style: pw.TextStyle(
                  color: PdfColors.blue900,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RÉCAPITULATIF DE RÉSERVATION',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ID: ${data['reservationId']}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                  ),
                ),
                pw.Text(
                  'Date: ${_formatDate(data['dateReservation'])}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildMapSection(Map<String, dynamic> data) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 30,
                height: 30,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'M',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'ITINÉRAIRE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Lieu de départ
                pw.Row(
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Lieu de départ:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            _cleanAddress(data['lieuDepart'] ?? 'Non défini'),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                // Lieu d'arrivée
                pw.Row(
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Lieu d\'arrivée:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            _cleanAddress(data['lieuArrivee'] ?? 'Non défini'),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                // Trajet complet
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 20,
                        height: 20,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'T',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Text(
                          data['trajetInfo'] ?? 'Trajet non défini',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
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

  // Méthode pour nettoyer les adresses et éviter les caractères spéciaux
  static String _cleanAddress(String address) {
    if (address.isEmpty) return 'Non défini';
    
    // Nettoyer l'adresse
    String cleanAddress = address.trim();
    
    // Remplacer les caractères problématiques
    cleanAddress = cleanAddress.replaceAll('XXXXX', '');
    cleanAddress = cleanAddress.replaceAll('XXXX', '');
    cleanAddress = cleanAddress.replaceAll('XXX', '');
    cleanAddress = cleanAddress.replaceAll('XX', '');
    cleanAddress = cleanAddress.replaceAll('X', '');
    
    // Extraire seulement la ville et le code postal
    if (cleanAddress.contains(',')) {
      List<String> parts = cleanAddress.split(',');
      if (parts.length >= 2) {
        String cityPart = parts[0].trim();
        String postalPart = parts[1].trim();
        
        // Chercher le code postal
        RegExp postalRegex = RegExp(r'\d{5}');
        Match? postalMatch = postalRegex.firstMatch(postalPart);
        
        if (postalMatch != null) {
          return '$cityPart, ${postalMatch.group(0)}';
        } else {
          return cityPart;
        }
      }
    }
    
    return cleanAddress;
  }
  
  static pw.Widget _buildReservationDetails(Map<String, dynamic> data) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 30,
                height: 30,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'D',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'DÉTAILS DE LA RÉSERVATION',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          _buildInfoRow('ID Réservation', 'RES-${data['id'] ?? 'N/A'}'),
          _buildInfoRow('Date de réservation', _formatDate(data['dateReservation'])),
          _buildInfoRow('Statut', _getStatusText(data['statut'])),
          _buildInfoRow('Type de marchandise', data['typeMarchandise'] ?? 'N/A'),
          _buildInfoRow('Poids', '${data['poids'] ?? 'N/A'} kg'),
          _buildInfoRow('Volume', '${data['volume'] ?? 'N/A'} m³'),
          _buildInfoRow('Tarif', '${data['tarif'] ?? 'N/A'} MAD'),
          _buildInfoRow('Mode de paiement', data['modePaiement'] ?? 'N/A'),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTransporteurDetails(Map<String, dynamic> data) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 30,
                height: 30,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'T',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'INFORMATIONS TRANSPORTEUR',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          _buildInfoRow('Nom', data['transporteurNom'] ?? 'N/A'),
          _buildInfoRow('Entreprise', data['transporteurCompany'] ?? 'N/A'),
          _buildInfoRow('Téléphone', data['transporteurPhone'] ?? 'N/A'),
          _buildInfoRow('Email', data['transporteurEmail'] ?? 'N/A'),
        ],
      ),
    );
  }
  
  static pw.Widget _buildCamionDetails(Map<String, dynamic> data) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 30,
                height: 30,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'C',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'INFORMATIONS CAMION',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          _buildInfoRow('Marque', data['marque'] ?? 'N/A'),
          _buildInfoRow('Modèle', data['modele'] ?? 'N/A'),
          _buildInfoRow('Immatriculation', data['immatriculation'] ?? 'N/A'),
          _buildInfoRow('Capacité', '${data['capacite'] ?? 'N/A'} tonnes'),
          _buildInfoRow('Type', data['type'] ?? 'N/A'),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFooter(Map<String, dynamic> data) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'TransportPro - Plateforme de Transport Logistique',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Document généré le ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 2,
            color: PdfColors.blue900,
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is String) {
      try {
        date = DateTime.parse(date);
      } catch (e) {
        return date;
      }
    }
    if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return 'N/A';
  }
  
  static String _getStatusText(String? status) {
    switch (status) {
      case 'TERMINEE':
        return 'Terminé';
      case 'EN_COURS':
        return 'En cours';
      case 'EN_ATTENTE':
        return 'En attente';
      default:
        return status ?? 'N/A';
    }
  }
} 