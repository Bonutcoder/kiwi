import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../theme/kiwi_theme.dart';
import 'location_screen.dart';
import 'scanner_screen.dart';
import 'status_screen.dart';

class DashboardScreen extends StatefulWidget {
  final NetworkService networkService;

  const DashboardScreen({super.key, required this.networkService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeSsid = "Unknown";
  final bool _isSecured = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentNetwork();
  }

  Future<void> _loadCurrentNetwork() async {
    final ssid = await widget.networkService.getConnectedWifiSsid();
    if (mounted) {
      setState(() {
        _activeSsid = ssid ?? "Disconnected";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiwiTheme.appBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Background Watermark Graphic
            Positioned(
              right: -30,
              bottom: 40,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.wifi_lock_rounded,
                  size: 280,
                  color: KiwiTheme.charcoal,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header with Kiwi Logo & Profile
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: KiwiTheme.cardBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.psychology_alt_rounded,
                            color: KiwiTheme.charcoal,
                            size: 26,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: KiwiTheme.cardBg.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: KiwiTheme.verifiedDark,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _activeSsid,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: KiwiTheme.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Greeting Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Hi User,\nLet's secure your\nconnection.",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: KiwiTheme.charcoal,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2x2 Grid of White Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.15,
                      children: [
                        // CARD 1: Kiwi Scan
                        _DashboardCard(
                          icon: Icons.radar_rounded,
                          title: "Kiwi Scan",
                          subtitle: "Check Wi-Fi for anchor",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ScannerScreen(networkService: widget.networkService),
                              ),
                            ).then((_) => _loadCurrentNetwork());
                          },
                        ),

                        // CARD 2: Connection Status
                        _DashboardCard(
                          icon: Icons.verified_user_rounded,
                          title: "Connection\nStatus",
                          subtitle: _isSecured ? "Secured (Green)" : "Threat Alert!",
                          badgeColor: _isSecured ? KiwiTheme.verifiedMint : KiwiTheme.hostileRose,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StatusScreen(networkService: widget.networkService),
                              ),
                            );
                          },
                        ),

                        // CARD 3: Saved Anchors
                        _DashboardCard(
                          icon: Icons.bookmark_border_rounded,
                          title: "Saved anchors",
                          subtitle: "2 Verified nodes",
                          onTap: () => _showSavedAnchorsSheet(context),
                        ),

                        // CARD 4: Location
                        _DashboardCard(
                          icon: Icons.location_on_outlined,
                          title: "Location",
                          subtitle: "Set campus area",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LocationScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedAnchorsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Saved Hardware Anchors",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: KiwiTheme.charcoal,
              ),
            ),
            SizedBox(height: 16),
            _AnchorTile(
              ssid: "VIT-Campus-Secure",
              gatewayId: "GW-68D111",
              status: "Verified (Ed25519)",
            ),
            SizedBox(height: 8),
            _AnchorTile(
              ssid: "Kiwi-Trust-Node-1",
              gatewayId: "GW-99F204",
              status: "Verified (Ed25519)",
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KiwiTheme.cardBg,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: badgeColor ?? KiwiTheme.appBg.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: KiwiTheme.charcoal,
                  size: 22,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: KiwiTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: KiwiTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnchorTile extends StatelessWidget {
  final String ssid;
  final String gatewayId;
  final String status;

  const _AnchorTile({
    required this.ssid,
    required this.gatewayId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KiwiTheme.appBg.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded, color: KiwiTheme.verifiedDark),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ssid, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("ID: $gatewayId", style: const TextStyle(fontSize: 11, color: KiwiTheme.textSecondary)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: KiwiTheme.verifiedMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: KiwiTheme.charcoal),
            ),
          ),
        ],
      ),
    );
  }
}
