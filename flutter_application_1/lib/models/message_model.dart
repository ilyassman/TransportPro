class MessageModel {
  final int? id;
  final String contenu;
  final DateTime dateEnvoi;
  final int expediteurId;
  final String expediteurNom;
  final int destinataireId;
  final int reservationId;
  final bool lu;

  MessageModel({
    this.id,
    required this.contenu,
    required this.dateEnvoi,
    required this.expediteurId,
    required this.expediteurNom,
    required this.destinataireId,
    required this.reservationId,
    required this.lu,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      contenu: json['contenu'] ?? '',
      dateEnvoi: DateTime.parse(json['dateEnvoi']),
      expediteurId: json['expediteur']?['id'] ?? 0,
      expediteurNom: json['expediteur']?['username'] ?? '',
      destinataireId: json['destinataire']?['id'] ?? 0,
      reservationId: json['reservation']?['id'] ?? 0,
      lu: json['lu'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenu': contenu,
      'dateEnvoi': dateEnvoi.toIso8601String(),
      'expediteurId': expediteurId,
      'expediteurNom': expediteurNom,
      'destinataireId': destinataireId,
      'reservationId': reservationId,
      'lu': lu,
    };
  }
} 