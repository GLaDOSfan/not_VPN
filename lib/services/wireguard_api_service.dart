import 'dart:convert';
import 'package:http/http.dart' as http;

class WireGuardApiService {
  final String baseUrl;
  final String password;
  
  // Храним cookies после авторизации
  String? _sessionCookie;
  
  WireGuardApiService({
    required this.baseUrl,
    required this.password,
  });

  /// Авторизация и получение сессионной cookie
  Future<void> _authenticate() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/session'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'password': password}),
    );
    
    if (response.statusCode == 200) {
      // Получаем cookie из заголовка Set-Cookie
      final cookieHeader = response.headers['set-cookie'];
      if (cookieHeader != null) {
        // Извлекаем значение cookie (обычно формат: connect.sid=xxx; Path=/; HttpOnly)
        _sessionCookie = cookieHeader.split(';')[0];
        print('Авторизация успешна, cookie: $_sessionCookie');
      } else {
        throw Exception('Cookie не получена');
      }
    } else {
      throw Exception('Ошибка авторизации: ${response.statusCode}');
    }
  }

  /// Получить заголовки с авторизацией
  Map<String, String> _getHeaders() {
    if (_sessionCookie == null) {
      throw Exception('Необходимо авторизоваться. Вызовите authenticate() сначала');
    }
    return {
      'Content-Type': 'application/json',
      'Cookie': _sessionCookie!,
    };
  }

  /// Убедиться, что сессия активна
  Future<void> _ensureAuthenticated() async {
    if (_sessionCookie == null) {
      await _authenticate();
    }
  }

  /// Получить список всех клиентов
  Future<List<Map<String, dynamic>>> getClients() async {
    await _ensureAuthenticated();
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/wireguard/client'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      // Сессия истекла, пробуем переавторизоваться
      _sessionCookie = null;
      await _authenticate();
      return getClients(); // Повторяем запрос
    } else {
      throw Exception('Ошибка получения списка клиентов: ${response.statusCode}');
    }
  }

  /// Найти клиента по имени (UUID)
  Future<Map<String, dynamic>?> findClientByUuid(String uuid) async {
    final clients = await getClients();
    try {
      return clients.firstWhere((client) => client['name'] == uuid);
    } catch (e) {
      return null;
    }
  }

  /// Создать клиента
  /// Создать клиента
  Future<Map<String, dynamic>> createClient(String clientId, String deviceName) async {
    await _ensureAuthenticated();
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/wireguard/client'),
      headers: _getHeaders(),
      body: json.encode({
        'name': deviceName,
      }),
    );
    
    print('Create client response status: ${response.statusCode}');
    print('Create client response body: ${response.body}');
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка создания клиента: ${response.statusCode}');
    }
    
    // Парсим ответ
    Map<String, dynamic>? responseData;
    if (response.body.isNotEmpty) {
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('Ошибка парсинга ответа: $e');
      }
    }
    
    // Если в ответе есть id и он не null - возвращаем его
    if (responseData != null && 
        responseData['id'] != null && 
        responseData['id'].toString() != 'null') {
      print('Клиент создан, id из ответа: ${responseData['id']}');
      return responseData;
    }
    
    // Иначе ждём и получаем из списка
    print('Ждём появления клиента в списке...');
    await Future.delayed(Duration(milliseconds: 500));
    
    final clients = await getClients();
    final newClient = clients.firstWhere(
      (client) => client['name'] == deviceName,
      orElse: () => {
        'id': 'error',
        'name': deviceName,
        'error': 'Клиент не найден после создания'
      },
    );
    
    print('Клиент найден в списке: id=${newClient['id']}');
    return newClient;
  }

  /// Получить конфигурацию по ID клиента
  Future<String> getClientConfig(String clientId) async {
    await _ensureAuthenticated();
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/wireguard/client/$clientId/configuration'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 401) {
      _sessionCookie = null;
      await _authenticate();
      return getClientConfig(clientId);
    } else {
      throw Exception('Ошибка получения конфигурации: ${response.statusCode}');
    }
  }

  /// Удалить клиента
  Future<void> deleteClient(String clientId) async {
    await _ensureAuthenticated();
    
    final response = await http.delete(
      Uri.parse('$baseUrl/api/wireguard/client/$clientId'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Ошибка удаления клиента: ${response.statusCode}');
    }
  }

  /// Сбросить сессию (при выходе из приложения)
  void logout() {
    _sessionCookie = null;
  }
}