// KIWI Wi-Fi Scanner Screen
// Scans for nearby Open/Unencrypted Access Points and provides manual/demo gateways

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../constants/security_constants.dart';
import '../models/verification_models.dart';
import '../services/network_service.dart';
import '../theme/kiwi_theme.dart';
import 'status_screen.dart';
import 'threat_log_screen.dart';

class ScannerScreen extends StatefulWidget {
  final NetworkService networkService;
  final bool autoScan;

  const ScannerScreen({
    super.key,
    required this.networkService,
    this.autoScan = true,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanning = false;
  List<ApScanItem> _accessPoints = [];
  bool _hardwareScanAvailable = true;
  String _customHost = kDefaultGatewayHost;
  final TextEditingController _customHostController =
      TextEditingController(text: kDefaultGatewayHost);

  // Fallback demo APs for non-hardware or emulator testing
  final List<ApScanItem> _fallbackAps = [
    ApScanItem(
      ssid: kTargetSoftApSsid,
      bssid: "CC:50:E3:8A:2B:10",
      rssi: -45,
      isOpen: true,
      isTargetKiwiZone: true,
    ),
    ApScanItem(
      ssid: "Airport-Free-Public-WiFi",
      bssid: "02:1A:11:F4:99:A2",
      rssi: -62,
      isOpen: true,
      isTargetKiwiZone: false,
    ),
    ApScanItem(
      ssid: "CoffeeShop_Guest_Open",
      bssid: "74:DA:38:21:55:01",
      rssi: -71,
      isOpen: true,
      isTargetKiwiZone: false,
    ),
    ApScanItem(
      ssid: "Metropolitan_Transit_WiFi",
      bssid: "E4:8D:8C:11:00:FE",
      rssi: -84,
      isOpen: true,
      isTargetKiwiZone: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoScan) {
      _startScan();
    } else {
      _accessPoints = _fallbackAps;
      _hardwareScanAvailable = false;
    }
  }

  @override
  void dispose() {
    _customHostController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);

    try {
      final canScan = await WiFiScan.instance
          .canStartScan()
          .timeout(const Duration(milliseconds: 500));
      if (canScan == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
        final results = await WiFiScan.instance.getScannedResults();
        
        // Filter for open (unencrypted) APs
        final openAps = results
            .where((ap) => ap.capabilities.contains("[ESS]") && !ap.capabilities.contains("WPA") && !ap.capabilities.contains("WEP"))
            .map((ap) => ApScanItem(
                  ssid: ap.ssid.isEmpty ? "<Hidden SSID>" : ap.ssid,
                  bssid: ap.bssid,
                  rssi: ap.level,
                  isOpen: true,
                  isTargetKiwiZone: ap.ssid == kTargetSoftApSsid,
                ))
            .toList();

        setState(() {
          _hardwareScanAvailable = true;
          _accessPoints = openAps.isNotEmpty ? openAps : _fallbackAps;
          _isScanning = false;
        });
      } else {
        // Fallback for emulators/desktop without Wi-Fi scanning hardware permission
        setState(() {
          _hardwareScanAvailable = false;
          _accessPoints = _fallbackAps;
          _isScanning = false;
        });
      }
    } catch (_) {
      setState(() {
        _hardwareScanAvailable = false;
        _accessPoints = _fallbackAps;
        _isScanning = false;
      });
    }
  }

  void _navigateToVerification({
    required String ssid,
    required String bssid,
    DemoScenario demoScenario = DemoScenario.none,
    String? customHost,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatusScreen(
          networkService: widget.networkService,
          ssid: ssid,
          bssid: bssid,
          demoScenario: demoScenario,
          gatewayHost: customHost ?? _customHost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: KiwiTheme.tealAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: KiwiTheme.tealAccent, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("KIWI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text("Wi-Fi Safety Companion", style: TextStyle(fontSize: 11, color: KiwiTheme.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Threat Audit Log",
            icon: const Icon(Icons.security, color: KiwiTheme.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ThreatLogScreen()),
              );
            },
          ),
          IconButton(
            tooltip: "Rescan APs",
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: KiwiTheme.tealAccent),
                  )
                : const Icon(Icons.refresh, color: KiwiTheme.textPrimary),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Trust Banner
          _buildTrustBanner(),
          const SizedBox(height: 16),

          // Direct Hardware Gateway Connection Card
          _buildDirectConnectCard(),
          const SizedBox(height: 16),

          // Simulation / Evaluation Matrix Card
          _buildDemoMatrixCard(),
          const SizedBox(height: 20),

          // Nearby Open Networks Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Nearby Open Networks (${_accessPoints.length})",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: KiwiTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (!_hardwareScanAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Demo Fallback",
                    style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // AP List
          ..._accessPoints.map(_buildApItem),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KiwiTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KiwiTheme.surfaceElevated),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: KiwiTheme.tealAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Zero-Trust Access Point Verification",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KiwiTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  "Every gateway must cryptographically prove it holds an authentic KIWI Root CA certificate before your device exposes network traffic.",
                  style: TextStyle(fontSize: 12, color: KiwiTheme.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectConnectCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KiwiTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KiwiTheme.tealAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.router, color: KiwiTheme.tealAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Physical ESP32 Gateway Verification",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KiwiTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Connect to SoftAP 'KIWI-Secure-Zone' then verify endpoint at 192.168.4.1:",
            style: TextStyle(fontSize: 12, color: KiwiTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customHostController,
                  style: const TextStyle(fontSize: 13, color: KiwiTheme.textPrimary),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    hintText: "192.168.4.1",
                    filled: true,
                    fillColor: KiwiTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: KiwiTheme.surfaceElevated),
                    ),
                  ),
                  onChanged: (val) => _customHost = val.trim(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.security, size: 16),
                label: const Text("Verify"),
                onPressed: () {
                  _navigateToVerification(
                    ssid: kTargetSoftApSsid,
                    bssid: "ESP32:GW:01",
                    customHost: _customHost.isNotEmpty ? _customHost : kDefaultGatewayHost,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoMatrixCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KiwiTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KiwiTheme.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.purpleAccent, size: 18),
              SizedBox(width: 8),
              Text(
                "Threat Simulation & Evaluation Mode",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KiwiTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Evaluate full 4-layer defense without physical ESP32 attached:",
            style: TextStyle(fontSize: 11, color: KiwiTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDemoButton(
                label: "Pass (Legitimate)",
                color: KiwiTheme.verifiedBorder,
                scenario: DemoScenario.legitimateGateway,
              ),
              _buildDemoButton(
                label: "Fail L1 (Forged Root)",
                color: KiwiTheme.hostileBorder,
                scenario: DemoScenario.evilTwinForgedRootSignature,
              ),
              _buildDemoButton(
                label: "Fail L2 (Bad Sig)",
                color: KiwiTheme.hostileBorder,
                scenario: DemoScenario.evilTwinInvalidGatewaySig,
              ),
              _buildDemoButton(
                label: "Fail L3 (Replay)",
                color: Colors.amber,
                scenario: DemoScenario.evilTwinReplayAttack,
              ),
              _buildDemoButton(
                label: "Fail L4 (Revoked)",
                color: Colors.orangeAccent,
                scenario: DemoScenario.evilTwinRevokedDevice,
              ),
              _buildDemoButton(
                label: "Fail (>2000ms Timeout)",
                color: Colors.redAccent,
                scenario: DemoScenario.timeoutFailure,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton({
    required String label,
    required Color color,
    required DemoScenario scenario,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        _navigateToVerification(
          ssid: "SIMULATED: ${scenario.name}",
          bssid: "SIM:00:11:22:33:44",
          demoScenario: scenario,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildApItem(ApScanItem ap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ap.isTargetKiwiZone
                ? KiwiTheme.tealAccent.withValues(alpha: 0.15)
                : KiwiTheme.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.wifi,
            color: ap.isTargetKiwiZone ? KiwiTheme.tealAccent : KiwiTheme.textMuted,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                ap.ssid,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Text(
                "Unverified",
                style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                ap.bssid,
                style: const TextStyle(fontSize: 11, color: KiwiTheme.textMuted, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 10),
              Text(
                "${ap.rssi} dBm",
                style: const TextStyle(fontSize: 11, color: KiwiTheme.textMuted),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: KiwiTheme.textMuted),
        onTap: () {
          _navigateToVerification(
            ssid: ap.ssid,
            bssid: ap.bssid,
            customHost: _customHost,
          );
        },
      ),
    );
  }
}
