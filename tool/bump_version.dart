import 'dart:io';

/// Simple helper to bump the Flutter `version:` line in pubspec.yaml.
///
/// By default the script increments the build number (the digits after the
/// `+`). Additional flags:
/// * `--bump=major|minor|patch|build` chooses which part to increment.
/// * `--set-name=x.y.z` overrides the semantic version (before the `+`).
/// * `--set-build=<number>` overrides the build number directly.
/// * `--dry-run` prints the new value without writing to disk.
void main(List<String> args) {
  var bumpTarget = 'build';
  String? overrideName;
  int? overrideBuild;
  var dryRun = false;

  for (final arg in args) {
    if (arg == '--help' || arg == '-h') {
      _printUsage();
      return;
    } else if (arg.startsWith('--bump=')) {
      bumpTarget = arg.substring('--bump='.length).toLowerCase();
    } else if (arg.startsWith('--set-name=')) {
      overrideName = arg.substring('--set-name='.length);
    } else if (arg.startsWith('--set-build=')) {
      final parsed = int.tryParse(arg.substring('--set-build='.length));
      if (parsed == null || parsed < 0) {
        stderr.writeln('⚠️  --set-build expects a non-negative integer.');
        exitCode = 64;
        return;
      }
      overrideBuild = parsed;
    } else if (arg == '--dry-run') {
      dryRun = true;
    } else {
      stderr.writeln('⚠️  Unknown argument: $arg');
      _printUsage();
      exitCode = 64;
      return;
    }
  }

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('❌ pubspec.yaml not found. Run from the project root.');
    exitCode = 66;
    return;
  }

  final content = pubspecFile.readAsStringSync();
  final match = RegExp(r'^version:\s*(\S+?)(?:\+(\d+))?\s*$', multiLine: true)
      .firstMatch(content);
  if (match == null) {
    stderr.writeln('❌ Could not find the version line in pubspec.yaml.');
    exitCode = 65;
    return;
  }

  final currentName = match.group(1)!;
  final currentBuild = int.tryParse(match.group(2) ?? '0') ?? 0;

  final updatedName = overrideName ?? _bumpName(currentName, bumpTarget);
  final updatedBuild = overrideBuild ?? _bumpBuild(currentBuild, bumpTarget, overrideName != null);

  if (updatedBuild > 2147483647) {
    stderr.writeln('❌ Calculated build number $updatedBuild exceeds the Android limit (2147483647).');
    exitCode = 65;
    return;
  }

  final newVersionLine = 'version: $updatedName+$updatedBuild';
  final newContent = content.replaceRange(match.start, match.end, newVersionLine);

  if (dryRun) {
    stdout.writeln('ℹ️  pubspec.yaml would be updated to: $newVersionLine');
  } else {
    pubspecFile.writeAsStringSync(newContent);
    stdout.writeln('✅ pubspec.yaml updated to: $newVersionLine');
  }
}

String _bumpName(String current, String target) {
  final nameMatch = RegExp(r'^(\d+)\.(\d+)\.(\d+)(.*)$').firstMatch(current);
  if (nameMatch == null) {
    stderr.writeln('⚠️  Version name "$current" is not in the form x.y.z. Keeping it as-is.');
    return current;
  }

  var major = int.parse(nameMatch.group(1)!);
  var minor = int.parse(nameMatch.group(2)!);
  var patch = int.parse(nameMatch.group(3)!);
  final suffix = nameMatch.group(4) ?? '';

  switch (target) {
    case 'major':
      major += 1;
      minor = 0;
      patch = 0;
      break;
    case 'minor':
      minor += 1;
      patch = 0;
      break;
    case 'patch':
      patch += 1;
      break;
    case 'build':
    default:
      // No change to semantic version when only bumping build.
      break;
  }

  return '$major.$minor.$patch$suffix';
}

int _bumpBuild(int current, String target, bool hasNameOverride) {
  if (hasNameOverride) {
    // When the caller specifies a new semantic version manually we keep the
    // existing build number unless overridden explicitly.
    return current;
  }

  switch (target) {
    case 'major':
    case 'minor':
    case 'patch':
      return 0; // Reset build counter after semantic bumps.
    case 'build':
    default:
      return current + 1;
  }
}

void _printUsage() {
  stdout.writeln('''Usage: dart run tool/bump_version.dart [options]\n\n'
      'Options:\n'
      '  --bump=<part>       Increment part: major, minor, patch, or build (default).\n'
      '  --set-name=x.y.z   Override the semantic version.\n'
      '  --set-build=N      Override the build number.\n'
      '  --dry-run          Show the result without writing.\n'
      '  -h, --help         Display this message.\n''');
}
