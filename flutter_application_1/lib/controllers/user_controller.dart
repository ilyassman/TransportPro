
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserController extends GetxController {
  final UserService userService;
  late WebSocketChannel channel;
  var isLoading = true.obs;
  var userList = <UserModel>[].obs;
  var isConnected = false.obs;
      final String socketUrl = 'ws://192.168.1.69:8082/ws/users'; 

  UserController({required this.userService});

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    connectWebSocket();
  }

  void loadUsers() async {
    
    try {
      isLoading(true);
      userList.value = await userService.fetchUsers();
    } catch (e) {
      print("Erreur chargement utilisateurs : $e");
    } finally {
      isLoading(false);
    }
  }

  void addUser(UserModel user) async {
    try {
      isLoading(true);
      await userService.addUser(user);
    } catch (e) {
      print("Erreur ajout utilisateur : $e");
    } finally {
      isLoading(false);
    }
  }
  void deleteUser(int id) async {
    try {
      isLoading(true);
      await userService.deleteUser(id);
      loadUsers(); // Recharger la liste après suppression
    } catch (e) {
      print("Erreur suppression utilisateur : $e");
    } finally {
      isLoading(false);
    }
  }
  void connectWebSocket() {
  channel = WebSocketChannel.connect(Uri.parse(socketUrl));

  channel.stream.listen((message) {
    isConnected(true);
    if (message == "update") {
      print("recueilli update");
      loadUsers();
    }
  }, onDone: () {
    isConnected(false);
    print("WebSocket fermé");
  }, onError: (error) {
    isConnected(false);
    print("Erreur WebSocket : $error");
  });
}
   
  @override
  void onClose() {
    channel.sink.close();
    super.onClose();
  }
}
