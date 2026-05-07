import 'dart:async';
import 'dart:io';
import 'terminal.dart';

class BuildStep {
  final int pctStart;
  final int pctEnd;
  final String label;
  final String midLabel;
  final String command;

  const BuildStep({
    required this.pctStart,
    required this.pctEnd,
    required this.label,
    required this.midLabel,
    required this.command,
  });
}

class Builder {
  final String projectDir;

  Builder(this.projectDir);

  Future<void> runStep(BuildStep step) async {
    final pctMid = step.pctStart + ((step.pctEnd - step.pctStart) * 0.6).floor();
    var cur = step.pctStart;
    var ticks = 0;

    final parts   = step.command.split(' ');
    final process = await Process.start(
      parts.first,
      parts.skip(1).toList(),
      workingDirectory: projectDir,
      runInShell: true,
    );

    // Collect output silently
    final outBuf = StringBuffer();
    final errBuf = StringBuffer();
    process.stdout.transform(SystemEncoding().decoder).listen((d) => outBuf.write(d));
    process.stderr.transform(SystemEncoding().decoder).listen((d) => errBuf.write(d));

    // Animate progress while process runs
    final timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      final label = cur >= pctMid ? step.midLabel : step.label;
      if (cur >= pctMid) {
        if (ticks % 5 == 0 && cur < step.pctEnd - 1) cur++;
      } else {
        if (ticks % 2 == 0 && cur < pctMid) cur++;
      }
      Terminal.drawBar(cur, label);
      ticks++;
    });

    final exitCode = await process.exitCode;
    timer.cancel();

    final combined = outBuf.toString() + errBuf.toString();

    if (exitCode != 0 || combined.toLowerCase().contains('build failed')) {
      Terminal.writeln();
      Terminal.writeln();
      Terminal.writeln('  ${Terminal.red}${Terminal.bold}[ERROR] ${step.label}${Terminal.reset}');
      final errLines = combined.split('\n').where((l) => l.trim().isNotEmpty).toList();
      for (final line in errLines.reversed.take(8).toList().reversed) {
        Terminal.writeln('  ${Terminal.dim}${line.trim()}${Terminal.reset}');
      }
      Terminal.writeln();
      exit(1);
    }

    Terminal.drawBar(step.pctEnd, step.label);
  }
}
