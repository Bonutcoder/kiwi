import 'package:flutter/material.dart';
import '../models/verification_models.dart';
import '../services/network_service.dart';
import '../theme/kiwi_theme.dart';

class StatusScreen extends StatefulWidget {
  final NetworkService networkService;
  final HandshakeResult? initialResult;

  const StatusScreen({
    super.key,
    required this.networkService,
    this.initialResult,
  });

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  late HandshakeResult _result;
  bool _isBypassExpanded = false;

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult ??
        HandshakeResult.verified(
          latencyMs: 14,
          certificate: GatewayCertificate(
            deviceId: "GW-68D111",
            publicKeyHex: "82a930bfe104882194c77112b32f91a4",
            signatureHex: "e90f2b881a7b...",
            issuedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          routerNonceHex: "4f99a812...",
          clientNonceHex: "91b2c4d0...",
        );
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = _result.isVerified;

    return Scaffold(
      backgroundColor: KiwiTheme.appBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: KiwiTheme.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isVerified ? "Connection Verified" : "Connection Blocked",
          style: const TextStyle(color: KiwiTheme.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Hero Status Circle Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isVerified ? KiwiTheme.verifiedMint : KiwiTheme.hostileRose,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVerified ? Icons.verified_rounded : Icons.shield_outlined,
                  size: 56,
                  color: isVerified ? KiwiTheme.verifiedDark : KiwiTheme.hostileRed,
                ),
              ),

              const SizedBox(height: 24),

              // Title Header
              Text(
                isVerified ? "Hardware Verified" : "Evil Twin Attack Detected!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isVerified ? KiwiTheme.charcoal : KiwiTheme.hostileRed,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isVerified
                    ? "Your connection is signed by a valid Ed25519 hardware anchor."
                    : "Rogue Wi-Fi network detected attempting to impersonate your campus access point.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: KiwiTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // Details & Cryptographic Proof Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: KiwiTheme.cardBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "NETWORK TELEMETRY",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: KiwiTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: "Gateway Device ID", value: _result.certificate?.deviceId ?? "GW-68D111"),
                    const Divider(height: 20),
                    _DetailRow(label: "Handshake Latency", value: "${_result.latencyMs} ms"),
                    const Divider(height: 20),
                    _DetailRow(
                      label: "Ed25519 Key Fingerprint",
                      value: _result.certificate?.publicKeyHex != null
                          ? "${_result.certificate!.publicKeyHex.substring(0, 14)}..."
                          : "Missing Signature",
                    ),
                  ],
                ),
              ),

              if (!isVerified) ...[
                const SizedBox(height: 16),
                // Friction Bypass Module
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: KiwiTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text(
                          "Ignore Risk & Bypass Lockdown",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: KiwiTheme.hostileRed),
                        ),
                        trailing: Icon(
                          _isBypassExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: KiwiTheme.hostileRed,
                        ),
                        onTap: () => setState(() => _isBypassExpanded = !_isBypassExpanded),
                      ),
                      if (_isBypassExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Warning: Continuing exposes your traffic to MITM interception.",
                                style: TextStyle(fontSize: 12, color: KiwiTheme.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: KiwiTheme.hostileRed,
                                    side: const BorderSide(color: KiwiTheme.hostileRed),
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Risk acknowledged. Connected to unverified AP.")),
                                    );
                                  },
                                  child: const Text("I Understand the Risk - Connect Anyway"),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: KiwiTheme.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KiwiTheme.charcoal),
        ),
      ],
    );
  }
}
