class ApiConfig {
  final String server;
  final String password;
  
  ApiConfig({
    required this.server,
    required this.password,
  });
}

class ConfigParser {
  /// Извлекает API-конфигурацию из файла
  static ApiConfig parseApiConfig(String content) {
    final lines = content.split('\n');
    String? server;
    String? password;
    
    bool inApiSection = false;
    
    for (var line in lines) {
      line = line.trim();
      
      if (line == '[API]') {
        inApiSection = true;
        continue;
      }
      
      if (line.startsWith('[') && line != '[API]') {
        inApiSection = false;
      }
      
      if (inApiSection && line.contains('=')) {
        final parts = line.split('=');
        final key = parts[0].trim().toLowerCase();
        final value = parts[1].trim();
        
        if (key == 'server') server = value;
        if (key == 'password') password = value;
      }
    }
    
    if (server == null || password == null) {
      throw Exception('В файле конфигурации отсутствует секция [API]');
    }
    
    return ApiConfig(
      server: server,
      password: password,
    );
  }
  
  /// Извлекает WireGuard-конфигурацию (всё кроме секции [API])
  static String extractWireGuardConfig(String content) {
    final lines = content.split('\n');
    final buffer = StringBuffer();
    bool inApiSection = false;
    
    for (var line in lines) {
      if (line.trim() == '[API]') {
        inApiSection = true;
        continue;
      }
      
      if (line.trim().startsWith('[') && line.trim() != '[API]') {
        inApiSection = false;
      }
      
      if (!inApiSection) {
        buffer.writeln(line);
      }
    }
    
    return buffer.toString().trim();
  }
}