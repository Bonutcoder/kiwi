// KIWI Wi-Fi Scanner & Gateway Authenticator
// Minimalist UI: Real Wi-Fi network scanner with Connect and Verify buttons for each network.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _isVerifying = false;
  List<ApScanItem> _accessPoints = [];
  String? _connectingSsid;
  String? _connectedSsid;
  String? _connectedBssid;
  final Map<String, String> _inlineErrors = {};

  @override
  void initState() {
    super.initState();
    _refreshConnectedState();
    if (widget.autoScan) {
      _scanWifiNetworks();
    }
  }

  Future<void> _refreshConnectedState() async {
    final ssid = await widget.networkService.getConnectedWifiSsid();
    final bssid = await widget.networkService.getConnectedWifiBssid();
    if (mounted) {
      setState(() {
        _connectedSsid = ssid;
        _connectedBssid = bssid;
      });
    }
  }

  Future<void> _scanWifiNetworks() async {
    setState(() {
      _isScanning = true;
    });

    await _refreshConnectedState();

    final locStatus = await Permission.location.request();
    await Permission.nearbyWifiDevices.request();

    if (locStatus.isDenied || locStatus.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        openAppSettings();
      }
      return;
    }

    final List<ApScanItem> realAps = [];

    // Include currently connected network if present
    if (_connectedSsid != null && _connectedSsid!.isNotEmpty) {
      realAps.add(
        ApScanItem(
          ssid: _connectedSsid!,
          bssid: _connectedBssid ?? "00:00:00:00:00:00",
          rssi: -35,
          isOpen: true,
          isTargetKiwiZone: _connectedSsid == kTargetSoftApSsid,
        ),
      );
    }

    try {
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

          if (!realAps.any((item) => item.ssid == ssidStr || item.bssid == ap.bssid)) {
            realAps.add(
              ApScanItem(
                ssid: ssidStr,
                bssid: ap.bssid,
                rssi: ap.level,
                isOpen: !ap.capabilities.contains("WPA") && !ap.capabilities.contains("WEP"),
                isTargetKiwiZone: ssidStr == kTargetSoftApSsid,
              ),
            );
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _accessPoints = realAps;
      _isScanning = false;
    });
  }

  Future<void> _connectToNetwork(ApScanItem ap) async {
    setState(() {
      _connectingSsid = ap.ssid;
      _inlineErrors.remove(ap.ssid);
    });

    final success = await widget.networkService.connectToWifi(ap.ssid);
    await _refreshConnectedState();

    if (!mounted) return;

    setState(() {
      _connectingSsid = null;
      if (!success && _connectedSsid != ap.ssid) {
        _inlineErrors[ap.ssid] = "Could not verify connection to '${ap.ssid}'. Select network in settings and retry.";
      } else {
        _inlineErrors.remove(ap.ssid);
      }
    });
  }

  Future<void> _verifyGateway({
    required String ssid,
    required String bssid,
  }) async {
    setState(() {
      _isVerifying = true;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatusScreen(
          networkService: widget.networkService,
          ssid: ssid,
          bssid: bssid.isEmpty ? "00:00:00:00:00:00" : bssid,
          gatewayHost: kDefaultGatewayHost,
        ),
      ),
    );

    await _refreshConnectedState();
    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KIWI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: KiwiTheme.tealAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: _isScanning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.search, size: 18),
              label: Text(_isScanning ? "Scanning..." : "Scan Wi-Fi", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: (_isScanning || _connectingSsid != null || _isVerifying) ? null : _scanWifiNetworks,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isScanning)
                const LinearProgressIndicator(color: KiwiTheme.tealAccent, minHeight: 3),

              const SizedBox(height: 10),

              // Real Scanned Wi-Fi Networks List
              Expanded(
                child: _accessPoints.isEmpty && !_isScanning
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 48, color: KiwiTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text("No Wi-Fi Networks Discovered", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: KiwiTheme.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: KiwiTheme.tealAccent, foregroundColor: Colors.black),
                              icon: const Icon(Icons.search),
                              label: const Text("Scan Wi-Fi", style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _scanWifiNetworks,
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

  Widget _buildApCard(ApScanItem ap) {
    final isConnectedToThis = _connectedSsid == ap.ssid;
    final isConnectingToThis = _connectingSsid == ap.ssid;
    final inlineErr = _inlineErrors[ap.ssid];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: KiwiTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnectedToThis ? KiwiTheme.tealAccent : KiwiTheme.surfaceElevated,
          width: isConnectedToThis ? 1.8 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isConnectedToThis ? KiwiTheme.tealAccent.withValues(alpha: 0.18) : KiwiTheme.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi,
                    color: isConnectedToThis ? KiwiTheme.tealAccent : KiwiTheme.textMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ap.ssid,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KiwiTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isConnectedToThis)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: KiwiTheme.tealAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("CONNECTED", style: TextStyle(color: KiwiTheme.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${ap.bssid}  •  ${ap.rssi} dBm",
                        style: const TextStyle(fontSize: 11, color: KiwiTheme.textMuted, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (inlineErr != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KiwiTheme.hostileBg.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: KiwiTheme.hostileBorder.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(inlineErr, style: const TextStyle(fontSize: 11, color: Color(0xFFFECACA))),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                      onPressed: isConnectingToThis ? null : () => _connectToNetwork(ap),
                      child: const Text("Retry", style: TextStyle(color: KiwiTheme.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KiwiTheme.textPrimary,
                      side: BorderSide(color: isConnectingToThis ? KiwiTheme.tealAccent : KiwiTheme.surfaceElevated),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: isConnectingToThis
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: KiwiTheme.tealAccent))
                        : const Icon(Icons.link, size: 18),
                    label: Text(
                      isConnectingToThis ? "Connecting..." : (isConnectedToThis ? "Connected" : "Connect"),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: (isConnectingToThis || _isVerifying) ? null : () => _connectToNetwork(ap),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KiwiTheme.tealAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: _isVerifying
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.shield_outlined, size: 18),
                    label: Text(
                      _isVerifying ? "Verifying..." : "Verify",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isVerifying ? null : () => _verifyGateway(ssid: ap.ssid, bssid: ap.bssid),
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
