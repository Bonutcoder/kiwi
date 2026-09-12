// KIWI Threat Audit Log Screen
// Forensic history of detected rogue APs, forged certificates, and bypass events

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/verification_models.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';
import '../theme/kiwi_theme.dart';

class ThreatLogScreen extends StatefulWidget {
  const ThreatLogScreen({super.key});

  @override
  State<ThreatLogScreen> createState() => _ThreatLogScreenState();
}

class _ThreatLogScreenState extends State<ThreatLogScreen> {
  late StorageService _storageService;
  List<ThreatLogEntry> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final crypto = CryptoService();
    _storageService = StorageService(crypto);
    await _storageService.init();

    setState(() {
      _logs = _storageService.getThreatLogs();
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KiwiTheme.surface,
        title: const Text("Purge Threat Audit Log?"),
        content: const Text(
          "Are you sure you want to permanently clear all local threat incident records?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: KiwiTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KiwiTheme.hostileBorder),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Purge All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.clearThreatLogs();
      setState(() {
        _logs = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Threat audit log cleared.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Threat Audit Log"),
        actions: [
          if (_logs.isNotEmpty)
            IconButton(
              tooltip: "Purge Audit Trail",
              icon: const Icon(Icons.delete_sweep, color: KiwiTheme.hostileBorder),
              onPressed: _clearLogs,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: KiwiTheme.tealAccent),
            )
          : _logs.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _logs[index];
                    return _buildLogCard(item, dateFormat);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KiwiTheme.surface,
                border: Border.all(color: KiwiTheme.surfaceElevated),
              ),
              child: const Icon(Icons.verified_user, size: 56, color: KiwiTheme.tealAccent),
            ),
            const SizedBox(height: 20),
            const Text(
              "No Threat Incidents Detected",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KiwiTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your device has not encountered any rogue APs, forged certificates, or replay attacks.",
              style: TextStyle(fontSize: 13, color: KiwiTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(ThreatLogEntry item, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KiwiTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.bypassed
              ? Colors.amber.withValues(alpha: 0.5)
              : KiwiTheme.hostileBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 16,
                    color: item.bypassed ? Colors.amber : KiwiTheme.hostileBorder,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.failedLayerName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: item.bypassed ? Colors.amber : KiwiTheme.hostileBorder,
                    ),
                  ),
                ],
              ),
              if (item.bypassed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                  ),
                  child: const Text(
                    "USER BYPASSED",
                    style: TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: KiwiTheme.hostileBorder.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: KiwiTheme.hostileBorder.withValues(alpha: 0.6)),
                  ),
                  child: const Text(
                    "BLOCKED",
                    style: TextStyle(fontSize: 9, color: KiwiTheme.hostileBorder, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.failureReason,
            style: const TextStyle(fontSize: 12, color: KiwiTheme.textPrimary, height: 1.3),
          ),
          const Divider(color: KiwiTheme.surfaceElevated, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SSID: ${item.ssid}",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: KiwiTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text("BSSID: ${item.bssid}",
                      style: const TextStyle(fontSize: 10, color: KiwiTheme.textMuted, fontFamily: 'monospace')),
                ],
              ),
              Text(
                dateFormat.format(item.timestamp),
                style: const TextStyle(fontSize: 10, color: KiwiTheme.textMuted),
              ),
            ],
          ),
          if (item.deviceId != null) ...[
            const SizedBox(height: 6),
            Text(
              "Target Device ID: ${item.deviceId}",
              style: const TextStyle(fontSize: 10, color: KiwiTheme.tealAccent, fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }
}
