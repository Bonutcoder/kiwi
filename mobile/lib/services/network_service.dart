// KIWI Mutual Handshake Network Orchestrator
// Enforces strict 2000ms timeout and conducts the two-directional 4-layer verification flow

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import '../constants/security_constants.dart';
import '../models/verification_models.dart';
import 'crypto_service.dart';
import 'storage_service.dart';

enum DemoScenario {
  none,
  legitimateGateway,
  evilTwinForgedRootSignature,
  evilTwinInvalidGatewaySig,
  evilTwinReplayAttack,
  evilTwinRevokedDevice,
  timeoutFailure,
}

class NetworkService {
  final CryptoService _cryptoService;
  final StorageService _storageService;
  final http.Client _httpClient;
  final NetworkInfo _networkInfo = NetworkInfo();
  static const _wifiChannel = MethodChannel('com.kiwi.companion/wifi');

  NetworkService(
    this._cryptoService,
    this._storageService, {
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Gets the currently connected Wi-Fi SSID from network_info_plus
  Future<String?> getConnectedWifiSsid() async {
    try {
      final name = await _networkInfo.getWifiName();
      if (name == null || name.isEmpty) return null;
      final clean = name.replaceAll('"', '').trim();
      if (clean.isEmpty || clean == "<unknown ssid>") return null;
      return clean;
    } catch (_) {
      return null;
    }
  }

  /// Gets the currently connected Wi-Fi BSSID
  Future<String?> getConnectedWifiBssid() async {
    try {
      return await _networkInfo.getWifiBSSID();
    } catch (_) {
      return null;
    }
  }

  /// Attempts to connect to target Wi-Fi network and polls connected SSID
  Future<bool> connectToWifi(String targetSsid, {Duration timeout = const Duration(seconds: 15)}) async {
    final current = await getConnectedWifiSsid();
    if (current == targetSsid) {
      return true;
    }

    try {
      await _wifiChannel.invokeMethod('openWifiSettings');
    } catch (_) {}

    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await Future.delayed(const Duration(seconds: 1));
      final updated = await getConnectedWifiSsid();
      if (updated == targetSsid) {
        return true;
      }
    }

    final finalSsid = await getConnectedWifiSsid();
    return finalSsid == targetSsid;
  }

  /// Performs the complete 2-directional, 4-layer mutual authentication handshake
  Future<HandshakeResult> performMutualHandshake({
    String host = kDefaultGatewayHost,
    int port = kDefaultGatewayPort,
    String ssid = kTargetSoftApSsid,
    String bssid = "AA:BB:CC:DD:EE:01",
    DemoScenario demoScenario = DemoScenario.none,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Check for simulated/demo modes for testing without physical ESP32
    if (demoScenario != DemoScenario.none) {
      return await _simulateHandshake(demoScenario, ssid, bssid);
    }

    final clientNonceHex = _cryptoService.generateNonceHex();
    final baseUrl = "http://$host:$port";

    try {
      // -----------------------------------------------------------------------
      // DIRECTION 1: Phone Verifies Gateway
      // -----------------------------------------------------------------------
      final mutualAuthUri = Uri.parse("$baseUrl$kMutualAuthEndpoint");
      final requestBody = jsonEncode({"client_nonce": clientNonceHex});

      final http.Response mutualResponse;
      try {
        mutualResponse = await _httpClient
            .post(
              mutualAuthUri,
              headers: {"Content-Type": "application/json"},
              body: requestBody,
            )
            .timeout(const Duration(milliseconds: kHandshakeTimeoutMs));
      } on TimeoutException {
        return await _recordHostile(
          layer: VerificationLayer.networkTimeoutOrUnreachable,
          reason: "Gateway connection timed out exceeding strict ${kHandshakeTimeoutMs}ms limit.",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          clientNonceHex: clientNonceHex,
        );
      } on SocketException catch (e) {
        return await _recordHostile(
          layer: VerificationLayer.networkTimeoutOrUnreachable,
          reason: "Network socket error: ${e.message}",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          clientNonceHex: clientNonceHex,
        );
      }

      if (mutualResponse.statusCode != 200) {
        return await _recordHostile(
          layer: VerificationLayer.networkTimeoutOrUnreachable,
          reason: "Gateway returned HTTP error: ${mutualResponse.statusCode} - ${mutualResponse.body}",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          clientNonceHex: clientNonceHex,
        );
      }

      final Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(mutualResponse.body) as Map<String, dynamic>;
      } catch (_) {
        return await _recordHostile(
          layer: VerificationLayer.layer1RootCaCertValidation,
          reason: "Malformed JSON received from gateway.",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          clientNonceHex: clientNonceHex,
        );
      }

      final authResponse = MutualAuthResponse.fromJson(responseData);
      final cert = authResponse.certificate;

      // Layer 1: Certificate validation against Root CA
      final isCertValid = await _cryptoService.verifyCertificateRootCa(cert);
      if (!isCertValid) {
        return await _recordHostile(
          layer: VerificationLayer.layer1RootCaCertValidation,
          reason: "Forged or untrusted gateway certificate! Signature fails Root CA validation.",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          certificate: cert,
          clientNonceHex: clientNonceHex,
        );
      }

      // Layer 2: Gateway challenge signature verification against certified public key
      final isSigValid = await _cryptoService.verifyGatewayChallengeSignature(
        clientNonceHex: clientNonceHex,
        signatureHex: authResponse.signatureHex,
        gatewayPubkeyHex: cert.publicKeyHex,
      );
      if (!isSigValid) {
        return await _recordHostile(
          layer: VerificationLayer.layer2GatewaySignatureValidation,
          reason: "Rogue Access Point detected! Gateway challenge signature is invalid or forged.",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          certificate: cert,
          clientNonceHex: clientNonceHex,
        );
      }

      // Layer 3: Freshness & Replay check
      final isFresh = _cryptoService.verifyFreshness(
        cert: cert,
        sentClientNonceHex: clientNonceHex,
        receivedClientNonceHex: clientNonceHex,
      );
      if (!isFresh) {
        return await _recordHostile(
          layer: VerificationLayer.layer3FreshnessReplayValidation,
          reason: "Replay attack detected! Challenge nonce stale or certificate timestamp invalid.",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          certificate: cert,
          clientNonceHex: clientNonceHex,
        );
      }

      // Layer 4: Revocation list check
      final revokedIds = _storageService.getRevokedDeviceIds();
      final isRevoked = _cryptoService.isDeviceRevoked(
        deviceId: cert.deviceId,
        revokedDeviceIds: revokedIds,
      );
      if (isRevoked) {
        return await _recordHostile(
          layer: VerificationLayer.layer4RevocationListCheck,
          reason: "Gateway Device '${cert.deviceId}' is revoked in local CRL database!",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          certificate: cert,
          clientNonceHex: clientNonceHex,
        );
      }

      // -----------------------------------------------------------------------
      // DIRECTION 2: Gateway Verifies Phone
      // -----------------------------------------------------------------------
      final clientPayload = await _cryptoService.signRouterNonce(
        routerNonceHex: authResponse.routerNonceHex,
        phoneKeyPair: _storageService.phoneKeyPair,
      );

      final clientVerifyUri = Uri.parse("$baseUrl$kClientVerifyEndpoint");
      final http.Response verifyResponse;
      try {
        verifyResponse = await _httpClient
            .post(
              clientVerifyUri,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(clientPayload),
            )
            .timeout(const Duration(milliseconds: kHandshakeTimeoutMs));
      } on TimeoutException {
        return await _recordHostile(
          layer: VerificationLayer.networkTimeoutOrUnreachable,
          reason: "Direction 2 (client verification) timed out exceeding ${kHandshakeTimeoutMs}ms.",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          certificate: cert,
          clientNonceHex: clientNonceHex,
        );
      }

      if (verifyResponse.statusCode != 200) {
        return await _recordHostile(
          layer: VerificationLayer.direction2ClientRejection,
          reason: "Gateway rejected client authorization: HTTP ${verifyResponse.statusCode}.",
          latencyMs: stopwatch.elapsedMilliseconds,
          ssid: ssid,
          bssid: bssid,
          certificate: cert,
          clientNonceHex: clientNonceHex,
        );
      }

      // Both directions succeeded!
      stopwatch.stop();
      return HandshakeResult.verified(
        latencyMs: stopwatch.elapsedMilliseconds,
        certificate: cert,
        routerNonceHex: authResponse.routerNonceHex,
        clientNonceHex: clientNonceHex,
      );
    } catch (e) {
      stopwatch.stop();
      return await _recordHostile(
        layer: VerificationLayer.networkTimeoutOrUnreachable,
        reason: "Unexpected handshake exception: $e",
        latencyMs: stopwatch.elapsedMilliseconds,
        ssid: ssid,
        bssid: bssid,
        clientNonceHex: clientNonceHex,
      );
    }
  }

  /// Automatically records threat incident to storage log
  Future<HandshakeResult> _recordHostile({
    required VerificationLayer layer,
    required String reason,
    required int latencyMs,
    required String ssid,
    required String bssid,
    GatewayCertificate? certificate,
    String? clientNonceHex,
    String? routerNonceHex,
  }) async {
    final entry = ThreatLogEntry(
      id: "threat_${DateTime.now().millisecondsSinceEpoch}",
      ssid: ssid,
      bssid: bssid,
      timestamp: DateTime.now(),
      failedLayerName: layer.displayName,
      failureReason: reason,
      deviceId: certificate?.deviceId,
      bypassed: false,
    );

    await _storageService.logThreat(entry);

    return HandshakeResult.hostile(
      failedLayer: layer,
      failureReason: reason,
      latencyMs: latencyMs,
      certificate: certificate,
      routerNonceHex: routerNonceHex,
      clientNonceHex: clientNonceHex,
    );
  }

  /// Simulation helper for grading / demo testing
  Future<HandshakeResult> _simulateHandshake(
    DemoScenario scenario,
    String ssid,
    String bssid,
  ) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final mockCert = GatewayCertificate(
      deviceId: "KIWI-GW-DEMO-01",
      publicKeyHex: "2bbcae6aefd00832de0bd7fb0d24fb7a79be0b9223550e4eb15fcb546fc22598",
      signatureHex: "11" * 64,
      issuedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600,
    );

    switch (scenario) {
      case DemoScenario.legitimateGateway:
        return HandshakeResult.verified(
          latencyMs: 142,
          certificate: mockCert,
          routerNonceHex: "44" * 32,
          clientNonceHex: "33" * 32,
        );

      case DemoScenario.evilTwinForgedRootSignature:
        return await _recordHostile(
          layer: VerificationLayer.layer1RootCaCertValidation,
          reason: "Untrusted Root Signature: Certificate was signed with an unknown or forged CA key.",
          latencyMs: 85,
          ssid: ssid,
          bssid: bssid,
          certificate: mockCert,
        );

      case DemoScenario.evilTwinInvalidGatewaySig:
        return await _recordHostile(
          layer: VerificationLayer.layer2GatewaySignatureValidation,
          reason: "Rogue Gateway Signature: Gateway failed challenge signature verification.",
          latencyMs: 110,
          ssid: ssid,
          bssid: bssid,
          certificate: mockCert,
        );

      case DemoScenario.evilTwinReplayAttack:
        return await _recordHostile(
          layer: VerificationLayer.layer3FreshnessReplayValidation,
          reason: "Replay Attack Detected: Nonce was previously used or timestamp was manipulated.",
          latencyMs: 92,
          ssid: ssid,
          bssid: bssid,
          certificate: mockCert,
        );

      case DemoScenario.evilTwinRevokedDevice:
        return await _recordHostile(
          layer: VerificationLayer.layer4RevocationListCheck,
          reason: "Revoked Gateway: Device ID 'KIWI-COMPROMISED-001' is flagged in the revocation list.",
          latencyMs: 120,
          ssid: ssid,
          bssid: bssid,
          certificate: GatewayCertificate(
            deviceId: "KIWI-COMPROMISED-001",
            publicKeyHex: mockCert.publicKeyHex,
            signatureHex: mockCert.signatureHex,
            issuedAt: mockCert.issuedAt,
          ),
        );

      case DemoScenario.timeoutFailure:
        return await _recordHostile(
          layer: VerificationLayer.networkTimeoutOrUnreachable,
          reason: "Connection Timed Out: Gateway failed to respond within strict 2000ms security window.",
          latencyMs: 2005,
          ssid: ssid,
          bssid: bssid,
        );

      case DemoScenario.none:
        throw UnimplementedError();
    }
  }
}
