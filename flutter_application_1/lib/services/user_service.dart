import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'utils/dio_client.dart';

class UserService {
  final Dio _dio;

  UserService({String? token}) : _dio = DioClient.create(token: token);

  Future<List<UserModel>> fetchUsers() async {
    final response = await _dio.get('/users');
    final List data = response.data;
    return data.map((e) => UserModel.fromJson(e)).toList();
  }
  
  Future<void> addUser(UserModel user) async {
    try {
      await _dio.post('/user', data: {
        'username': user.username,
        'email': user.email,
        'password': user.password
      });
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de l'utilisateur : $e");
    }
  }
  
  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('/user/$id');
    } catch (e) {
      throw Exception("Erreur lors de la suppression de l'utilisateur : $e");
    }
  }
}
