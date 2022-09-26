import 'dart:async';

import 'package:neokeys/neokeys.dart';
import 'package:test/test.dart';

void main() {
  const q = 0x71;
  const z = 0x7A;

  group('BufferedKeys.sync', () {
    late BufferedKeys keys;
    late List<List<int>> buffer;

    setUp(() {
      keys = BufferedKeys.sync(buffer = []);
    });

    test('should not indicate any key is pressed', () {
      expect(keys.isAnyPressed, isFalse);
    });

    test('should indicate any key is pressed', () {
      buffer.add([q]);

      expect(keys.isAnyPressed, isTrue);
    });

    test('should only indicate a specific key is pressed', () {
      buffer.add([q]);

      expect(keys.isPressed(q), isTrue);
      expect(keys.isPressed(z), isFalse);
    });

    test('should clear the buffer on demand', () {
      buffer.add([q]);
      keys.clear();

      expect(keys.isPressed(q), isFalse);
    });

    test('should clear the buffer when cancelled', () {
      buffer.add([q]);
      keys.cancel();

      expect(keys.isPressed(q), isFalse);
    });

    test('should check for a 2-code character', () {
      buffer.add([1, 2]);

      expect(keys.isPressed(1, 2), isTrue);
    });

    test('should check for a 3-code character', () {
      buffer.add([1, 2, 3]);

      expect(keys.isPressed(1, 2, 3), isTrue);
    });

    test('should check for a 4-code character', () {
      buffer.add([1, 2, 3, 4]);

      expect(keys.isPressed(1, 2, 3, 4), isTrue);
    });

    test('should check for a 5-code character', () {
      buffer.add([1, 2, 3, 4, 5]);

      expect(keys.isPressed(1, 2, 3, 4, 5), isTrue);
    });

    test('should check for a 6-code character', () {
      buffer.add([1, 2, 3, 4, 5, 6]);

      expect(keys.isPressed(1, 2, 3, 4, 5, 6), isTrue);
    });
  });

  group('BufferedKeys.async', () {
    late BufferedKeys keys;
    late StreamController<List<int>> buffer;

    Future<void> pumpEventQueue() => Future(() {});

    setUp(() {
      keys = BufferedKeys.async((buffer = StreamController()).stream);
    });

    test('should not indicate any key is pressed', () {
      expect(keys.isAnyPressed, isFalse);
    });

    test('should indicate any key is pressed', () async {
      buffer.add([q]);
      await pumpEventQueue();

      expect(keys.isAnyPressed, isTrue);
    });

    test('should only indicate a specific key is pressed', () async {
      buffer.add([q]);
      await pumpEventQueue();

      expect(keys.isPressed(q), isTrue);
      expect(keys.isPressed(z), isFalse);
    });

    test('should clear the buffer on demand', () async {
      buffer.add([q]);
      await pumpEventQueue();
      keys.clear();

      expect(keys.isPressed(q), isFalse);
    });

    test('should clear the buffer when cancelled', () async {
      buffer.add([q]);
      await pumpEventQueue();
      keys.cancel();

      expect(keys.isPressed(q), isFalse);
    });

    test('should check for a 2-code character', () async {
      buffer.add([1, 2]);
      await pumpEventQueue();

      expect(keys.isPressed(1, 2), isTrue);
    });

    test('should check for a 3-code character', () async {
      buffer.add([1, 2, 3]);
      await pumpEventQueue();

      expect(keys.isPressed(1, 2, 3), isTrue);
    });
  });
}
