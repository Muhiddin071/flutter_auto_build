import 'dart:async';
import 'dart:convert';
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

    final parts = step.command.split(' ');
    Process process;
    try {
      process = await Process.start(
        parts.first,
        parts.skip(1).toList(),
        workingDirectory: projectDir,
        runInShell: true,
      );
    } catch (e) {
      Terminal.writeln();
      Terminal.writeln('  ${Terminal.red}${Terminal.bold}[ERROR] Failed to start command: ${step.command}${Terminal.reset}');
      Terminal.writeln('  ${Terminal.dim}$e${Terminal.reset}');
      exit(1);
    }

    // Close stdin so the process never hangs waiting for user input
    await process.stdin.close();

    // Collect output silently
    final outBuf = StringBuffer();
    final errBuf = StringBuffer();
    var lastLine = '';
    
    process.stdout.transform(utf8.decoder).listen((d) {
      outBuf.write(d);
      final lines = d.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) lastLine = lines.last;
    }, onError: (_) {});
    
    process.stderr.transform(utf8.decoder).listen((d) {
      errBuf.write(d);
      final lines = d.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) lastLine = lines.last;
    }, onError: (_) {});

    final spinner = ['|', '/', '-', '\\'];

    // Animate progress while process runs
    final timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      var label = cur >= pctMid ? step.midLabel : step.label;
      if (ticks > 30 && lastLine.isNotEmpty) {
        // Show actual output if it's taking more than 4.5 seconds
        label = lastLine.length > 30 ? lastLine.substring(0, 30) + '...' : lastLine;
      }
      
      final spin = spinner[ticks % spinner.length];

      if (cur >= pctMid) {
        if (ticks % 5 == 0 && cur < step.pctEnd - 1) cur++;
      } else {
        if (ticks % 2 == 0 && cur < pctMid) cur++;
      }
      Terminal.drawBar(cur, '$label $spin');
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
