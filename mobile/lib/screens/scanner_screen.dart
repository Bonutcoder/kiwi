// KIWI Wi-Fi Scanner & Authenticator Screen
// Clean, focused interface for scanning Wi-Fi access points and verifying hardware gateway authenticity.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../constants/security_constants.dart';
import '../models/verification_models.dart';
import '../services/network_service.dart';
import '../theme/kiwi_theme.dart';
import 'status_screen.dart';

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
  String _gatewayHost = kDefaultGatewayHost;
  final TextEditingController _hostController = TextEditingController(text: kDefaultGatewayHost);

  // Default target AP entry if hardware scan returns empty
  final List<ApScanItem> _defaultTargetAps = [
    ApScanItem(
      ssid: kTargetSoftApSsid,
      bssid: "68:D1:11:8A:2B:10",
      rssi: -45,
      isOpen: true,
      isTargetKiwiZone: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);

    try {
      final canScan = await WiFiScan.instance
          .canStartScan()
          .timeout(const Duration(milliseconds: 1000));

      if (canScan == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
        final results = await WiFiScan.instance.getScannedResults();

        final openAps = results.map((ap) => ApScanItem(
          ssid: ap.ssid.isEmpty ? "<Hidden Network>" : ap.ssid,
          bssid: ap.bssid,
          rssi: ap.level,
          isOpen: !ap.capabilities.contains("WPA") && !ap.capabilities.contains("WEP"),
          isTargetKiwiZone: ap.ssid == kTargetSoftApSsid,
        )).toList();

        setState(() {
          _accessPoints = openAps.isNotEmpty ? openAps : _defaultTargetAps;
          _isScanning = false;
        });
      } else {
        setState(() {
          _accessPoints = _defaultTargetAps;
          _isScanning = false;
        });
      }
    } catch (_) {
      setState(() {
        _accessPoints = _defaultTargetAps;
        _isScanning = false;
      });
    }
  }

  void _verifyGateway({
    required String ssid,
    required String bssid,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatusScreen(
          networkService: widget.networkService,
          ssid: ssid,
          bssid: bssid,
          gatewayHost: _gatewayHost.isNotEmpty ? _gatewayHost : kDefaultGatewayHost,
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Scan Action Card
              _buildScanHeaderCard(),
              const SizedBox(height: 16),

              // Discovered Wi-Fi Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Discovered Wi-Fi Networks (${_accessPoints.length})",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: KiwiTheme.textSecondary,
                    ),
                  ),
                  if (_isScanning)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: KiwiTheme.tealAccent),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Networks List
              Expanded(
                child: ListView.builder(
                  itemCount: _accessPoints.length,
                  itemBuilder: (context, index) {
                    final ap = _accessPoints[index];
                    return _buildApCard(ap);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KiwiTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KiwiTheme.tealAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi_find_rounded, color: KiwiTheme.tealAccent, size: 24),
              SizedBox(width: 10),
              Text(
                "Wi-Fi Security Scanner",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KiwiTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Scan for nearby Wi-Fi networks and cryptographically authenticate hardware gateways against Evil Twin attacks.",
            style: TextStyle(fontSize: 12, color: KiwiTheme.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 14),

          // Gateway IP Field
          Row(
            children: [
              const Text("Gateway IP: ", style: TextStyle(fontSize: 12, color: KiwiTheme.textSecondary)),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _hostController,
                    style: const TextStyle(fontSize: 12, color: KiwiTheme.textPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      isDense: true,
                      hintText: "192.168.4.1",
                      filled: true,
                      fillColor: KiwiTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: KiwiTheme.surfaceElevated),
                      ),
                    ),
                    onChanged: (val) => _gatewayHost = val.trim(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Scan Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: KiwiTheme.tealAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Icon(Icons.wifi_find, size: 20),
              label: Text(
                _isScanning ? "Scanning Networks..." : "Scan Wi-Fi Networks",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _isScanning ? null : _startScan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApCard(ApScanItem ap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: KiwiTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ap.isTargetKiwiZone
              ? KiwiTheme.tealAccent.withValues(alpha: 0.5)
              : KiwiTheme.surfaceElevated,
          width: ap.isTargetKiwiZone ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _verifyGateway(ssid: ap.ssid, bssid: ap.bssid),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Wi-Fi Icon
                Container(
                  width: 42,
                  height: 42,
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
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ap.ssid,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: KiwiTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ap.isTargetKiwiZone)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: KiwiTheme.tealAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: KiwiTheme.tealAccent.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                "KIWI Gateway",
                                style: TextStyle(color: KiwiTheme.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
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
                          const SizedBox(width: 10),
                          Text(
                            ap.isOpen ? "Open" : "Secured",
                            style: TextStyle(
                              fontSize: 11,
                              color: ap.isOpen ? Colors.amber : KiwiTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action Verify Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ap.isTargetKiwiZone ? KiwiTheme.tealAccent : KiwiTheme.surfaceElevated,
                    foregroundColor: ap.isTargetKiwiZone ? Colors.black : KiwiTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("Verify", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _verifyGateway(ssid: ap.ssid, bssid: ap.bssid),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
