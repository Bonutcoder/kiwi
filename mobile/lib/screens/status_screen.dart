// KIWI Mutual Verification Status Screen
// Implements the 3 Visual Security States: Challenging, Verified, and Hostile (Iron Gate)

import 'package:flutter/material.dart';

import '../constants/security_constants.dart';
import '../models/verification_models.dart';
import '../services/network_service.dart';
import '../theme/kiwi_theme.dart';
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

class _StatusScreenState extends State<StatusScreen>
    with SingleTickerProviderStateMixin {
  ScreenState _state = ScreenState.challenging;
  HandshakeResult? _result;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _bypassExpanded = false;
  bool _bypassed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _executeHandshake();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
        backgroundColor: KiwiTheme.hostileBg,
        content: Text(
          "Security Bypassed. Threat entry remains permanently recorded in Threat Audit Log.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _state == ScreenState.verified
              ? "Shield Active"
              : _state == ScreenState.hostile
                  ? "Iron Gate Engaged"
                  : "Challenging Gateway",
        ),
        actions: [
          IconButton(
            tooltip: "Threat Audit Log",
            icon: const Icon(Icons.security),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target AP Meta Card
              _buildTargetMetaCard(),
              const SizedBox(height: 20),

              // Dynamic State Card
              if (_state == ScreenState.challenging)
                _buildChallengingCard()
              else if (_state == ScreenState.verified)
                _buildVerifiedCard()
              else
                _buildHostileCard(),

              const SizedBox(height: 20),

              // Re-challenge / Action Buttons
              if (_state != ScreenState.challenging)
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Re-run Mutual Verification"),
                  onPressed: _executeHandshake,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetMetaCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KiwiTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KiwiTheme.surfaceElevated),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi, color: KiwiTheme.tealAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ssid,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  "BSSID: ${widget.bssid} • Target Gateway: ${widget.gatewayHost}",
                  style: const TextStyle(fontSize: 11, color: KiwiTheme.textMuted, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATE 1: Challenging (Navy, Pulsing Radar)
  // ---------------------------------------------------------------------------
  Widget _buildChallengingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: KiwiTheme.challengingBg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KiwiTheme.challengingBorder.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KiwiTheme.challengingBg,
                boxShadow: [
                  BoxShadow(
                    color: KiwiTheme.challengingBorder.withValues(alpha: 0.4),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.lock_clock, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Mutual Authentication in Progress",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Generating 32-byte client challenge nonce & probing gateway at 192.168.4.1 (2000ms SLA)...",
            style: TextStyle(fontSize: 12, color: KiwiTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: KiwiTheme.challengingBorder),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATE 2: Verified (Emerald #064E3B, Shield Icon, Latency, "Connect Safely")
  // ---------------------------------------------------------------------------
  Widget _buildVerifiedCard() {
    final cert = _result?.certificate;
    final latency = _result?.latencyMs ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KiwiTheme.verifiedBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KiwiTheme.verifiedBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: KiwiTheme.verifiedBorder.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KiwiTheme.verifiedBorder.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.verified, color: KiwiTheme.verifiedBorder, size: 50),
          ),
          const SizedBox(height: 16),
          const Text(
            "Shield Active / Verified",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Genuine KIWI Root CA Trust Anchor Validated",
            style: TextStyle(fontSize: 12, color: Color(0xFFA7F3D0)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Diagnostic Metrics Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildMetricRow("Device ID", cert?.deviceId ?? "KIWI-GW-VERIFIED"),
                const Divider(color: Color(0xFF065F46), height: 16),
                _buildMetricRow("Handshake Latency", "$latency ms (Under 2000ms SLA)"),
                const Divider(color: Color(0xFF065F46), height: 16),
                _buildMetricRow("Verification Layers", "4/4 Passed + Direction 2 Authorized"),
                const Divider(color: Color(0xFF065F46), height: 16),
                _buildMetricRow("Revocation List (CRL)", "Clean (Not Revoked)"),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Connect Safely CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: KiwiTheme.verifiedBorder,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.lock_open_rounded, size: 20),
              label: const Text("Connect Safely", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: KiwiTheme.verifiedBg,
                    content: Text(
                      "Secure Tunnel Ready. Gateway cryptographically authenticated.",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATE 3: Hostile (Crimson #7F1D1D, "KIWI Iron Gate", Failure Reason, Bypass)
  // ---------------------------------------------------------------------------
  Widget _buildHostileCard() {
    final layer = _result?.failedLayer;
    final reason = _result?.failureReason ?? "Unknown Security Anomaly";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KiwiTheme.hostileBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KiwiTheme.hostileBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: KiwiTheme.hostileBorder.withValues(alpha: 0.3),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KiwiTheme.hostileBorder.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.gpp_bad, color: KiwiTheme.hostileBorder, size: 50),
          ),
          const SizedBox(height: 16),
          const Text(
            "KIWI Iron Gate",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            layer?.displayName ?? "Security Failure",
            style: const TextStyle(fontSize: 13, color: Color(0xFFFECACA), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Threat Explanation Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: KiwiTheme.hostileBorder.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: KiwiTheme.hostileBorder, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Hostile Access Point Detected",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFFEE2E2), height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: KiwiTheme.tealAccent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            "Auto-Logged to Threat Vault",
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Advanced Security Bypass Section
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _bypassExpanded,
              onExpansionChanged: (exp) => setState(() => _bypassExpanded = exp),
              tilePadding: EdgeInsets.zero,
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: KiwiTheme.textMuted, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Advanced Security Bypass",
                    style: TextStyle(fontSize: 13, color: KiwiTheme.textMuted, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DANGER: Connecting to an unverified gateway exposes your unencrypted DNS, credentials, and traffic to adversary interception.",
                        style: TextStyle(fontSize: 11, color: Color(0xFFFECACA), height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Note: Bypassing will still retain this incident in your local Threat Audit Log for forensic analysis.",
                        style: TextStyle(fontSize: 10, color: KiwiTheme.textMuted, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: KiwiTheme.hostileBorder, width: 1.5),
                            foregroundColor: Colors.white,
                            backgroundColor: _bypassed ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _bypassed ? null : _handleBypass,
                          child: Text(
                            _bypassed ? "Bypassed (Logged)" : "Connect Anyway (At Your Own Risk)",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFA7F3D0))),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
