import 'dart:io';

class EnvSwitcher {
  static Future<void> apply(String projectDir, String mode) async {
    final envFile = File('$projectDir/.env');
    if (!envFile.existsSync()) {
      stderr.writeln('  [ERROR] .env file not found.');
      exit(1);
    }

    final lines = envFile.readAsLinesSync();
    final map   = <String, String>{};

    for (final line in lines) {
      if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
      final idx = line.indexOf('=');
      if (idx == -1) continue;
      map[line.substring(0, idx).trim()] = line.substring(idx + 1).trim();
    }

    final baseUrl  = mode == 'dev' ? (map['TEST_BASE_URL']  ?? '') : (map['BASE_URL']  ?? '');
    final imageUrl = mode == 'dev' ? (map['TEST_IMAGE_URL'] ?? '') : (map['IMAGE_URL'] ?? '');

    final newLines = lines.map((line) {
      if (RegExp(r'^BASE_URL\s*=').hasMatch(line))  return 'BASE_URL=$baseUrl';
      if (RegExp(r'^IMAGE_URL\s*=').hasMatch(line)) return 'IMAGE_URL=$imageUrl';
      return line;
    }).toList();

    envFile.writeAsStringSync(newLines.join('\n'));
  }
}
