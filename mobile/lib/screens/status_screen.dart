// KIWI Mutual Verification Status Screen
// Plain, minimal reference Material UI for 4-layer mutual authentication results.

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
        content: Text("Security Bypassed. Incident recorded in Threat Log."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color? statusColor;

    if (_state == ScreenState.challenging) {
      statusText = "Challenging Gateway...";
      statusColor = null;
    } else if (_state == ScreenState.verified) {
      statusText = "VERIFIED: Genuine Gateway Authenticated\n"
          "Device ID: ${_result?.certificate?.deviceId ?? 'KIWI-GW-VERIFIED'}\n"
          "Latency: ${_result?.latencyMs ?? 0} ms";
      statusColor = Colors.green;
    } else {
      statusText = "NOT VERIFIED: ${_result?.failedLayer?.displayName ?? 'Security Failure'}\n"
          "${_result?.failureReason ?? 'Unknown Security Threat'}";
      statusColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gateway Verification"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Target WiFi: ${widget.ssid}",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "BSSID: ${widget.bssid}",
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_state == ScreenState.challenging)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _executeHandshake,
                  child: const Text("Re-run Verification"),
                ),
                const SizedBox(height: 20),
                if (_state == ScreenState.hostile) ...[
                  ElevatedButton(
                    onPressed: _bypassed ? null : _handleBypass,
                    child: Text(_bypassed ? "Bypassed (Logged)" : "Connect Anyway (Bypass)"),
                  ),
                  const SizedBox(height: 20),
                ],
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ThreatLogScreen()),
                    );
                  },
                  child: const Text("View Threat Log"),
                ),
              ],
              const SizedBox(height: 30),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
