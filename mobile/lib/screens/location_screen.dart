import 'package:flutter/material.dart';
import '../theme/kiwi_theme.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _selectedLocation = "VIT University, Vellore";
  final TextEditingController _customLocationController = TextEditingController();

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
          "Location Anchor",
          style: TextStyle(
            color: KiwiTheme.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Radar Compass Graphic
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: KiwiTheme.cardBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: KiwiTheme.telemetryBlue.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.explore_rounded,
                    size: 72,
                    color: KiwiTheme.telemetryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Active Location Card
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
                    const Row(
                      children: [
                        Icon(Icons.my_location_rounded, color: KiwiTheme.telemetryBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "AUTO-DETECTED CAMPUS AREA",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: KiwiTheme.telemetryBlue,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedLocation,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: KiwiTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Latitude: 12.9692° N, Longitude: 79.1559° E",
                      style: TextStyle(
                        fontSize: 12,
                        color: KiwiTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Manual Location Entry Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KiwiTheme.charcoal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.edit_location_alt_rounded),
                  label: const Text(
                    "Enter Location Manually",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showManualEntryDialog(context),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Manual Location Entry"),
        content: TextField(
          controller: _customLocationController,
          decoration: const InputDecoration(
            hintText: "Enter campus or building name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KiwiTheme.charcoal),
            onPressed: () {
              if (_customLocationController.text.trim().isNotEmpty) {
                setState(() {
                  _selectedLocation = _customLocationController.text.trim();
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
