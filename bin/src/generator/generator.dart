import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart';

import 'client_builder.dart';
import 'generator_options.dart';
import 'model_delegate_builder.dart';
import 'schema_builder.dart';

final List<String> _ignores = [
  'constant_identifier_names',
  'non_constant_identifier_names',
  'depend_on_referenced_packages',
  'unused_import',
]..sort();

/// Run Dart client generator
Future<void> generator(GeneratorOptions options) async {
  // Get output file.
  final File output = File(options.output);

  final Library library = Library((LibraryBuilder updates) {
    updates.name = 'prisma.client';

    // Add header comment.
    updates.body.add(Code('''\n
part '${basenameWithoutExtension(output.path)}.g.dart';
// GENERATED CODE - DO NOT MODIFY BY HAND
//
// ignore_for_file: ${_ignores.join(', ')}
//
${'//'.padRight(80, '*')}
// This file was generated by Prisma
// GitHub: https://github.com/odroe/prisma-dart
${'//'.padRight(80, '*')} \n
'''));

    // Exports
    updates.directives.add(Directive.export(
      'package:orm/orm.dart',
      show: [
        'Datasource',
        'PrismaNull',
        'PrismaUnion',
        'PrismaClient',
      ]..sort(),
    ));

    // Inport `package:json_annotation/json_annotation.dart`
    // 临时修复👉https://github.com/google/json_serializable.dart/issues/1115
    // 等待 https://github.com/google/json_serializable.dart/pull/1116 并发布新版本
    updates.directives.add(Directive.import(
      'package:json_annotation/json_annotation.dart',
      show: [
        r'$enumDecodeNullable',
        r'$enumDecode',
      ]..sort(),
    ));

    // Build schema.
    SchemaBuilder(options, updates).build();

    // Build model delegates.
    ModelDelegateBuilder(options, updates).build();

    // Build prisma client.
    ClientBuilder(options, updates).build();
  });
  final DartEmitter emitter = DartEmitter.scoped();
  final StringSink sink = library.accept(emitter);
  final DartFormatter formatter = DartFormatter();
  final String formatted = formatter.format(sink.toString());

  // Write to file.
  output.writeAsStringSync(formatted);
}
