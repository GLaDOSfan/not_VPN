import 'dart:convert';
import 'package:http/http.dart' as http;

class WireGuardApiService {
  final String baseUrl;
  final String username;
  final String password;
  
  WireGuardApiService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  Map<String, String> _getHeaders() {
    final basicAuth = base64Encode(utf8.encode('$username:$password'));
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Basic $basicAuth',
    };
  }

  /// Получить список всех клиентов
  Future<List<Map<String, dynamic>>> getClients() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/wireguard/client'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Ошибка получения списка клиентов: ${response.statusCode}');
    }
  }

  /// Найти клиента по clientId
  Future<Map<String, dynamic>?> findClientByUuid(String uuid) async {
  final clients = await getClients();
  try {
    // Ищем по полю name (оно равно UUID)
    return clients.firstWhere((client) => client['name'] == uuid);
  } catch (e) {
    return null;
  }
}

  /// Создать клиента
Future<Map<String, dynamic>> createClient(String clientId, String deviceName) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/wireguard/client'),
    headers: _getHeaders(),
    body: json.encode({
      'name': deviceName,  // теперь сюда передаём чистый UUID
      'clientId': clientId,
    }),
  );
  
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Ошибка создания клиента: ${response.statusCode}');
  }
  
  // Получаем список клиентов и находим по name (который равен clientId)
  final clients = await getClients();
  final newClient = clients.firstWhere(
    (client) => client['name'] == clientId,  // ищем по name
    orElse: () => throw Exception('Клиент создан, но не найден в списке'),
  );
  
  return newClient;
}


  /// Получить конфигурацию по внутреннему ID клиента
  Future<String> getClientConfig(String clientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/wireguard/client/$clientId/configuration'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Ошибка получения конфигурации: ${response.statusCode}');
    }
  }

  /// Удалить клиента
  Future<void> deleteClient(String clientId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/wireguard/client/$clientId'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Ошибка удаления клиента: ${response.statusCode}');
    }
  }
}