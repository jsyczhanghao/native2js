import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native2js/native2js.dart';

void main() {
  const MethodChannel channel = MethodChannel('native2js');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Native2js.platformVersion, '42');
  });
}
