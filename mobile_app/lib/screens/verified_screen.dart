import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/crypto_service.dart';

class VerifiedScreen extends StatelessWidget {
  final VerificationResult? result;

  const VerifiedScreen({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final nonce = result?.nonce ?? "challenge_9A4bX89F";
    final sigHex = result?.signatureHex ?? "8F3A12C4...B90C19A0";
    final latency = result?.latencyMs ?? 14;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF151719)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Hardware Verified",
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

              // Verified Circle Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.25),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 64,
                  color: Color(0xFF10B981),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Connection Verified",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF151719),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Hardware Trust Anchor Confirmed (ESP32 Verified)",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF047857),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Cryptographic Handshake Proof Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CRYPTOGRAPHIC PROOF",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF047857),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildProofRow("Algorithm", "Ed25519 (256-bit)"),
                    _buildProofRow("Nonce Challenge", nonce),
                    _buildProofRow("64-Byte Signature", sigHex),
                    _buildProofRow("Public Key", "ed25519:e4:83:99:a1"),
                    _buildProofRow("LAN Latency", "${latency}ms"),
                  ],
                ),
              ),

              const Spacer(),

              // Primary CTA Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Connected & Secure",
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

  Widget _buildProofRow(String label, String value) {
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
              fontWeight: FontWeight.w600,
              color: const Color(0xFF151719),
            ),
          ),
        ],
      ),
    );
  }
}
