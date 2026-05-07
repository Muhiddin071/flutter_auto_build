import 'dart:io';
import 'package:args/args.dart';
import 'terminal.dart';
import 'builder.dart';
import 'env_switcher.dart';

Future<void> run(List<String> args) async {
  final parser = ArgParser()
    ..addOption('target',
        abbr: 't',
        allowed: ['apk', 'aab', 'both'],
        defaultsTo: 'apk',
        help: 'Build target: apk, aab, or both')
    ..addOption('env',
        abbr: 'e',
        allowed: ['dev', 'prod', ''],
        defaultsTo: '',
        help: 'Environment: dev or prod')
    ..addFlag('help', abbr: 'h', negatable: false);

  // Positional args support: flutter_auto_build apk dev
  String target = 'apk';
  String env    = '';

  final positional = args.where((a) => !a.startsWith('-')).toList();
  final flagArgs   = args.where((a) => a.startsWith('-')).toList();

  if (positional.isNotEmpty) {
    final t = positional[0].toLowerCase();
    if (['apk', 'aab', 'both'].contains(t)) target = t;
  }
  if (positional.length > 1) {
    final e = positional[1].toLowerCase();
    if (['dev', 'prod'].contains(e)) env = e;
  }

  // Also support --flag style
  try {
    final parsed = parser.parse(flagArgs);
    if (parsed['help'] == true) {
      _printHelp();
      return;
    }
    if (flagArgs.any((a) => a.startsWith('--target') || a.startsWith('-t'))) {
      target = parsed['target'] as String;
    }
    if (flagArgs.any((a) => a.startsWith('--env') || a.startsWith('-e'))) {
      env = parsed['env'] as String;
    }
  } catch (_) {}

  final projectDir = Directory.current.path;

  if (!File('$projectDir/pubspec.yaml').existsSync()) {
    Terminal.writeln('  ${Terminal.red}[ERROR]${Terminal.reset} pubspec.yaml not found.');
    exit(1);
  }

  // Read project name from pubspec.yaml
  final pubspecLines = File('$projectDir/pubspec.yaml').readAsLinesSync();
  final nameLine     = pubspecLines.firstWhere(
    (l) => l.trimLeft().startsWith('name:'),
    orElse: () => 'name: unknown',
  );
  final projectName = nameLine.replaceFirst(RegExp(r'^name:\s*'), '').trim();

  // Header
  Terminal.writeln();
  final envTag = env.isNotEmpty
      ? '  ${env == 'dev' ? Terminal.yellow : Terminal.green}[$env]${Terminal.reset}'
      : '';
  Terminal.writeln(
    '  ${Terminal.bold}${Terminal.cyan}Flutter Release Builder${Terminal.reset}'
    '  ${Terminal.dim}-> ${target.toUpperCase()}$envTag${Terminal.reset}',
  );
  Terminal.writeln('  ${Terminal.dim}$projectDir${Terminal.reset}');
  Terminal.writeln('  ${Terminal.dim}$projectName${Terminal.reset}');
  Terminal.writeln();

  // Apply .env if needed
  if (env == 'dev' || env == 'prod') {
    final envLabel = env == 'dev'
        ? '${Terminal.yellow}DEV${Terminal.reset}'
        : '${Terminal.green}PROD${Terminal.reset}';
    Terminal.writeln('  ${Terminal.dim}Updating .env...${Terminal.reset}  $envLabel');
    Terminal.writeln();
    await EnvSwitcher.apply(projectDir, env);
  }

  final builder = Builder(projectDir);

  // Steps
  await builder.runStep(BuildStep(
    pctStart: 0, pctEnd: 5,
    label: 'flutter clean...',
    midLabel: 'flutter clean...',
    command: 'flutter clean',
  ));

  await builder.runStep(BuildStep(
    pctStart: 5, pctEnd: 15,
    label: 'flutter pub get...',
    midLabel: 'fetching packages...',
    command: 'flutter pub get',
  ));

  if (target == 'apk' || target == 'both') {
    final end = target == 'both' ? 55 : 100;
    await builder.runStep(BuildStep(
      pctStart: 15, pctEnd: end,
      label: 'flutter build apk...',
      midLabel: 'running Gradle build...',
      command: 'flutter build apk --release',
    ));
  }

  if (target == 'aab' || target == 'both') {
    await builder.runStep(BuildStep(
      pctStart: 55, pctEnd: 100,
      label: 'flutter build aab...',
      midLabel: 'running Gradle build...',
      command: 'flutter build appbundle --release',
    ));
  }

  Terminal.drawBar(100, 'Copying files...');
  Terminal.writeln();
  Terminal.writeln();

  // Copy to Desktop/Flutter Releases
  final desktop    = _getDesktopPath();
  final releaseDir = '$desktop/Flutter Releases/$projectName';
  Directory(releaseDir).createSync(recursive: true);

  if (target == 'apk' || target == 'both') {
    final copied = _copyOutput(projectDir, releaseDir, projectName, 'app-release.apk', 'apk', env);
    if (copied != null) {
      final sz = (File(copied).lengthSync() / 1024 / 1024).toStringAsFixed(1);
      Terminal.writeln('  ${Terminal.green}APK${Terminal.reset}  ${Terminal.dim}$copied  ($sz MB)${Terminal.reset}');
    }
  }
  if (target == 'aab' || target == 'both') {
    final copied = _copyOutput(projectDir, releaseDir, projectName, 'app-release.aab', 'aab', env);
    if (copied != null) {
      final sz = (File(copied).lengthSync() / 1024 / 1024).toStringAsFixed(1);
      Terminal.writeln('  ${Terminal.green}AAB${Terminal.reset}  ${Terminal.dim}$copied  ($sz MB)${Terminal.reset}');
    }
  }

  Terminal.writeln();
}

String? _copyOutput(
  String projectDir,
  String releaseDir,
  String projectName,
  String filter,
  String ext,
  String env,
) {
  final buildOut = Directory('$projectDir/build/app/outputs');
  if (!buildOut.existsSync()) return null;

  final files = buildOut
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith(filter))
      .toList();

  if (files.isEmpty) return null;

  final suffix  = env.isNotEmpty ? '_${env}_release' : '_release';
  final dest    = '$releaseDir/${projectName}$suffix.$ext';
  files.first.copySync(dest);
  return dest;
}

String _getDesktopPath() {
  if (Platform.isWindows) {
    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:/Users/User';
    return '$userProfile/Desktop';
  } else if (Platform.isMacOS) {
    return '${Platform.environment['HOME']}/Desktop';
  } else {
    return '${Platform.environment['HOME']}/Desktop';
  }
}

void _printHelp() {
  Terminal.writeln('''
  Flutter Release Builder

  Usage:
    dart run flutter_auto_build <target> [env]

  Target:
    apk    APK build (default)
    aab    App Bundle build
    both   Both APK and AAB

  Env (optional):
    dev    Writes TEST_ URLs to .env
    prod   Writes main URLs to .env
    (blank) Does not change .env

  Examples:
    dart run flutter_auto_build apk
    dart run flutter_auto_build apk dev
    dart run flutter_auto_build both prod
    dart run flutter_auto_build aab
''');
}
