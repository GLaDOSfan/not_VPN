import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceManager {
  static const String _uuidKey = 'device_uuid';
  
  final Uuid _uuid = const Uuid();
  
  /// Получить или создать уникальный ID устройства
  Future<String> getDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? uuid = prefs.getString(_uuidKey);
    
    if (uuid == null) {
      // Генерируем новый UUID при первом запуске
      uuid = _uuid.v4();
      await prefs.setString(_uuidKey, uuid);
      print('Создан новый UUID: $uuid');
    } else {
      print('Найден существующий UUID: $uuid');
    }
    
    return uuid;
  }
  
  /// Сбросить ID (например, при выходе из аккаунта)
  Future<void> resetDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uuidKey);
    print('UUID сброшен');
  }
}