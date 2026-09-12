import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/crypto_service.dart';

void main() {
  group('Kiwi Hardware Cryptography Tests', () => {
    test('Generate nonce returns non-empty 16-char string', () {
      final nonce = CryptoService.generateNonce();
      expect(nonce, isNotEmpty);
      expect(nonce.length, greaterThanOrEqualTo(16));
    }),

    test('Verify invalid signature returns false gracefully', () async {
      final nonce = "test_nonce_12345";
      final invalidSig = List<int>.filled(64, 0);
      final isValid = await CryptoService.verifyEd25519Signature(
        nonce: nonce,
        signatureBytes: invalidSig,
      );
      expect(isValid, isFalse);
    }),
  });
}
