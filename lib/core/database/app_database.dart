import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/calls_table.dart';
import 'tables/settings_table.dart';
import 'tables/call_details_table.dart';
import 'tables/tags_table.dart';
import 'tables/call_tags_table.dart';
import 'tables/call_attachments_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Calls, Settings, CallDetails, Tags, CallTags, CallAttachments],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(settings);
        }
        if (from < 3) {
          await m.createTable(callDetails);
        }
        if (from < 4) {
          await m.createTable(tags);
          await m.createTable(callTags);
        }
        if (from < 5) {
          await m.addColumn(callDetails, callDetails.reminderAt);
        }
        if (from < 6) {
          await m.addColumn(callDetails, callDetails.reminderLabel);
        }
        if (from < 7) {
          await m.createTable(callAttachments);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await into(
          settings,
        ).insertOnConflictUpdate(const SettingsCompanion(id: Value(0)));

        final tagCount = await (selectOnly(tags)..addColumns([tags.id.count()]))
            .getSingle()
            .then((row) => row.read(tags.id.count()) ?? 0);

        if (tagCount == 0) {
          const defaultTags = [
            'Work',
            'Family',
            'Friend',
            'Client',
            'Personal',
          ];
          for (final name in defaultTags) {
            await into(
              tags,
            ).insertOnConflictUpdate(TagsCompanion.insert(name: name));
          }
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRawRows<
    T extends Table,
    D extends DataClass
  >(TableInfo<T, D> table) async {
    final query = table.select();
    final rows = await query.get();
    return rows.map((row) => row.toJson()).toList();
  }

  Stream<List<Call>> watchAllCalls() {
    return (select(calls)..orderBy([
          (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<int?> getLatestTimestamp() async {
    final query = selectOnly(calls)..addColumns([calls.timestamp.max()]);
    final row = await query.getSingleOrNull();
    return row?.read(calls.timestamp.max());
  }

  Stream<Setting> watchSettings() {
    return (select(settings)..where((s) => s.id.equals(0))).watchSingle();
  }

  Future<void> updateSetting(SettingsCompanion updated) {
    return (update(settings)..where((s) => s.id.equals(0))).write(updated);
  }

  Future<bool> getArchiveMode() async {
    final row = await (select(
      settings,
    )..where((s) => s.id.equals(0))).getSingle();
    return row.archiveMode;
  }

  Future<bool> hasAnyCalls() async {
    final row = await (selectOnly(
      calls,
    )..addColumns([calls.id.count()])).getSingle();
    final count = row.read(calls.id.count()) ?? 0;
    return count > 0;
  }

  Stream<CallDetail?> watchDetailsForCall(int callId) {
    return (select(
      callDetails,
    )..where((d) => d.callId.equals(callId))).watchSingleOrNull();
  }

  Future<void> saveNote(int callId, String note) async {
    final existing = await (select(
      callDetails,
    )..where((t) => t.callId.equals(callId))).getSingleOrNull();

    if (existing == null) {
      await into(
        callDetails,
      ).insert(CallDetailsCompanion.insert(callId: callId, note: Value(note)));
    } else {
      await (update(callDetails)..where((t) => t.callId.equals(callId))).write(
        CallDetailsCompanion(note: Value(note)),
      );
    }
  }

  Stream<List<Tag>> watchTagsForCall(int callId) {
    final query = select(tags).join([
      innerJoin(callTags, callTags.tagId.equalsExp(tags.id)),
    ])..where(callTags.callId.equals(callId));

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(tags)).toList(),
    );
  }

  Future<void> addTagToCall(int callId, String tagName) async {
    final normalizedName = tagName.trim();
    if (normalizedName.isEmpty) return;

    final existingTag = await (select(
      tags,
    )..where((t) => t.name.equals(normalizedName))).getSingleOrNull();

    final tagId =
        existingTag?.id ??
        await into(tags).insert(TagsCompanion.insert(name: normalizedName));

    await into(callTags).insertOnConflictUpdate(
      CallTagsCompanion.insert(callId: callId, tagId: tagId),
    );
  }

  Future<void> removeTagFromCall(int callId, int tagId) async {
    await (delete(
      callTags,
    )..where((t) => t.callId.equals(callId) & t.tagId.equals(tagId))).go();
  }

  Future<List<Tag>> getAllTags() {
    return select(tags).get();
  }

  Stream<CallDetail?> watchReminderForCall(int callId) {
    return (select(
      callDetails,
    )..where((d) => d.callId.equals(callId))).watchSingleOrNull();
  }

  Future<void> saveReminder(
    int callId,
    DateTime reminderTime,
    String? label,
  ) async {
    final existing = await (select(
      callDetails,
    )..where((d) => d.callId.equals(callId))).getSingleOrNull();

    if (existing == null) {
      await into(callDetails).insert(
        CallDetailsCompanion.insert(
          callId: callId,
          reminderAt: Value(reminderTime.millisecondsSinceEpoch),
          reminderLabel: Value(label),
        ),
      );
    } else {
      await (update(callDetails)..where((d) => d.callId.equals(callId))).write(
        CallDetailsCompanion(
          reminderAt: Value(reminderTime.millisecondsSinceEpoch),
          reminderLabel: Value(label),
        ),
      );
    }
  }

  Future<void> clearReminder(int callId) async {
    await (update(callDetails)..where((d) => d.callId.equals(callId))).write(
      const CallDetailsCompanion(
        reminderAt: Value(null),
        reminderLabel: Value(null),
      ),
    );
  }

  Stream<List<CallAttachment>> watchAttachmentsForCall(int callId) {
    return (select(
      callAttachments,
    )..where((a) => a.callId.equals(callId))).watch();
  }

  Future<void> addAttachment({
    required int callId,
    required String filePath,
    required String originalFileName,
    required String fileType,
  }) async {
    await into(callAttachments).insert(
      CallAttachmentsCompanion.insert(
        callId: callId,
        filePath: filePath,
        originalFileName: originalFileName,
        fileType: fileType,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> deleteAttachment(int id) async {
    await (delete(callAttachments)..where((a) => a.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'convolens.sqlite'));
    return NativeDatabase(file);
  });
}
