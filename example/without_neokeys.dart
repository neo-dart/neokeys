import 'dart:async';
import 'dart:io';

/// Run as `dart example/without_neokeys.dart N`.
///
/// 1. Reading from the keyboard synchronously
/// 2. Reading from the keyboard asynchronously
/// 3. Reading from the keyboard asynchronously with an "is hit"-like API
///
/// It *mostly* works, with caveats.
void main(List<String> args) async {
  var wasError = false;
  stdin
    ..echoMode = false
    ..lineMode = false;
  final program = args.length == 1 ? args.first : null;
  switch (program) {
    case '1':
      _readKeyboardSync();
      break;
    case '2':
      await _readKeyboardAsync();
      break;
    case '3':
      await _readKeyboardAsyncWithKeyHitLoop();
      break;
    default:
      stderr.writeln('Include a program parameter, i.e. 1 2 or 3');
      stderr.writeln('1 = readKeyboardSync');
      stderr.writeln('2 = readKeyboardAsync');
      stderr.writeln('3 = readKeyboardAsyncWithKeyHitLoop');
      wasError = true;
      break;
  }
  stdin
    ..echoMode = true
    ..lineMode = true;
  if (wasError) {
    exit(1);
  }
}

// Key code for `Q`.
const _qKey = 0x71;

String _debugKeyCode(int keyCode) {
  return '0x${keyCode.toRadixString(16).toUpperCase()} ($keyCode)';
}

/// It is super easy to read a single character code from [stdin].
///
/// What's hard:
///
/// - What if I want to read non-standard codes such as control keys?
/// - What if I *don't* want to synchronously block the entire program?
void _readKeyboardSync() {
  stdout.writeln('Press any (well, mostly any) key to quit:');

  final c = stdin.readByteSync();
  stdout.writeln('readByteSync(): ${_debugKeyCode(c)}');
}

/// It is super easy to read multiple character codes as a stream from [stdin].
///
/// What's hard:
///
/// - What if I build a rendering loop and want to process at certain time?
Future<void> _readKeyboardAsync() async {
  stdout.writeln('Press any key or key combination, or Q to quit');

  await for (final keys in stdin) {
    if (keys.length == 1 && keys.first == _qKey) {
      return;
    }

    final codes = keys.map(_debugKeyCode).toList();
    stdout.writeln('await for (... stdin): $codes');
  }
}

/// ... it's much more complicated to buffer keyboard reads until checked.
///
/// So, this is more or less the reason to use neokeys!
Future<void> _readKeyboardAsyncWithKeyHitLoop() async {
  late final StreamSubscription<void> read;
  final completer = Completer<void>();
  final buffer = <List<int>>[];

  void quit() {
    if (completer.isCompleted) {
      return;
    }
    read.cancel();
    completer.complete();
  }

  // This works... but what if you wanted to store timestamps too in order to
  // "detect" more accurately long a key was pressed? Do you just keep adding
  // and adding code?
  read = stdin.listen((keys) {
    if (completer.isCompleted) {
      return;
    }

    if (keys.length == 1 && keys.first == _qKey) {
      quit();
    }

    buffer.add(keys);
  });

  stdout.writeln('Press WASD to move, Q to quit');

  const aKey = 0x61;
  const dKey = 0x64;
  const sKey = 0x73;
  const wKey = 0x77;

  bool isHit(int keyCode) {
    return buffer.any((keys) => keys.length == 1 && keys.first == keyCode);
  }

  var xDirection = 0;
  var yDirection = 0;

  // This is not terribly efficient, but that's not the point.
  void processInput() {
    if (isHit(aKey)) {
      xDirection--;
    }
    if (isHit(dKey)) {
      xDirection++;
    }
    if (isHit(sKey)) {
      yDirection++;
    }
    if (isHit(wKey)) {
      yDirection--;
    }
    if (!completer.isCompleted && isHit(_qKey)) {
      quit();
    }
    if (xDirection > 1) {
      xDirection = 1;
    } else if (xDirection < -1) {
      xDirection = -1;
    }
    if (yDirection > 1) {
      yDirection = 1;
    } else if (yDirection < -1) {
      yDirection = -1;
    }
    buffer.clear();
  }

  var x = 50;
  var y = 50;

  void updateState() {
    x += xDirection;
    y += yDirection;

    if (x < 0) {
      x = 0;
    } else if (x > 100) {
      x = 100;
    }

    if (y < 0) {
      y = 0;
    } else if (y > 100) {
      y = 100;
    }
  }

  const frames = Duration(milliseconds: 1000 ~/ 30);

  // ignore: no_leading_underscores_for_local_identifiers
  await for (final _ in Stream<void>.periodic(frames)) {
    xDirection = yDirection = 0;

    processInput();
    updateState();

    if (xDirection != 0 || yDirection != 0) {
      stdout.writeln('You are standing at ($x, $y).');
    }

    if (completer.isCompleted) {
      return;
    }
  }

  await completer.future;
}
