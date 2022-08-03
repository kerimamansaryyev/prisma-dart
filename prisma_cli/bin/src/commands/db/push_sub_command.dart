import 'package:args/command_runner.dart';
import 'package:prisma_cli/prisma_cli.dart';

import '../../logger.dart';

class PushSubCommand extends Command<int> {
  PushSubCommand(this.engine) {
    argParser.addFlag(
      'force-reset',
      help: 'Force a reset of the database before push',
    );
    argParser.addOption(
      'schema',
      help: 'Custom path to your Prisma schema',
      valueHelp: 'path',
    );
  }

  final BinaryEngine engine;

  @override
  String get description =>
      '🙌  Push the state from your Prisma schema to your database';

  @override
  String get name => 'push';

  @override
  Future<int> run() async {
    final Migrate migrate = Migrate(
      engine,
      schema: getSchemaFile(argResults?['schema']),
    );
    await engine.load();

    final progress = logger.progress('Pushing schema...');
    final result = await migrate.push(force: argResults?['force-reset']);

    migrate.stop();
    progress.finish(showTiming: true);

    if (result.error != null) {
      logger.write(result.error!.message);
      return 1;
    }

    logger.write('Schema pushed successfully!');

    return 0;
  }
}