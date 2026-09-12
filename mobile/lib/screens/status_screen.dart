// KIWI Mutual Verification Status Screen
// Plain, minimal Material UI for 4-layer mutual authentication results.

import 'package:flutter/material.dart';

import '../constants/security_constants.dart';
import '../models/verification_models.dart';
import '../services/network_service.dart';
import 'threat_log_screen.dart';

enum ScreenState { challenging, verified, hostile }

class StatusScreen extends StatefulWidget {
  final NetworkService networkService;
  final String ssid;
  final String bssid;
  final DemoScenario demoScenario;
  final String gatewayHost;

  const StatusScreen({
    super.key,
    required this.networkService,
    required this.ssid,
    required this.bssid,
    this.demoScenario = DemoScenario.none,
    this.gatewayHost = kDefaultGatewayHost,
  });

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  ScreenState _state = ScreenState.challenging;
  HandshakeResult? _result;
  bool _bypassed = false;

  @override
  void initState() {
    super.initState();
    _executeHandshake();
  }

  Future<void> _executeHandshake() async {
    setState(() {
      _state = ScreenState.challenging;
      _bypassed = false;
    });

    final res = await widget.networkService.performMutualHandshake(
      host: widget.gatewayHost,
      ssid: widget.ssid,
      bssid: widget.bssid,
      demoScenario: widget.demoScenario,
    );

    if (!mounted) return;

    setState(() {
      _result = res;
      _state = res.isVerified ? ScreenState.verified : ScreenState.hostile;
    });
  }

  void _handleBypass() {
    setState(() {
      _bypassed = true;
      _result?.bypassed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Security Bypassed. Threat entry recorded in Threat Audit Log."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gateway Verification"),
        actions: [
          IconButton(
            tooltip: "Threat Audit Log",
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ThreatLogScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Target Network Meta Info
              Text(
                widget.ssid,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "BSSID: ${widget.bssid} • Host: ${widget.gatewayHost}",
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Single Centered Status Display Text
              if (_state == ScreenState.challenging) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  "Verifying Gateway...",
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Conducting 4-layer Ed25519 mutual authentication (2000ms SLA)",
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ] else if (_state == ScreenState.verified) ...[
                const Text(
                  "VERIFIED",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Genuine Gateway Authenticated",
                  style: textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "Device ID: ${_result?.certificate?.deviceId ?? 'KIWI-GW-VERIFIED'}\n"
                  "Latency: ${_result?.latencyMs ?? 0} ms\n"
                  "All 4 Verification Layers Passed",
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const Text(
                  "NOT VERIFIED",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _result?.failedLayer?.displayName ?? "Security Failure",
                  style: textTheme.titleMedium?.copyWith(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _result?.failureReason ?? "Unknown Security Threat",
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Threat incident auto-logged to Threat Audit Log.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 36),

              // Stacked Buttons
              if (_state != ScreenState.challenging) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _executeHandshake,
                    child: const Text("Re-run Verification"),
                  ),
                ),
                const SizedBox(height: 12),
                if (_state == ScreenState.hostile) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _bypassed ? null : _handleBypass,
                      child: Text(_bypassed ? "Bypassed (Logged)" : "Connect Anyway (Bypass)"),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ThreatLogScreen()),
                      );
                    },
                    child: const Text("View Threat Log"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
