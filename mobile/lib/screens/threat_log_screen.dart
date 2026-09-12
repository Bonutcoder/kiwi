// KIWI Threat Audit Log Screen
// Plain, minimal Material UI for forensic threat logs.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/verification_models.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';

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
        title: const Text("Purge Threat Audit Log?"),
        content: const Text(
          "Are you sure you want to permanently clear all local threat incident records?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Purge All"),
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Threat Audit Log"),
        actions: [
          if (_logs.isNotEmpty)
            TextButton(
              onPressed: _clearLogs,
              child: const Text("Purge All", style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Text(
                    "No Threat Incidents Detected",
                    style: textTheme.bodyLarge,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = _logs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.failedLayerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.bypassed ? Colors.orange : Colors.red,
                              ),
                            ),
                          ),
                          Text(
                            item.bypassed ? "BYPASSED" : "BLOCKED",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.bypassed ? Colors.orange : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "${item.failureReason}\n"
                          "SSID: ${item.ssid} • BSSID: ${item.bssid}\n"
                          "Time: ${dateFormat.format(item.timestamp)}",
                          style: textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
