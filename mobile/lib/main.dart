// KIWI: Your Wi-Fi Safety Companion
// Main Application Bootstrap & Service Dependency Injection

import 'package:flutter/material.dart';

import 'screens/scanner_screen.dart';
import 'services/crypto_service.dart';
import 'services/network_service.dart';
import 'services/storage_service.dart';
import 'theme/kiwi_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Cryptographic Engine
  final cryptoService = CryptoService();

  // 2. Initialize Hardware Key Storage & Threat Vault
  final storageService = StorageService(cryptoService);
  await storageService.init();

  // 3. Initialize Network Handshake Orchestrator
  final networkService = NetworkService(cryptoService, storageService);

  runApp(KiwiApp(networkService: networkService));
}

class KiwiApp extends StatelessWidget {
  final NetworkService networkService;
  final bool autoScan;

  const KiwiApp({
    super.key,
    required this.networkService,
    this.autoScan = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KIWI Wi-Fi Safety Companion',
      debugShowCheckedModeBanner: false,
      theme: KiwiTheme.darkTheme,
      home: ScannerScreen(
        networkService: networkService,
        autoScan: autoScan,
      ),
    );
  }
}
