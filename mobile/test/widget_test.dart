// Basic widget smoke test for KIWI Wi-Fi Safety Companion

import 'package:flutter_test/flutter_test.dart';
import 'package:kiwi_mobile/main.dart';
import 'package:kiwi_mobile/services/crypto_service.dart';
import 'package:kiwi_mobile/services/network_service.dart';
import 'package:kiwi_mobile/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('KiwiApp loads and renders scanner screen header', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final cryptoService = CryptoService();
    final storageService = StorageService(cryptoService, inMemorySecureStorage: {});
    await storageService.init();
    final networkService = NetworkService(cryptoService, storageService);

    await tester.pumpWidget(KiwiApp(networkService: networkService, autoScan: false));
    await tester.pump();

    expect(find.text('KIWI'), findsOneWidget);
    expect(find.text('Wi-Fi Safety Companion'), findsOneWidget);
  });
}
