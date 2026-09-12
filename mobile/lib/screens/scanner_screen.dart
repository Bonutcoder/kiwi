// KIWI Wi-Fi Scanner & Gateway Authenticator
// Handles permission rationale, hardware Wi-Fi scanning (filtered to open networks),
// per-card connection loading with inline error handling, persistent connected SSID bar,
// and mutual authentication verification flow.

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
  String? _statusMessage;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _refreshConnectedState();
    if (widget.autoScan) {
      _requestPermissionsAndScan();
    }
  }

  /// Refreshes the currently connected network status from network_info_plus
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

  /// 1. Request Runtime Permissions with Rationale Dialog if denied
  Future<void> _requestPermissionsAndScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = null;
      _permissionDenied = false;
    });

    await _refreshConnectedState();

    final locStatus = await Permission.location.request();
    await Permission.nearbyWifiDevices.request();

    if (locStatus.isDenied || locStatus.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isScanning = false;
          _statusMessage = "Location permission is required by Android to discover nearby Wi-Fi networks.";
        });
        _showPermissionRationaleDialog();
      }
      return;
    }

    await _performRealScan();
  }

  /// Displays clear Rationale Dialog explaining why permissions are required
  void _showPermissionRationaleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KiwiTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: KiwiTheme.tealAccent, size: 24),
            SizedBox(width: 10),
            Text("Location Required", style: TextStyle(color: KiwiTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Android requires Location & Nearby Wi-Fi permissions to scan nearby wireless access points. "
          "Without this permission, hardware Wi-Fi scans cannot detect nearby gateways.",
          style: TextStyle(color: KiwiTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: KiwiTheme.textMuted)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KiwiTheme.tealAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text("Grant Permission", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  /// 2. Perform Hardware Wi-Fi Scan - Filtered strictly to OPEN / UNENCRYPTED networks
  Future<void> _performRealScan() async {
    final List<ApScanItem> openAps = [];
    String? diagMsg;

    // Add current active interface if present
    if (_connectedSsid != null && _connectedSsid!.isNotEmpty) {
      openAps.add(
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
      switch (canStart) {
        case CanStartScan.yes:
          await WiFiScan.instance.startScan();
          break;
        case CanStartScan.noLocationServiceDisabled:
          diagMsg = "Location (GPS) is turned OFF in phone settings. Turn ON Location (GPS) in your top control shade to scan Wi-Fi.";
          break;
        case CanStartScan.noLocationPermissionDenied:
        case CanStartScan.noLocationPermissionRequired:
          diagMsg = "Location permission was denied.";
          _permissionDenied = true;
          break;
        default:
          break;
      }

      final canGet = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
      if (canGet == CanGetScannedResults.yes) {
        final results = await WiFiScan.instance.getScannedResults();

        for (final ap in results) {
          final ssidStr = ap.ssid.trim();
          if (ssidStr.isEmpty || ssidStr == "<Hidden Network>") continue;

          // FILTER: Show OPEN / UNENCRYPTED networks as specified in requirement 1
          final isOpen = !ap.capabilities.contains("WPA") && !ap.capabilities.contains("WEP");
          if (!isOpen && ssidStr != kTargetSoftApSsid) continue;

          if (!openAps.any((item) => item.ssid == ssidStr || item.bssid == ap.bssid)) {
            openAps.add(
              ApScanItem(
                ssid: ssidStr,
                bssid: ap.bssid,
                rssi: ap.level,
                isOpen: isOpen,
                isTargetKiwiZone: ssidStr == kTargetSoftApSsid,
              ),
            );
          }
        }
      } else if (diagMsg == null) {
        if (canGet == CanGetScannedResults.noLocationServiceDisabled) {
          diagMsg = "Location (GPS) is turned OFF in phone settings. Turn ON Location in top control shade to scan Wi-Fi.";
        }
      }
    } catch (e) {
      diagMsg = "Scan error: $e";
    }

    if (!mounted) return;

    setState(() {
      _accessPoints = openAps;
      _isScanning = false;
      if (diagMsg != null) {
        _statusMessage = diagMsg;
      } else if (openAps.isEmpty) {
        _statusMessage = "No open Wi-Fi networks found nearby.";
      }
    });
  }

  /// 3. Connect to a specific Wi-Fi Network with per-card loading & inline error handling
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
        _inlineErrors[ap.ssid] = "Could not verify connection to '${ap.ssid}'. Ensure network is selected in Wi-Fi settings and retry.";
      } else {
        _inlineErrors.remove(ap.ssid);
      }
    });
  }

  /// 4. Mutual Handshake Verification Trigger
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

    // Reset flow cleanly on returning from StatusScreen
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("KIWI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text(
                  _connectedSsid != null ? "Connected: $_connectedSsid" : "Wi-Fi Safety Companion",
                  style: TextStyle(
                    fontSize: 11,
                    color: _connectedSsid != null ? KiwiTheme.tealAccent : KiwiTheme.textSecondary,
                    fontWeight: _connectedSsid != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Requirement 1: Rescan Icon Button in AppBar
          IconButton(
            tooltip: "Rescan Wi-Fi Networks",
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: KiwiTheme.tealAccent),
                  )
                : const Icon(Icons.refresh, color: KiwiTheme.tealAccent),
            onPressed: (_isScanning || _connectingSsid != null || _isVerifying) ? null : _requestPermissionsAndScan,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Requirement 2 & 3: Persistent Active Connection Status Bar
              _buildConnectedStatusBar(),
              const SizedBox(height: 14),

              // Discovered Networks Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Open Wi-Fi Networks (${_accessPoints.length})",
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

              if (_permissionDenied)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KiwiTheme.hostileBg.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KiwiTheme.hostileBorder.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Location permission is required to scan open networks.",
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: _showPermissionRationaleDialog,
                        child: const Text("Grant", style: TextStyle(color: KiwiTheme.tealAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              if (_statusMessage != null && !_permissionDenied)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
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

              // Open Networks List or Empty State
              Expanded(
                child: _isScanning
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: KiwiTheme.tealAccent),
                            SizedBox(height: 14),
                            Text("Scanning for open Wi-Fi networks...", style: TextStyle(color: KiwiTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                      )
                    : _accessPoints.isEmpty
                        ? _buildEmptyState()
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

  /// Persistent Connected Status Bar above the list
  Widget _buildConnectedStatusBar() {
    final isConnected = _connectedSsid != null && _connectedSsid!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KiwiTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? KiwiTheme.tealAccent.withValues(alpha: 0.6) : KiwiTheme.surfaceElevated,
          width: isConnected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: isConnected ? KiwiTheme.tealAccent : KiwiTheme.textMuted,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? _connectedSsid! : "Not Connected to Wi-Fi",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: KiwiTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected ? "Active Gateway IP: $kDefaultGatewayHost" : "Connect to an open network below to challenge gateway",
                      style: const TextStyle(fontSize: 11, color: KiwiTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? KiwiTheme.tealAccent.withValues(alpha: 0.15) : KiwiTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isConnected ? KiwiTheme.tealAccent : KiwiTheme.textMuted.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isConnected ? "ACTIVE" : "OFFLINE",
                  style: TextStyle(
                    color: isConnected ? KiwiTheme.tealAccent : KiwiTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KiwiTheme.tealAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isVerifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                      )
                    : const Icon(Icons.shield_outlined, size: 20),
                label: Text(
                  _isVerifying ? "Verifying Gateway..." : "Verify Connected Gateway",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: (_isVerifying || _connectingSsid != null)
                    ? null
                    : () => _verifyGateway(ssid: _connectedSsid!, bssid: _connectedBssid ?? ""),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Empty State Widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 54, color: KiwiTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 14),
          const Text(
            "No Open Wi-Fi Networks Found",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KiwiTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            "Only unencrypted open networks are displayed for gateway testing.\nEnsure Wi-Fi & Location (GPS) are ON.",
            style: TextStyle(fontSize: 12, color: KiwiTheme.textMuted, height: 1.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: KiwiTheme.tealAccent,
              side: const BorderSide(color: KiwiTheme.tealAccent),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Rescan", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _requestPermissionsAndScan,
          ),
        ],
      ),
    );
  }

  /// Individual Open Network Card
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
          color: isConnectedToThis
              ? KiwiTheme.tealAccent
              : ap.isTargetKiwiZone
                  ? KiwiTheme.tealAccent.withValues(alpha: 0.5)
                  : KiwiTheme.surfaceElevated,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isConnectedToThis
                        ? KiwiTheme.tealAccent.withValues(alpha: 0.18)
                        : KiwiTheme.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi,
                    color: isConnectedToThis ? KiwiTheme.tealAccent : KiwiTheme.textMuted,
                    size: 22,
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
                          Text("${ap.rssi} dBm", style: const TextStyle(fontSize: 11, color: KiwiTheme.textMuted)),
                          const SizedBox(width: 10),
                          const Text("Open", style: TextStyle(fontSize: 11, color: Colors.amber)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Inline Error Banner if connection attempt failed
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
                      child: Text(
                        inlineErr,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFFECACA), height: 1.3),
                      ),
                    ),
                    const SizedBox(width: 6),
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

            // Action Buttons based on state
            if (isConnectedToThis)
              ElevatedButton.icon(
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
                  _isVerifying ? "Verifying Gateway..." : "Verify Gateway",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: _isVerifying ? null : () => _verifyGateway(ssid: ap.ssid, bssid: ap.bssid),
              )
            else
              OutlinedButton.icon(
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
                  isConnectingToThis ? "Connecting to ${ap.ssid}..." : "Connect",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: (_connectingSsid != null || _isVerifying) ? null : () => _connectToNetwork(ap),
              ),
          ],
        ),
      ),
    );
  }
}
