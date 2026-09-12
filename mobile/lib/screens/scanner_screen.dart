// KIWI Wi-Fi Scanner & Gateway Authenticator
// Plain, minimal Material UI for Wi-Fi scanning, connection, and gateway verification.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../constants/security_constants.dart';
import '../models/verification_models.dart';
import '../services/network_service.dart';
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
        _inlineErrors[ap.ssid] = "Could not connect to ${ap.ssid}. Select network in Wi-Fi settings.";
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KIWI"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isScanning || _connectingSsid != null || _isVerifying)
                      ? null
                      : _scanWifiNetworks,
                  child: Text(_isScanning ? "Scanning Wi-Fi..." : "Scan Wi-Fi"),
                ),
              ),
              const SizedBox(height: 24),

              // Wi-Fi List or Status Message
              if (_isScanning)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_accessPoints.isEmpty)
                Center(
                  child: Text(
                    "No Wi-Fi Networks Found",
                    style: textTheme.bodyLarge,
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _accessPoints.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final ap = _accessPoints[index];
                      return _buildApTile(ap);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApTile(ApScanItem ap) {
    final isConnectedToThis = _connectedSsid == ap.ssid;
    final isConnectingToThis = _connectingSsid == ap.ssid;
    final inlineErr = _inlineErrors[ap.ssid];
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    ap.ssid,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isConnectedToThis)
                  const Text(
                    "CONNECTED",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
            subtitle: Text(
              "${ap.bssid} • ${ap.rssi} dBm",
              style: textTheme.bodySmall,
            ),
          ),
          if (inlineErr != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inlineErr,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: isConnectingToThis ? null : () => _connectToNetwork(ap),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (isConnectingToThis || _isVerifying) ? null : () => _connectToNetwork(ap),
                  child: Text(isConnectingToThis ? "Connecting..." : "Connect"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : () => _verifyGateway(ssid: ap.ssid, bssid: ap.bssid),
                  child: Text(_isVerifying ? "Verifying..." : "Verify"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
