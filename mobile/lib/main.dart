import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'constants/security_constants.dart';
import 'models/verification_models.dart';
import 'services/crypto_service.dart';
import 'services/network_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cryptoService = CryptoService();
  final storageService = StorageService(cryptoService);
  await storageService.init();
  final networkService = NetworkService(cryptoService, storageService);

  runApp(MyApp(networkService: networkService));
}

class MyApp extends StatelessWidget {
  final NetworkService networkService;

  const MyApp({super.key, required this.networkService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KIWI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, primarySwatch: Colors.blue),
      home: VerifierPage(networkService: networkService),
    );
  }
}

class VerifierPage extends StatefulWidget {
  final NetworkService networkService;

  const VerifierPage({super.key, required this.networkService});

  @override
  State<VerifierPage> createState() => _VerifierPageState();
}

class _VerifierPageState extends State<VerifierPage> {
  String wifiName = "Unknown";
  String status = "Press button to verify";
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await Permission.location.request();
    await Permission.nearbyWifiDevices.request();
    await _getWifiName();
  }

  Future<void> _getWifiName() async {
    final ssid = await widget.networkService.getConnectedWifiSsid();
    if (mounted) {
      setState(() {
        wifiName = ssid ?? "Disconnected / Unknown";
      });
    }
  }

  Future<void> _verifyGateway() async {
    setState(() {
      _isVerifying = true;
      status = "Challenging Gateway...";
    });

    final bssid = await widget.networkService.getConnectedWifiBssid() ?? "00:00:00:00:00:00";
    final res = await widget.networkService.performMutualHandshake(
      host: kDefaultGatewayHost,
      ssid: wifiName,
      bssid: bssid,
    );

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      final buffer = StringBuffer();
      if (res.isVerified) {
        buffer.writeln("✅ Verified — $wifiName is a trusted KIWI gateway\n");
      } else {
        final layerName = res.failedLayer?.displayName ?? 'Verification Failed';
        final reason = res.failureReason ?? 'Gateway Unreachable';
        buffer.writeln("❌ Not Verified: $layerName");
        buffer.writeln("$reason\n");
      }

      if (res.passedLayers.isNotEmpty || res.failedLayers.isNotEmpty) {
        buffer.writeln("--- Verification Layer Audit ---");
        for (final p in res.passedLayers) {
          buffer.writeln(p);
        }
        for (final f in res.failedLayers) {
          buffer.writeln(f);
        }
      }
      status = buffer.toString().trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KIWI")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Connected WiFi: $wifiName",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _getWifiName,
                child: const Text("Refresh WiFi Name"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isVerifying ? null : _verifyGateway,
                child: Text(_isVerifying ? "Verifying..." : "Verify Gateway"),
              ),
              const SizedBox(height: 30),
              Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: status.startsWith("✅")
                      ? Colors.green
                      : (status.startsWith("❌") ? Colors.red : null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
