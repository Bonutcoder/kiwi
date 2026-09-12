import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/crypto_service.dart';
import 'verified_screen.dart';
import 'hostile_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    setState(() {
      isScanning = true;
    });

    final result = await CryptoService.verifyHardwareAnchor();

    if (!mounted) return;
    setState(() {
      isScanning = false;
    });

    if (result.isVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifiedScreen(result: result),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HostileScreen(result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF151719)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Kiwi Anchor",
          style: GoogleFonts.inter(
            color: const Color(0xFF151719),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(),

              // Central Wi-Fi Orb Pulse Visual
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Concentric Pulse Outer Ring 2
                      Container(
                        width: 220 + (_pulseController.value * 20),
                        height: 220 + (_pulseController.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0284C7).withOpacity(
                            0.08 * (1 - _pulseController.value),
                          ),
                        ),
                      ),
                      // Concentric Pulse Outer Ring 1
                      Container(
                        width: 170 + (_pulseController.value * 15),
                        height: 170 + (_pulseController.value * 15),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0284C7).withOpacity(
                            0.15 * (1 - _pulseController.value),
                          ),
                        ),
                      ),
                      // Inner White Circle Medallion
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withOpacity(0.2),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isScanning
                              ? Icons.sync_rounded
                              : Icons.wifi_lock_rounded,
                          size: 56,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 48),

              // Title and Subtitle Text
              Text(
                isScanning ? "Verifying Trust Anchor..." : "Verify Your Connection",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF151719),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isScanning
                    ? "Executing Ed25519 cryptographic handshake with gateway IP 192.168.4.1"
                    : "Hardware-Verified Wi-Fi Security Protocol",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),

              const Spacer(),

              // Single Sleek Pill CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isScanning ? null : _startVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isScanning
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "Verify Network",
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
