import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/crypto_service.dart';

class HostileScreen extends StatefulWidget {
  final VerificationResult? result;

  const HostileScreen({super.key, this.result});

  @override
  State<HostileScreen> createState() => _HostileScreenState();
}

class _HostileScreenState extends State<HostileScreen> {
  bool isBypassExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF2F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF151719)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Connection Blocked",
          style: GoogleFonts.inter(
            color: const Color(0xFF151719),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(),

              // Red Alert Circle Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.25),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gpp_bad_rounded,
                  size: 64,
                  color: Color(0xFFEF4444),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Connection Blocked",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF151719),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "No Hardware Signature Detected (Evil Twin Attack)",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFBE123C),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Threat Breakdown Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "THREAT ANALYSIS",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFBE123C),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildThreatRow("Ed25519 Handshake", "FAILED"),
                    _buildThreatRow("Hardware Key", "ABSENT / UNTRUSTED"),
                    _buildThreatRow("SSID Verification", "Spoofed Public Hotspot"),
                    _buildThreatRow("MitM Risk Level", "CRITICAL"),
                  ],
                ),
              ),

              const Spacer(),

              // Friction Bypass Collapsible ExpansionTile
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: ExpansionTile(
                  title: Text(
                    "Advanced Security Details & Risk Bypass",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Text(
                            "WARNING: Proceeding over an unverified network exposes your passwords, personal data, and session tokens to active interceptors.",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF7F1D1D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Warning: Connected without Hardware Verification!'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("Connect Anyway (Unsafe Bypass)"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Primary Blocked CTA Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Blocked for Safety",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThreatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }
}
