import 'dart:io';

class Terminal {
  static const reset  = '\x1B[0m';
  static const bold   = '\x1B[1m';
  static const dim    = '\x1B[2m';
  static const cyan   = '\x1B[96m';
  static const green  = '\x1B[92m';
  static const white  = '\x1B[97m';
  static const red    = '\x1B[91m';
  static const yellow = '\x1B[93m';

  static void drawBar(int pct, String label) {
    final filled = (pct * 36 / 100).floor();
    final empty  = 36 - filled;
    final bar    = '#' * filled + '-' * empty;
    stdout.write('\r  $cyan[$bar]$reset $bold${white}$pct%$reset  $dim$label$reset          ');
  }

  static void writeln([String msg = '']) => stdout.writeln(msg);
  static void write(String msg)          => stdout.write(msg);
}
