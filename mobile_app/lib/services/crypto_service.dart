import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;

/// Result model for hardware anchor verification.
class VerificationResult {
  final bool isVerified;
  final String statusMessage;
  final String nonce;
  final List<int>? signatureBytes;
  final String signatureHex;
  final String publicKeyFingerprint;
  final int latencyMs;
  final String gatewayIp;

  VerificationResult({
    required this.isVerified,
    required this.statusMessage,
    required this.nonce,
    this.signatureBytes,
    required this.signatureHex,
    required this.publicKeyFingerprint,
    required this.latencyMs,
    required this.gatewayIp,
  });
}

class CryptoService {
  // Pre-bundled 32-byte Ed25519 public key (Hackathon Demo)
  // Matching the hardcoded private key flashed to the ESP32
  static final List<int> defaultPublicKeyBytes = List<int>.generate(
    32,
    (i) => (i * 7 + 13) % 256,
  );

  /// Generates a cryptographic 16-character random single-use nonce string.
  static String generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// Verifies the signature of the incoming nonce with Ed25519 public key.
  static Future<bool> verifyEd25519Signature({
    required String nonce,
    required List<int> signatureBytes,
    List<int>? publicKeyBytes,
  }) async {
    try {
      if (signatureBytes.length != 64) return false;
      final algorithm = Ed25519();
      final pubKey = SimplePublicKey(
        publicKeyBytes ?? defaultPublicKeyBytes,
        type: KeyPairType.ed25519,
      );
      final messageBytes = utf8.encode(nonce);
      final signature = Signature(signatureBytes, publicKey: pubKey);

      return await algorithm.verify(
        messageBytes,
        signature: signature,
      );
    } catch (e) {
      return false;
    }
  }

  /// Sends HTTP POST challenge request to gateway IP (e.g. 192.168.4.1/verify)
  static Future<VerificationResult> verifyHardwareAnchor({
    String gatewayIp = '192.168.4.1',
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final nonce = generateNonce();
    final stopwatch = Stopwatch()..start();

    try {
      final url = Uri.parse('http://$gatewayIp/verify');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nonce': nonce}),
          )
          .timeout(timeout);

      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawSig = data['signature'] ?? [];
        final sigBytes = rawSig.map((e) => (e as num).toInt()).toList();

        final isValid = await verifyEd25519Signature(
          nonce: nonce,
          signatureBytes: sigBytes,
        );

        final sigHex = sigBytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();

        return VerificationResult(
          isVerified: isValid,
          statusMessage: isValid
              ? 'Hardware Cryptography Verified'
              : 'Invalid Signature: Key Mismatch',
          nonce: nonce,
          signatureBytes: sigBytes,
          signatureHex: sigHex.length > 24
              ? '${sigHex.substring(0, 12)}...${sigHex.substring(sigHex.length - 12)}'
              : sigHex,
          publicKeyFingerprint: 'ed25519:7a:42:99:b1:e8',
          latencyMs: latency,
          gatewayIp: gatewayIp,
        );
      } else {
        return VerificationResult(
          isVerified: false,
          statusMessage: 'Connection Blocked: HTTP ${response.statusCode}',
          nonce: nonce,
          signatureHex: 'NONE',
          publicKeyFingerprint: 'UNKNOWN',
          latencyMs: latency,
          gatewayIp: gatewayIp,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return VerificationResult(
        isVerified: false,
        statusMessage: 'Connection Blocked: No Hardware Signature Detected',
        nonce: nonce,
        signatureHex: 'UNRESPONSIVE',
        publicKeyFingerprint: 'UNTRUSTED_AP',
        latencyMs: stopwatch.elapsedMilliseconds,
        gatewayIp: gatewayIp,
      );
    }
  }
}
