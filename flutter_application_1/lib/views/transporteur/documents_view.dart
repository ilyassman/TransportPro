import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import '../../services/reservation_service.dart';
import '../../services/pdf_service.dart';

class TransporteurDocument {
  final String id;
  final String reservationId;
      final String clientName;
  final String trajetInfo;
  final DateTime dateReservation;
  final String status;
  final String size;
  final String format;
  final Map<String, dynamic> fullData;

  TransporteurDocument({
    required this.id,
    required this.reservationId,
    required this.clientName,
    required this.trajetInfo,
    required this.dateReservation,
    required this.status,
    required this.size,
    required this.format,
    required this.fullData,
  });

  factory TransporteurDocument.fromJson(Map<String, dynamic> json) {
    // Construire les informations du client
    String clientName = json['chargeurNom'] ?? 'Client non assigné';
    if (json['chargeurCompany'] != null && json['chargeurCompany'].toString().isNotEmpty) {
      clientName = json['chargeurCompany'].toString();
    }

    return TransporteurDocument(
      id: _parseId(json['id']),
      reservationId: 'RES-${_parseId(json['id'])}',
      clientName: clientName,
      trajetInfo: json['trajetInfo'] ?? 'Trajet non défini',
      dateReservation: _parseDateTime(json['dateReservation']),
      status: json['statut'] ?? json['status'] ?? 'EN_ATTENTE',
      size: json['size'] ?? '2.3 MB',
      format: json['format'] ?? 'PDF',
      fullData: json,
    );
  }

  // Méthode helper pour parser les IDs
  static String _parseId(dynamic id) {
    if (id == null) return '';
    if (id is String) return id;
    if (id is int) return id.toString();
    if (id is num) return id.toInt().toString();
    return '';
  }

  // Méthode helper pour parser les dates
  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        print('Erreur parsing date: $e');
        return DateTime.now();
      }
    }
    if (date is DateTime) return date;
    return DateTime.now();
  }
}

class DocumentsView extends StatefulWidget {
  const DocumentsView({Key? key}) : super(key: key);

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ReservationService _reservationService = ReservationService();
  
  List<TransporteurDocument> _allDocuments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Récupérer les récapitulatifs de réservations (même endpoint que le chargeur)
      final data = await _reservationService.getReservationRecapitulatif();
      final documents = data.map((json) => TransporteurDocument.fromJson(json)).toList();

      setState(() {
        _allDocuments = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<TransporteurDocument> get _filteredDocuments {
    return _allDocuments.where((doc) {
      return doc.reservationId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             doc.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             doc.trajetInfo.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'TERMINEE':
        return Colors.green;
      case 'EN_COURS':
        return Colors.blue;
      case 'EN_TRANSIT':
        return Colors.orange;
      case 'EN_ATTENTE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'TERMINEE':
        return 'Terminé';
      case 'EN_COURS':
        return 'En cours';
      case 'EN_TRANSIT':
        return 'En transit';
      case 'EN_ATTENTE':
        return 'En attente';
      default:
        return status;
    }
  }

  void _downloadDocument(TransporteurDocument document) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
          ),
        ),
      );

      // Générer le PDF
      await PdfService.generateReservationRecap(document.fullData);
      
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      
      // Afficher le message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF généré avec succès: Récapitulatif ${document.reservationId}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      
      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération du PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _viewDocumentDetails(TransporteurDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Récapitulatif ${document.reservationId}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                              Text('Client: ${document.clientName}'),
              const SizedBox(height: 8),
              Text('Trajet: ${document.trajetInfo}'),
              const SizedBox(height: 8),
              Text('Date: ${document.dateReservation.day}/${document.dateReservation.month}/${document.dateReservation.year}'),
              const SizedBox(height: 8),
              Text('Statut: ${_getStatusText(document.status)}'),
              const SizedBox(height: 8),
              Text('Taille: ${document.size}'),
              const SizedBox(height: 16),
              Text(
                'Le PDF contiendra toutes les informations détaillées de la réservation, du chargeur et du trajet.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadDocument(document);
            },
            child: Text('Générer PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildInfoCard(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Icon(
            Icons.arrow_back,
            color: const Color(0xFF1E3A8A),
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(
            'Documents',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher par réservation, chargeur ou trajet...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description,
            color: const Color(0xFF1E3A8A),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Documents de Transport',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Générez des PDF détaillés avec carte du trajet et toutes les informations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des documents...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocuments,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filteredDocuments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _allDocuments.isEmpty ? 'Aucun document disponible' : 'Aucun document trouvé',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_allDocuments.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Vos documents apparaîtront ici après vos premières missions',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _filteredDocuments.length,
      itemBuilder: (context, index) {
        final document = _filteredDocuments[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + index * 50),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
          child: GestureDetector(
            onTap: () => _viewDocumentDetails(document),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icône du document
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description,
                        color: const Color(0xFF1E3A8A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Contenu principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre du document
                          Text(
                            'Récapitulatif ${document.reservationId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Chargeur
                          Text(
                            document.clientName,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Trajet
                          Text(
                            document.trajetInfo,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Statut et informations
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(document.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusText(document.status),
                                  style: TextStyle(
                                    color: _getStatusColor(document.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${document.size} • ${document.format}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton de téléchargement
                    IconButton(
                      onPressed: () => _downloadDocument(document),
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Color(0xFF1E3A8A),
                        size: 24,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 