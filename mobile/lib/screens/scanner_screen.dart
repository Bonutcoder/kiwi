import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/network_service.dart';
import '../theme/kiwi_theme.dart';
import 'status_screen.dart';

class ScannerScreen extends StatefulWidget {
  final NetworkService networkService;

  const ScannerScreen({super.key, required this.networkService});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _requestPermissions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.nearbyWifiDevices.request();
  }

  Future<void> _runKiwiVerification() async {
    setState(() => _isScanning = true);

    try {
      final result = await widget.networkService.performMutualHandshake();

      if (mounted) {
        setState(() => _isScanning = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StatusScreen(
              networkService: widget.networkService,
              initialResult: result,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiwiTheme.appBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: KiwiTheme.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Kiwi Scan",
          style: TextStyle(color: KiwiTheme.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Animated Radar Pulse Orb Visual
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.15);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: KiwiTheme.cardBg,
                          boxShadow: [
                            BoxShadow(
                              color: KiwiTheme.verifiedMint.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.wifi_find_rounded,
                            size: 84,
                            color: KiwiTheme.charcoal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),

              const Text(
                "Scanning Hardware Anchors",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: KiwiTheme.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Kiwi verifies Ed25519 signatures of surrounding Wi-Fi access points to prevent Evil Twin attacks.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: KiwiTheme.textSecondary,
                ),
              ),

              const Spacer(),

              // Verification Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KiwiTheme.charcoal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isScanning ? null : _runKiwiVerification,
                  child: _isScanning
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text("Verifying Anchor...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Text(
                          "Verify Network",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
