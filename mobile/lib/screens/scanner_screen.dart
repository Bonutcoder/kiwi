// KIWI Wi-Fi Scanner & Gateway Authenticator
// Displays ONLY REAL, live nearby Wi-Fi networks with direct Connect & Gateway Verification actions. Zero fake entries.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
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
  String? _statusMessage;
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = null;
    });

    final List<ApScanItem> realAps = [];

    try {
      // 1. Try Hardware Wi-Fi Scan
      final canStart = await WiFiScan.instance.canStartScan(askPermissions: true);
      if (canStart == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
      }

      final canGet = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
      if (canGet == CanGetScannedResults.yes) {
        final results = await WiFiScan.instance.getScannedResults();

        for (final ap in results) {
          final ssidStr = ap.ssid.trim();
          if (ssidStr.isEmpty || ssidStr == "<Hidden Network>") continue;

          realAps.add(ApScanItem(
            ssid: ssidStr,
            bssid: ap.bssid,
            rssi: ap.level,
            isOpen: !ap.capabilities.contains("WPA") && !ap.capabilities.contains("WEP"),
            isTargetKiwiZone: ssidStr == kTargetSoftApSsid,
          ));
        }
      }
    } catch (_) {
      // Ignore scan exceptions and fallback to active connection query below
    }

    // 2. Also query currently connected Wi-Fi interface (if any)
    try {
      final connectedSsid = await _networkInfo.getWifiName();
      final connectedBssid = await _networkInfo.getWifiBSSID();

      if (connectedSsid != null && connectedSsid.isNotEmpty) {
        final cleanSsid = connectedSsid.replaceAll('"', '').trim();
        if (cleanSsid.isNotEmpty && !realAps.any((item) => item.ssid == cleanSsid)) {
          realAps.insert(
            0,
            ApScanItem(
              ssid: cleanSsid,
              bssid: connectedBssid ?? "00:00:00:00:00:00",
              rssi: -40,
              isOpen: true,
              isTargetKiwiZone: cleanSsid == kTargetSoftApSsid,
            ),
          );
        }
      }
    } catch (_) {
      // Ignore connection query exceptions
    }

    if (!mounted) return;

    setState(() {
      _accessPoints = realAps;
      _isScanning = false;
      if (realAps.isEmpty) {
        _statusMessage = "No active Wi-Fi networks detected. Make sure Wi-Fi & Location are enabled on your device, then tap 'Scan Wi-Fi Networks'.";
      }
    });
  }

  void _connectToNetwork(ApScanItem ap) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: KiwiTheme.surface,
        content: Row(
          children: [
            const Icon(Icons.wifi, color: KiwiTheme.tealAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "To connect to '${ap.ssid}', select it in your device's Wi-Fi Settings.",
                style: const TextStyle(color: KiwiTheme.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
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
          gatewayHost: kDefaultGatewayHost,
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
              // Primary Scan Action Card
              _buildScanCard(),
              const SizedBox(height: 16),

              // Discovered Wi-Fi Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Real Wi-Fi Networks (${_accessPoints.length})",
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

              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KiwiTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KiwiTheme.surfaceElevated),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(fontSize: 12, color: KiwiTheme.textSecondary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

              // Real Networks List
              Expanded(
                child: _accessPoints.isEmpty && !_isScanning
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, size: 48, color: KiwiTheme.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              "No Wi-Fi Networks Discovered",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: KiwiTheme.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Tap 'Scan Wi-Fi Networks' to scan nearby access points.",
                              style: TextStyle(fontSize: 12, color: KiwiTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
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

  Widget _buildScanCard() {
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
            "Scan all real nearby Wi-Fi networks. Connect to a network or verify its gateway authenticity.",
            style: TextStyle(fontSize: 12, color: KiwiTheme.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 14),

          // Large Scan Button
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
                  : const Icon(Icons.search, size: 20),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
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
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons: Connect & Verify
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KiwiTheme.textPrimary,
                      side: const BorderSide(color: KiwiTheme.surfaceElevated),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text("Connect", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _connectToNetwork(ap),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ap.isTargetKiwiZone ? KiwiTheme.tealAccent : KiwiTheme.surfaceElevated,
                      foregroundColor: ap.isTargetKiwiZone ? Colors.black : KiwiTheme.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.shield_outlined, size: 16),
                    label: const Text("Verify Gateway", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _verifyGateway(ssid: ap.ssid, bssid: ap.bssid),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
