# neokeys

Get characters from a terminal keyboard, similar to `getch` in [curses][0] library.

[![On pub.dev][pub_img]][pub_url]
[![Code coverage][cov_img]][cov_url]
[![Github action status][gha_img]][gha_url]
[![Dartdocs][doc_img]][doc_url]

[![Style guide][sty_img]][sty_url]

[pub_url]: https://pub.dartlang.org/packages/neokeys
[pub_img]: https://img.shields.io/pub/v/neokeys.svg
[gha_url]: https://github.com/neo-dart/neokeys/actions
[gha_img]: https://github.com/neo-dart/neokeys/workflows/Dart/badge.svg
[cov_url]: https://codecov.io/gh/neo-dart/neokeys
[cov_img]: https://codecov.io/gh/neo-dart/neokeys/branch/main/graph/badge.svg
[doc_url]: https://www.dartdocs.org/documentation/neokeys/latest
[doc_img]: https://img.shields.io/badge/Documentation-neokeys-blue.svg
[sty_url]: https://pub.dev/packages/neodart
[sty_img]: https://img.shields.io/badge/style-neodart-9cf.svg

## Purpose

Dart's terminal support is fairly basic, with a [`Stdin`][1] class and
little more, particularly for _input_ (see [`examples/without_neokeys.dart`][2])

As a result creating something representing a rendering loop quite difficult:

```dart
import 'dart:io';

void main() {
  stdin
    ..echoMode = false
    ..lineMode = false;
  _exampleOfWaitingForQ();
}

void _exampleOfWaitingForQ() async {
  const qKey = 0x71;

  final buffer = <List<int>>[];

  bool isHit(int keyCode) {
    return buffer.any((keys) => keys.length == 1 && keys.first == keyCode);
  }

  stdin.listen((keys) {
    if (completer.isCompleted) {
      return;
    }

    buffer.add(keys);
  });

  const frames = Duration(milliseconds: 1000 ~/ 30);
  await for (final _ in Stream<void>.periodic(frames)) {
    if (isHit(qKey)) {
      stdin
        ..echoMode = true
        ..lineMode = true;
      return;
    }
  }
}
```

[0]: https://linux.die.net/man/3/getch
[1]: https://api.dart.dev/stable/2.17.1/dart-io/Stdin-class.html
[2]: examples/without_neokeys.dart

## Usage

The same code as above in [_purpose_](#purpose), using `neokeys`:

```dart
import 'dart:io';

import 'package:neokeys/neokeys.dart';

void main() {
  stdin
    ..echoMode = false
    ..lineMode = false;
  _exampleOfWaitingForQ();
}

void _exampleOfWaitingForQ() async {
  // Creates a smart listener with buffering.
  final input = stdin.neokeys();

  const frames = Duration(milliseconds: 1000 ~/ 30);
  await for (final _ in Stream<void>.periodic(frames)) {
    // Fully typed API with convenience methods.
    if (input.isPressed(Key.q)) {
      stdin
        ..echoMode = true
        ..lineMode = true;
      return;
    }
  }
}
```

## Contributing

**This package welcomes [new issues][issues] and [pull requests][fork].**

[issues]: https://github.com/neo-dart/neokeys/issues/new
[fork]: https://github.com/neo-dart/neokeys/fork

Changes or requests that do not match the following criteria will be rejected:

1. Common decency as described by the [Contributor Covenant][code-of-conduct].
2. Making this library brittle.
3. Adding platform-specific functionality.
4. A somewhat arbitrary bar of "complexity", everything should be _easy to use_.

[code-of-conduct]: https://www.contributor-covenant.org/version/1/4/code-of-conduct/
