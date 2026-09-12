// KIWI Wi-Fi Scanner & Gateway Authenticator
// Plain, minimal reference Material UI for Wi-Fi scanning, connection, and gateway verification.

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("KIWI"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _connectedSsid != null ? "Connected WiFi: $_connectedSsid" : "Not connected to WiFi",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_isScanning || _connectingSsid != null || _isVerifying) ? null : _scanWifiNetworks,
                child: Text(_isScanning ? "Scanning WiFi..." : "Scan WiFi"),
              ),
              const SizedBox(height: 20),
              if (_isScanning)
                const CircularProgressIndicator()
              else if (_accessPoints.isEmpty)
                const Text(
                  "No WiFi networks found",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _accessPoints.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final ap = _accessPoints[index];
                      final isConnectingToThis = _connectingSsid == ap.ssid;
                      final inlineErr = _inlineErrors[ap.ssid];

                      return ListTile(
                        title: Text(ap.ssid),
                        subtitle: Text(
                          "${ap.bssid} • ${ap.rssi} dBm${inlineErr != null ? '\nError: $inlineErr' : ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: (isConnectingToThis || _isVerifying) ? null : () => _connectToNetwork(ap),
                              child: Text(isConnectingToThis ? "Connecting..." : "Connect"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isVerifying ? null : () => _verifyGateway(ssid: ap.ssid, bssid: ap.bssid),
                              child: Text(_isVerifying ? "Verifying..." : "Verify"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
