import 'dart:async';
import 'dart:io';

import 'package:neokeys/neokeys.dart';

/// Run as `dart example/using_neokeys.dart`.
void main() async {
  stdin
    ..echoMode = false
    ..lineMode = false;

  final keys = BufferedKeys.async(stdin);
  stdout.writeln('Press WASD to move, Q to quit');

  const aKey = 0x61;
  const dKey = 0x64;
  const sKey = 0x73;
  const wKey = 0x77;
  const qKey = 0x71;

  var xDirection = 0;
  var yDirection = 0;
  var shouldExit = false;

  void processInput() {
    if (keys.isPressed(aKey)) {
      xDirection--;
    }
    if (keys.isPressed(dKey)) {
      xDirection++;
    }
    if (keys.isPressed(sKey)) {
      yDirection++;
    }
    if (keys.isPressed(wKey)) {
      yDirection--;
    }
    if (keys.isPressed(qKey)) {
      shouldExit = true;
    }

    keys.clear();
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

    if (shouldExit) {
      stdin
        ..echoMode = true
        ..lineMode = true;
      keys.cancel();
      break;
    }
  }
}
