import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/kiwi_painter.dart';
import 'scan_screen.dart';
import 'verified_screen.dart';
import 'hostile_screen.dart';
import 'location_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isSecured = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBAC0B9),
      body: SafeArea(
        child: Stack(
          children: [
            // Background Watermark Kiwi Bird
            Positioned(
              right: -30,
              bottom: -20,
              width: 280,
              height: 220,
              child: Opacity(
                opacity: 0.35,
                child: CustomPaint(
                  painter: KiwiBirdPainter(
                    color: const Color(0xFF151719),
                    strokeWidth: 3.5,
                  ),
                ),
              ),
            ),

            // Main Content Layout
            Column(
              children: [
                // Top Header Region
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kiwi Bird Logo Icon
                      SizedBox(
                        width: 54,
                        height: 46,
                        child: CustomPaint(
                          painter: KiwiBirdPainter(
                            color: const Color(0xFF151719),
                            strokeWidth: 2.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Display Greeting Headline
                      Text(
                        "Hi User,\nLet's secure your\nconnection.",
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF151719),
                          height: 1.08,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 2x2 Feature Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.22,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Card 1: Sentinel Scan
                        _buildActionCard(
                          context: context,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ScanScreen(),
                              ),
                            );
                          },
                          iconWidget: _buildScanIcon(),
                          title: "Sentinel Scan",
                          subtitle: "Check Wi-Fi for anchor",
                        ),

                        // Card 2: Connection Status
                        _buildActionCard(
                          context: context,
                          onTap: () {
                            if (isSecured) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VerifiedScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HostileScreen(),
                                ),
                              );
                            }
                          },
                          iconWidget: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSecured
                                  ? const Color(0xFF8CE2A8)
                                  : const Color(0xFFFECDD3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSecured ? Icons.lock_outline : Icons.gpp_maybe,
                              size: 18,
                              color: isSecured
                                  ? const Color(0xFF113A21)
                                  : const Color(0xFF9F1239),
                            ),
                          ),
                          title: "Connection\nStatus",
                          subtitle: isSecured ? "Current: Secured (Green)" : "Current: Blocked (Red)",
                        ),

                        // Card 3: Saved Anchors
                        _buildActionCard(
                          context: context,
                          onTap: () => _showSavedAnchorsModal(context),
                          iconWidget: const Icon(
                            Icons.bookmark_border_rounded,
                            size: 26,
                            color: Color(0xFF151719),
                          ),
                          title: "Saved anchors",
                        ),

                        // Card 4: Settings
                        _buildActionCard(
                          context: context,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LocationScreen(),
                              ),
                            );
                          },
                          iconWidget: const Icon(
                            Icons.settings_outlined,
                            size: 26,
                            color: Color(0xFF151719),
                          ),
                          title: "Settings",
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Search Bar & Floating Dock Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    children: [
                      // Pill Search Bar
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DED8).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Search",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF6B7280),
                              size: 18,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Floating Dock & Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left Dock Capsule
                          Container(
                            height: 52,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF151719),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // White Active Layers Button
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.layers_outlined,
                                    color: Color(0xFF151719),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Profile Button
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isSecured = !isSecured;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isSecured
                                              ? 'Simulated State: Hardware Verified (Green)'
                                              : 'Simulated State: Evil Twin Blocked (Red)',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right Floating Action Button (+)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScanScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFF151719),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white70,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required VoidCallback onTap,
    required Widget iconWidget,
    required String title,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            iconWidget,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF151719),
                    height: 1.15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanIcon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF151719),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF151719),
                width: 1.5,
              ),
            ),
          ),
          const Icon(
            Icons.check,
            size: 14,
            color: Color(0xFF151719),
          ),
        ],
      ),
    );
  }

  void _showSavedAnchorsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Saved Anchors",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF151719),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnchorItem(
              name: "Station Master AP-04",
              ip: "192.168.1.1",
              status: "Ed25519 Verified",
              color: const Color(0xFF10B981),
            ),
            _buildAnchorItem(
              name: "Nordic Express Lounge 5G",
              ip: "10.0.12.1",
              status: "Trust Anchor Rooted",
              color: const Color(0xFF10B981),
            ),
            _buildAnchorItem(
              name: "Central Transit Mesh Node",
              ip: "172.16.0.1",
              status: "Anchor Key Validated",
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnchorItem({
    required String name,
    required String ip,
    required String status,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF151719),
                ),
              ),
              Text(
                "IP: $ip",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
