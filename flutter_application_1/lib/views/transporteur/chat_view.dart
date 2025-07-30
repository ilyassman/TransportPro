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
        
        // Pour un transporteur, le destinataire est toujours le chargeur
        // L'ID du chargeur est stocké dans transporteurId (nommage confus mais c'est l'ID du chargeur)
        destinataireId = widget.reservation.transporteurId; // C'est en fait l'ID du chargeur
        destinataireNom = widget.reservation.transporteurNom; // C'est en fait le nom du chargeur
      });
      
      // Logs pour déboguer
      print('=== DEBUG CHAT ===');
      print('Current User ID: $currentUserId');
      print('Current Username: $currentUsername');
      print('Destinataire ID: $destinataireId');
      print('Destinataire Nom: $destinataireNom');
      print('Reservation ID: ${widget.reservation.id}');
      print('==================');
      
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
      print('Erreur lors du chargement des messages: $e');
    }
  }

  void _connectWebSocket() {
    try {
      final wsUrl = 'ws://192.168.1.104:8082/ws/chat/${widget.reservation.id}';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (message) {
          print('Message WebSocket reçu: $message');
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'NEW_MESSAGE') {
              final newMessage = MessageModel.fromJson(data['message']);
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
        onError: (error) {
          print('Erreur WebSocket: $error');
          setState(() {
            isConnected = false;
          });
        },
        onDone: () {
          print('WebSocket fermé');
          setState(() {
            isConnected = false;
          });
        },
      );
      
      setState(() {
        isConnected = true;
      });
    } catch (e) {
      print('Erreur lors de la connexion WebSocket: $e');
      setState(() {
        isConnected = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final messageText = _messageController.text.trim();
    _messageController.clear();
    
    try {
      final message = await _messageService.envoyerMessage(
        messageText,
        destinataireId ?? 0,
        widget.reservation.id,
      );
      
      setState(() {
        messages.add(message);
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
      print('Erreur lors de l\'envoi du message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi du message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callUser() async {
    if (destinataireNom == null) return;
    
    try {
      // Demander la permission d'appeler
      final status = await Permission.phone.request();
      if (status.isGranted) {
        // Ici vous devriez récupérer le numéro de téléphone du destinataire
        // Pour l'instant, on utilise un numéro fictif
        final phoneNumber = 'tel:+212600000000';
        if (await canLaunchUrl(Uri.parse(phoneNumber))) {
          await launchUrl(Uri.parse(phoneNumber));
        }
      }
    } catch (e) {
      print('Erreur lors de l\'appel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destinataireNom ?? 'Chat',
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected ? 'Connecté' : 'Déconnecté',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF1E3A8A)),
            onPressed: _callUser,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Dégradé de fond
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE3E9F9), Color(0xFFD1D8F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              // Zone des messages
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                          ),
                        )
                      : messages.isEmpty
                          ? _buildEmptyState()
                          : _buildMessagesList(),
                ),
              ),
              
              // Zone de saisie
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Tapez votre message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: const Color(0xFF1E3A8A).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              color: const Color(0xFF1E293B).withOpacity(0.7),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez la conversation',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF64748B).withOpacity(0.7),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMyMessage = message.expediteurId == currentUserId;
        
        return _buildMessageBubble(message, isMyMessage);
      },
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMyMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1E3A8A),
              child: Text(
                (destinataireNom ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMyMessage 
                    ? const Color(0xFF1E3A8A)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.contenu,
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.dateEnvoi),
                    style: TextStyle(
                      color: isMyMessage ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                (currentUsername ?? 'M')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inHours > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
} 