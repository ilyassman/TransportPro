import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../../models/message_model.dart';
import '../../models/reservation_display_model.dart';
import '../../services/message_service.dart';
import '../../services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatView extends StatefulWidget {
  final ReservationDisplay reservation;
  
  const ChatView({Key? key, required this.reservation}) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  
  List<MessageModel> messages = [];
  bool isLoading = true;
  bool isConnected = false;
  WebSocketChannel? _channel;
  int? currentUserId;
  String? currentUsername;
  int? destinataireId;
  String? destinataireNom;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser().then((_) {
      _loadMessages();
      _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profileService = ProfileService();
      final profile = await profileService.getProfile();
      
      setState(() {
        currentUserId = profile['id'];
        currentUsername = profile['username'];
        
        // Déterminer le destinataire (l'autre participant)
        if (widget.reservation.transporteurNom.isNotEmpty && widget.reservation.transporteurId > 0) {
          // Si on est le chargeur, le destinataire est le transporteur
          destinataireId = widget.reservation.transporteurId;
          destinataireNom = widget.reservation.transporteurNom;
        } else {
          // Si on est le transporteur, le destinataire est le chargeur
          // On utilise l'ID de la réservation comme ID du chargeur
          destinataireId = widget.reservation.id; // Ceci devra être corrigé
          destinataireNom = 'Client';
        }
      });
      
      // Logs pour déboguer
      print('=== DEBUG CHAT CHARGEUR ===');
      print('Current User ID: $currentUserId');
      print('Current Username: $currentUsername');
      print('Destinataire ID: $destinataireId');
      print('Destinataire Nom: $destinataireNom');
      print('Reservation ID: ${widget.reservation.id}');
      print('Transporteur ID: ${widget.reservation.transporteurId}');
      print('Transporteur Nom: ${widget.reservation.transporteurNom}');
      print('===========================');
      
    } catch (e) {
      print('Erreur lors du chargement du profil: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final messagesList = await _messageService.getMessagesForReservation(widget.reservation.id);
      
      setState(() {
        messages = messagesList;
        isLoading = false;
      });
      
      // Marquer les messages comme lus
      await _messageService.marquerMessagesCommeLus(widget.reservation.id);
      
      // Scroll vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _connectWebSocket() async {
    // Attendre que l'utilisateur soit chargé
    if (currentUserId == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (currentUserId == null) {
        print('Impossible de connecter au WebSocket: utilisateur non chargé');
        return;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    
    final wsUrl = 'ws://10.0.2.2:8082/ws/chat?userId=$currentUserId&token=$token';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    _channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          
          if (data['type'] == 'NEW_MESSAGE') {
            final newMessage = MessageModel(
              id: data['messageId'],
              contenu: data['contenu'],
              dateEnvoi: DateTime.parse(data['dateEnvoi']),
              expediteurId: data['expediteurId'],
              expediteurNom: data['expediteurNom'],
              destinataireId: currentUserId!,
              reservationId: widget.reservation.id,
              lu: false,
            );
            
            setState(() {
              messages.add(newMessage);
            });
            
            // Scroll vers le bas
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        } catch (e) {
          print('Erreur lors du traitement du message WebSocket: $e');
        }
      },
      onDone: () {
        setState(() {
          isConnected = false;
        });
      },
      onError: (error) {
        setState(() {
          isConnected = false;
        });
        print('Erreur WebSocket: $error');
      },
    );
    
    setState(() {
      isConnected = true;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (destinataireId == null || destinataireId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'identifier le destinataire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final contenu = _messageController.text.trim();
    _messageController.clear();
    
    try {
      final newMessage = await _messageService.envoyerMessage(
        contenu,
        destinataireId!,
        widget.reservation.id,
      );
      
      setState(() {
        messages.add(newMessage);
      });
      
      // Scroll vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi du message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour obtenir la première lettre du nom
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // Méthode pour obtenir la couleur de l'avatar
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF2196F3), // Bleu
      const Color(0xFF4CAF50), // Vert
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Violet
      const Color(0xFFF44336), // Rouge
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Marron
      const Color(0xFF607D8B), // Gris bleu
    ];
    
    int hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destinataireNom ?? 'Utilisateur',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Transport Express • ${isConnected ? 'En ligne' : 'Hors ligne'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Bouton d'appel
          if (widget.reservation.transporteurPhone.isNotEmpty)
            IconButton(
              onPressed: _callTransporteur,
              icon: const Icon(Icons.phone),
              tooltip: 'Appeler',
            ),
        ],
      ),
      body: Column(
        children: [
          // Zone des messages
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun message pour le moment',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Commencez la conversation !',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.expediteurId == currentUserId;
                          
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Champ de saisie
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Tapez votre message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton d'envoi
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final initials = _getInitials(message.expediteurNom);
    final avatarColor = _getAvatarColor(message.expediteurNom);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Avatar de l'autre personne
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Bulle de message
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1E3A8A) : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      message.expediteurNom,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.contenu,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.dateEnvoi),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            // Avatar de l'utilisateur actuel
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Méthode pour appeler le transporteur
  Future<void> _callTransporteur() async {
    if (widget.reservation.transporteurPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone du transporteur non disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final phoneNumber = widget.reservation.transporteurPhone;
    
    // Afficher un dialogue de confirmation
    bool? shouldCall = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Appeler le transporteur'),
          content: Text('Voulez-vous appeler ${widget.reservation.transporteurNom} au ${phoneNumber} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Appeler'),
            ),
          ],
        );
      },
    );

    if (shouldCall != true) return;
    
    try {
      // Demander les permissions téléphoniques
      PermissionStatus phoneStatus = await Permission.phone.request();
      if (phoneStatus.isDenied || phoneStatus.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission d\'appel téléphonique requise'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Nettoyer le numéro de téléphone
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Ajouter le préfixe si nécessaire
      if (!cleanNumber.startsWith('+')) {
        if (cleanNumber.startsWith('0')) {
          cleanNumber = '+212' + cleanNumber.substring(1);
        } else if (cleanNumber.startsWith('212')) {
          cleanNumber = '+' + cleanNumber;
        } else {
          cleanNumber = '+212' + cleanNumber;
        }
      }
      
      // Essayer plusieurs formats d'URL
      List<String> urlFormats = [
        'tel:$cleanNumber',
        'tel:${cleanNumber.replaceAll('+', '')}',
        'tel:${cleanNumber.replaceAll('+212', '0')}',
      ];
      
      bool launched = false;
      for (String urlFormat in urlFormats) {
        try {
          final url = Uri.parse(urlFormat);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            launched = true;
            break;
          }
        } catch (e) {
          print('Erreur avec le format $urlFormat: $e');
          continue;
        }
      }
      
      if (!launched) {
        // Dernière tentative avec un format simple
        try {
          final simpleUrl = Uri.parse('tel:${cleanNumber.replaceAll(RegExp(r'[^\d]'), '')}');
          if (await canLaunchUrl(simpleUrl)) {
            await launchUrl(simpleUrl, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Aucun format d\'URL valide trouvé');
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir l\'application téléphone pour: $cleanNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'appel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 