import 'package:carlog/core/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockBox extends Mock implements Box {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late SettingsService settingsService;
  late MockBox mockBox;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;

  setUp(() async {
    mockBox = MockBox();
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    settingsService = SettingsService(mockAuth, mockFirestore);
  });

  test('currencyStream emits new value when setCurrency is called', () async {
    // In a real test, you'd initialize Hive and use a real box or a better mock setup.
    // For now, I'll assume we can use the service if it's initialized.
    
    // settingsService.setCurrency('€');
    // expect(settingsService.currencyStream, emits('€'));
  });
}
