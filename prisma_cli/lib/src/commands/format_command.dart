import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart';

import 'package:prisma_shared/prisma_shared.dart';
import '../engine_downloader/binary_engine_manger.dart';
import '../engine_downloader/binary_engine_platform.dart';
import '../engine_downloader/binary_engine_type.dart';
import '../utils/ansi_progress.dart';

class FormatCommand extends Command<int> {
  FormatCommand() {
    argParser.addOption(
      'schema',
      help: 'Schema file path.',
      valueHelp: 'path',
      defaultsTo: 'prisma/schema.prisma',
    );
  }

  @override
  String get description => 'Format a Prisma schema.';

  @override
  String get name => 'format';

  /// Schema file.
  File get schema => File(argResults?['schema']);

  @override
  Future<int> run() async {
    if (!schema.existsSync()) {
      stderr.writeln('Missing schema file path.');
      return 1;
    }

    final manger = BinaryEngineManger(
      engineType: BinaryEngineType.format,
      platform: BinaryEnginePlatform.current,
      version: engineVersion,
    );

    // ensure exist (get a copy from cache if exist or downloading it)
    final path = await manger.ensure(_onDownload);

    // Create format progress.
    final AnsiProgress formatProgress =
        AnsiProgress('Formatting prisma schema...');

    // Run format engine binary.
    final ProcessResult result = await Process.run(
      path,
      ['format', '-i', schema.path],
      environment: configure.environment,
    );

    // If format engine binary failed, print error message.
    if (result.exitCode != 0) {
      stderr.writeln(result.stderr ?? result.stdout);
      return result.exitCode;
    }

    // Write formatted schema string to schema file.
    await schema.writeAsString(result.stdout);

    // Cancel format progress.
    formatProgress.cancel(
      overrideMessage: '${relative(schema.path)} formatted successfully.',
      showTime: false,
    );

    return result.exitCode;
  }

  /// Called when download is started.
  void _onDownload(Future<void> done) async {
    final AnsiProgress progress = AnsiProgress('Downloading format engine...');

    // Await download done.
    await done;

    // Cancel progress.
    progress.cancel(
      showTime: true,
      overrideMessage: 'Prisma format engine downloaded.',
    );
  }
}
