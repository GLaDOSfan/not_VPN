import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WireGuard VPN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const VpnControlPage(),
    );
  }
}

class VpnControlPage extends StatefulWidget {
  const VpnControlPage({super.key});

  @override
  State<VpnControlPage> createState() => _VpnControlPageState();
}

class _VpnControlPageState extends State<VpnControlPage> with SingleTickerProviderStateMixin {
  bool _isConnected = false;
  bool _isLoading = false;
  String _statusMessage = 'Готов к подключению';
  int _rxBytes = 0;
  int _txBytes = 0;
  
  final _vpn = WireGuardFlutter.instance;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _initializeVpn();
    _startTrafficUpdates();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeVpn() async {
    try {
      setState(() {
        _statusMessage = 'Инициализация...';
      });
      
      await _vpn.initialize(
        interfaceName: 'wg0',
        vpnName: 'notVPN',
      );
      
      setState(() {
        _statusMessage = 'Готов к подключению';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка инициализации: $e';
      });
    }
  }
  
  void _startTrafficUpdates() {
    Future.delayed(const Duration(seconds: 2), _updateTraffic);
  }
  
  Future<void> _updateTraffic() async {
    if (!mounted) return;
    
    try {
      final traffic = await _vpn.trafficStats();
      setState(() {
        _rxBytes = traffic['totalDownload'] ?? 0;
        _txBytes = traffic['totalUpload'] ?? 0;
      });
    } catch (e) {
      // Игнорируем ошибки, если VPN не активен
    }
    
    if (mounted) {
      Future.delayed(const Duration(seconds: 2), _updateTraffic);
    }
  }

  Future<void> _connectVpn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Подключение...';
    });
    
    _pulseController.forward();

    try {
      final configString = await rootBundle.loadString('assets/wireguard_config.conf');
      final (serverAddress, wgQuickConfig) = _parseConfig(configString);
      
      await _vpn.startVpn(
        serverAddress: serverAddress,
        wgQuickConfig: wgQuickConfig,
        providerBundleIdentifier: 'com.example.notvpn',
      );
      
      setState(() {
        _isConnected = true;
        _statusMessage = 'notVPN подключен';
        _isLoading = false;
      });
      
      _pulseController.stop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('notVPN подключен')),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка подключения: $e';
        _isLoading = false;
      });
      
      _pulseController.stop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _disconnectVpn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Отключение...';
    });

    try {
      await _vpn.stopVpn();
      
      setState(() {
        _isConnected = false;
        _statusMessage = 'notVPN отключен';
        _isLoading = false;
        _rxBytes = 0;
        _txBytes = 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('notVPN отключен'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка отключения: $e';
        _isLoading = false;
      });
    }
  }

  (String serverAddress, String wgQuickConfig) _parseConfig(String config) {
    final endpointMatch = RegExp(r'Endpoint\s*=\s*(\S+)').firstMatch(config);
    final endpoint = endpointMatch?.group(1) ?? '';
    return (endpoint, config);
  }

  Widget _buildTrafficItem(String label, int bytes) {
    String formattedBytes;
    if (bytes < 1024) {
      formattedBytes = '$bytes B';
    } else if (bytes < 1024 * 1024) {
      formattedBytes = '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      formattedBytes = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      formattedBytes = '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Text(formattedBytes, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('notVPN'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isLoading ? _pulseAnimation.value : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: _isLoading ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ] : [],
                      ),
                      child: Icon(
                        _isConnected ? Icons.vpn_key : Icons.vpn_lock,
                        size: 100,
                        color: _isConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Статистика трафика',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTrafficItem('📥 Получено', _rxBytes),
                        _buildTrafficItem('📤 Отправлено', _txBytes),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isConnected ? _disconnectVpn : _connectVpn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isConnected ? 'ОТКЛЮЧИТЬ' : 'ПОДКЛЮЧИТЬ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isConnected)
                const Text(
                  'Ваш трафик защищен',
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}