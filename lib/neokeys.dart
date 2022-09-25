/// Get characters from a terminal keyboard, similar to `getch` in [curses][].
///
/// Use [BufferedKeys] to buffer and allow synchronous recall of pressed keys.
///
/// [curses]: https://linux.die.net/man/3/getch
library neokeys;

import 'dart:async';

import 'package:meta/meta.dart';

/// A minimal buffer interface for _synchronously_ reading the state of keys.
///
/// When reading from the terminal (i.e. with `dart:io`), you have two choices:
/// 1. Block the program until a key is pressed (`stdin.readByteSync()`).
/// 2. Capture event codes as they are received (using `stdin` as a [Stream]).
///
/// [BufferedKeys] provides a synchronous API for the _state_ of key codes:
/// ```
/// void processInput(BufferedKeys keys) {
///   if (keys.isPressed(/* q * / 0x71)) {
///     print('"q" was pressed');
///   }
/// }
/// ```
///
/// The simplest implementation uses `dart:io` and [BufferedKeys.async], i.e.:
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   const frames = Duration(milliseconds: 1000 ~/ 30);
///   final keys = BufferedKeys.from(stdio);
///
///   stdout.writeln('Press any key to quit');
///
///   await for (final _ in Stream.periodic(frames)) {
///     if (keys.isAnyPressed) {
///       return;
///     }
///   }
/// }
/// ```
///
/// ## Lifecycle
///
/// This class on most platforms is **stateful**, and care should be taken to
/// avoid memory leaks or hangs in applications. In general, only two methods
/// ([clear] and [cancel]) must be used:
///
/// 1. After processing keys (i.e. after using [isPressed]), call [clear].
/// 2. When reading of keys is no longer necessary, call [cancel].
///
/// ```dart
/// // An example of a game loop lifecycle.
/// class GameLoop {
///   BufferedKeys keys;
///
///   /* ... */
///
///   void terminateLoop() {
///     keys.cancel();
///   }
///
///   void processInput() {
///     if (keys.isAnyPressed) {
///       stdout.writeln('Key pressed!');
///     }
///     keys.clear();
///   }
///
///   /* ... */
/// }
/// ```
abstract class BufferedKeys {
  /// @nodoc
  const BufferedKeys();

  /// Creates a buffer of key codes from a stream of key codes being received.
  ///
  /// This is a reasonable default from listening to `stdin`:
  /// ```dart
  /// import 'dart:io';
  ///
  /// void main() {
  ///   final keys = BufferedKeys.async(stdin);
  ///
  ///   /* ... */
  /// }
  /// ```
  factory BufferedKeys.async(Stream<List<int>> input) = _AsyncBufferedKeys;

  /// Creates a buffer of key codes using a sequence of codes as [input].
  ///
  /// This class is provided mostly for testing or stubbing purposes:
  /// ```dart
  /// void main() {
  ///   // Can be added to (buffer.add) to add codes to the buffer.
  ///   final buffer = <List<int>>[];
  ///   final keys = BufferedKeys.sync(buffer);
  ///
  ///   /* ... */
  /// }
  /// ```
  factory BufferedKeys.sync(List<List<int>> input) = _SyncBufferedKeys;

  /// Cancels the underlying event listeners, if any, for reading keys.
  ///
  /// Implementations that do not require cleanup should still call [clear].
  ///
  /// If using the terminal in raw mode, disable raw mode _before_ cancelling.
  @mustCallSuper
  void cancel() {
    clear();
  }

  /// Clears the buffer.
  ///
  /// This method should be invoked after checking keys using [isPressed] to
  /// clear the buffer between frames, otherwise keys will report being pressed
  /// that have been released and memory will grow indefinitely.
  void clear();

  /// Returns whether the provided key code exists in the buffer.
  ///
  /// May provide up to 3 codes in order to capture control characters:
  /// ```dart
  /// void processInput(BufferedKeys keys) {
  ///   final upArrowPressed = keys.isPressed(0x1B, 0x5B, 0x41);
  ///   // ...
  /// }
  /// ```
  bool isPressed(int code1, [int? code2, int? code3]);

  /// Returns whether any key is present in the buffer.
  ///
  /// Exactly what keys are considered "any" is platform specific.
  bool get isAnyPressed;
}

class _SyncBufferedKeys extends BufferedKeys {
  /// Buffered keycodes.
  final List<List<int>> _buffer;

  _SyncBufferedKeys(this._buffer);

  @override
  void clear() {
    _buffer.clear();
  }

  @override
  bool isPressed(int code1, [int? code2, int? code3]) {
    for (final keys in _buffer) {
      switch (keys.length) {
        case 1:
          return code2 == null && code1 == keys[0];
        case 2:
          return code3 == null && code1 == keys[0] && code2 == keys[1];
        case 3:
          return code3 == keys[2] && code2 == keys[1] && code1 == keys[0];
      }
    }
    return false;
  }

  @override
  bool get isAnyPressed => _buffer.isNotEmpty;
}

class _AsyncBufferedKeys extends _SyncBufferedKeys {
  /// Subscription to the underlying stream.
  final StreamSubscription<void> _subscription;

  factory _AsyncBufferedKeys(Stream<List<int>> keys) {
    final buffer = <List<int>>[];
    return _AsyncBufferedKeys._(buffer, keys.listen(buffer.add));
  }

  _AsyncBufferedKeys._(
    List<List<int>> buffer,
    this._subscription,
  ) : super(buffer);

  @override
  void cancel() {
    _subscription.cancel();
    super.cancel();
  }
}
