import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/call_number_stat.dart';
import 'tables/call_attachments_table.dart';
import 'tables/call_details_table.dart';
import 'tables/call_tags_table.dart';
import 'tables/calls_table.dart';
import 'tables/contact_details_table.dart';
import 'tables/contact_links_table.dart';
import 'tables/contact_tags_table.dart';
import 'tables/profile_fields_table.dart';
import 'tables/profile_meta_table.dart';
import 'tables/settings_table.dart';
import 'tables/tags_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Calls,
    Settings,
    CallDetails,
    Tags,
    CallTags,
    CallAttachments,
    ContactDetails,
    ContactTags,
    ContactLinks,
    ProfileFieldEntries,
    ProfileMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createIndexes(m);
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

        if (from < 8) {
          await m.addColumn(settings, settings.showNotePreview);
          await m.addColumn(settings, settings.showTags);
          await m.addColumn(settings, settings.showReminderIndicator);
          await m.addColumn(settings, settings.showAttachmentCount);
        }

        if (from < 9) {
          await m.createTable(contactDetails);
          await m.createTable(contactTags);
        }

        if (from < 10) {
          await m.createTable(contactLinks);
        }

        if (from < 11) {
          await m.addColumn(contactDetails, contactDetails.colorValue);
          await m.addColumn(contactDetails, contactDetails.isArchived);
          await m.addColumn(contactDetails, contactDetails.ignoreFromAnalytics);
          await m.addColumn(contactDetails, contactDetails.preferredMethod);
          await m.addColumn(contactDetails, contactDetails.bestTimeToCall);
        }

        if (from < 12) {
          await m.createTable(profileFieldEntries);
          await m.createTable(profileMeta);
        }

        if (from < 13) {
          await _createIndexes(m);
        }

        if (from < 14) {
          await m.addColumn(settings, settings.theme);
        }

        if (from < 15) {
          await m.addColumn(settings, settings.lastNotifiedStreak);
          await m.addColumn(settings, settings.lastWeeklySummaryTimestamp);
        }
      },

      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');

        await into(
          settings,
        ).insertOnConflictUpdate(const SettingsCompanion(id: Value(0)));

        await into(
          profileMeta,
        ).insertOnConflictUpdate(const ProfileMetaCompanion(id: Value(0)));

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

  Future<void> _createIndexes(Migrator m) async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_calls_timestamp '
      'ON calls(timestamp)',
    );

    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_calls_number '
      'ON calls(number)',
    );
  }

  // ============================================================
  // GENERIC
  // ============================================================

  Future<List<Map<String, dynamic>>> getRawRows<
    T extends Table,
    D extends DataClass
  >(TableInfo<T, D> table) async {
    final query = table.select();
    final rows = await query.get();

    return rows.map((row) => row.toJson()).toList();
  }

  // ============================================================
  // CALLS
  // ============================================================

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

  Future<bool> hasAnyCalls() async {
    final row = await (selectOnly(
      calls,
    )..addColumns([calls.id.count()])).getSingle();

    final count = row.read(calls.id.count()) ?? 0;

    return count > 0;
  }

  Stream<List<Call>> searchCalls({
    required String contactQuery,
    required String noteQuery,
    required String tagQuery,
    required bool hasAttachment,
    required bool hasReminder,
  }) {
    final selectQuery = select(calls).join([
      leftOuterJoin(callDetails, callDetails.callId.equalsExp(calls.id)),
    ]);

    if (contactQuery.isNotEmpty) {
      final likeQuery = '%$contactQuery%';

      selectQuery.where(
        calls.name.like(likeQuery) | calls.number.like(likeQuery),
      );
    }

    if (noteQuery.isNotEmpty) {
      selectQuery.where(callDetails.note.like('%$noteQuery%'));
    }

    if (hasReminder) {
      selectQuery.where(callDetails.reminderAt.isNotNull());
    }

    if (hasAttachment) {
      selectQuery.where(
        existsQuery(
          selectOnly(callAttachments)
            ..addColumns([callAttachments.id])
            ..where(callAttachments.callId.equalsExp(calls.id)),
        ),
      );
    }

    if (tagQuery.isNotEmpty) {
      selectQuery.where(
        existsQuery(
          selectOnly(
              callTags,
            ).join([innerJoin(tags, tags.id.equalsExp(callTags.tagId))])
            ..addColumns([callTags.callId])
            ..where(
              callTags.callId.equalsExp(calls.id) &
                  tags.name.like('%$tagQuery%'),
            ),
        ),
      );
    }

    selectQuery.orderBy([
      OrderingTerm(expression: calls.timestamp, mode: OrderingMode.desc),
    ]);

    return selectQuery.watch().map(
      (rows) => rows.map((row) => row.readTable(calls)).toList(),
    );
  }

  Stream<List<Call>> watchCallsForNumber(String normalizedNumber) {
    final query = select(calls)
      ..where((c) => c.number.like('%$normalizedNumber'))
      ..orderBy([
        (c) => OrderingTerm(expression: c.timestamp, mode: OrderingMode.desc),
      ]);

    return query.watch();
  }

  // ============================================================
  // SETTINGS
  // ============================================================

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

  Future<int> getLastNotifiedStreak() async {
    final row =
        await (select(settings)..where((s) => s.id.equals(0))).getSingle();
    return row.lastNotifiedStreak;
  }

  Future<void> setLastNotifiedStreak(int streak) async {
    await (update(settings)..where((s) => s.id.equals(0))).write(
      SettingsCompanion(lastNotifiedStreak: Value(streak)),
    );
  }

  Future<DateTime?> getLastWeeklySummaryDate() async {
    final row =
        await (select(settings)..where((s) => s.id.equals(0))).getSingle();
    final ts = row.lastWeeklySummaryTimestamp;
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }

  Future<void> setLastWeeklySummaryDate(DateTime date) async {
    await (update(settings)..where((s) => s.id.equals(0))).write(
      SettingsCompanion(
        lastWeeklySummaryTimestamp: Value(date.millisecondsSinceEpoch),
      ),
    );
  }

  // ============================================================
  // CALL DETAILS / NOTES
  // ============================================================

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

  Future<void> clearAllNotesForContact(String normalizedNumber) async {
    await setContactFields(
      normalizedNumber,
      const ContactDetailsCompanion(generalNote: Value(null)),
    );

    final matchingCalls = await (select(
      calls,
    )..where((c) => c.number.like('%$normalizedNumber'))).get();

    for (final call in matchingCalls) {
      await (update(callDetails)..where((d) => d.callId.equals(call.id))).write(
        const CallDetailsCompanion(note: Value(null)),
      );
    }
  }

  // ============================================================
  // TAGS
  // ============================================================

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

  // ============================================================
  // ATTACHMENTS
  // ============================================================

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

  Stream<int> watchAttachmentCountForCall(int callId) {
    final query = selectOnly(callAttachments)
      ..addColumns([callAttachments.id.count()])
      ..where(callAttachments.callId.equals(callId));

    return query.watchSingle().map(
      (row) => row.read(callAttachments.id.count()) ?? 0,
    );
  }

  // ============================================================
  // CONTACT DETAILS
  // ============================================================

  Stream<ContactDetail?> watchContactDetails(String normalizedNumber) {
    return (select(contactDetails)
          ..where((c) => c.normalizedNumber.equals(normalizedNumber)))
        .watchSingleOrNull();
  }

  Future<void> saveContactNote(String normalizedNumber, String note) async {
    final existing =
        await (select(contactDetails)
              ..where((c) => c.normalizedNumber.equals(normalizedNumber)))
            .getSingleOrNull();

    if (existing == null) {
      await into(contactDetails).insert(
        ContactDetailsCompanion.insert(
          normalizedNumber: normalizedNumber,
          generalNote: Value(note),
        ),
      );
    } else {
      await (update(contactDetails)
            ..where((c) => c.normalizedNumber.equals(normalizedNumber)))
          .write(ContactDetailsCompanion(generalNote: Value(note)));
    }
  }

  Future<void> toggleContactFavorite(
    String normalizedNumber,
    bool isFavorite,
  ) async {
    final existing =
        await (select(contactDetails)
              ..where((c) => c.normalizedNumber.equals(normalizedNumber)))
            .getSingleOrNull();

    if (existing == null) {
      await into(contactDetails).insert(
        ContactDetailsCompanion.insert(
          normalizedNumber: normalizedNumber,
          isFavorite: Value(isFavorite),
        ),
      );
    } else {
      await (update(contactDetails)
            ..where((c) => c.normalizedNumber.equals(normalizedNumber)))
          .write(ContactDetailsCompanion(isFavorite: Value(isFavorite)));
    }
  }

  Future<void> setContactFields(
    String normalizedNumber,
    ContactDetailsCompanion fields,
  ) async {
    final existing =
        await (select(contactDetails)
              ..where((c) => c.normalizedNumber.equals(normalizedNumber)))
            .getSingleOrNull();

    if (existing == null) {
      await into(contactDetails).insert(
        ContactDetailsCompanion.insert(
          normalizedNumber: normalizedNumber,
        ).copyWith(
          colorValue: fields.colorValue,
          isArchived: fields.isArchived,
          ignoreFromAnalytics: fields.ignoreFromAnalytics,
          preferredMethod: fields.preferredMethod,
          bestTimeToCall: fields.bestTimeToCall,
          generalNote: fields.generalNote,
        ),
      );
    } else {
      await (update(contactDetails)
            ..where((c) => c.normalizedNumber.equals(normalizedNumber)))
          .write(fields);
    }
  }

  Stream<Set<String>> watchFavoriteNumbers() {
    final query = select(contactDetails)
      ..where((c) => c.isFavorite.equals(true));

    return query.watch().map(
      (rows) => rows.map((r) => r.normalizedNumber).toSet(),
    );
  }

  // ============================================================
  // CONTACT TAGS
  // ============================================================

  Stream<List<Tag>> watchTagsForContact(String normalizedNumber) {
    final query = select(tags).join([
      innerJoin(contactTags, contactTags.tagId.equalsExp(tags.id)),
    ])..where(contactTags.normalizedNumber.equals(normalizedNumber));

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(tags)).toList(),
    );
  }

  Future<void> addTagToContact(String normalizedNumber, String tagName) async {
    final name = tagName.trim();

    if (name.isEmpty) return;

    final existingTag = await (select(
      tags,
    )..where((t) => t.name.equals(name))).getSingleOrNull();

    final tagId =
        existingTag?.id ??
        await into(tags).insert(TagsCompanion.insert(name: name));

    await into(contactTags).insertOnConflictUpdate(
      ContactTagsCompanion.insert(
        normalizedNumber: normalizedNumber,
        tagId: tagId,
      ),
    );
  }

  Future<void> removeTagFromContact(String normalizedNumber, int tagId) async {
    await (delete(contactTags)..where(
          (t) =>
              t.normalizedNumber.equals(normalizedNumber) &
              t.tagId.equals(tagId),
        ))
        .go();
  }

  // ============================================================
  // CONTACT LINKS
  // ============================================================

  Stream<List<ContactLink>> watchLinksForContact(String normalizedNumber) {
    return (select(
      contactLinks,
    )..where((l) => l.normalizedNumber.equals(normalizedNumber))).watch();
  }

  Future<void> addContactLink(
    String normalizedNumber,
    String platform,
    String url,
  ) async {
    await into(contactLinks).insert(
      ContactLinksCompanion.insert(
        normalizedNumber: normalizedNumber,
        platform: platform,
        url: url,
      ),
    );
  }

  Future<void> updateContactLink(int id, String url) async {
    await (update(contactLinks)..where((l) => l.id.equals(id))).write(
      ContactLinksCompanion(url: Value(url)),
    );
  }

  Future<void> deleteContactLink(int id) async {
    await (delete(contactLinks)..where((l) => l.id.equals(id))).go();
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Stream<Map<String, ProfileFieldEntry>> watchProfileFields() {
    return select(
      profileFieldEntries,
    ).watch().map((rows) => {for (final row in rows) row.key: row});
  }

  Future<void> setProfileFieldValue(String key, String value) async {
    await into(profileFieldEntries).insertOnConflictUpdate(
      ProfileFieldEntriesCompanion.insert(key: key, value: Value(value)),
    );
  }

  Future<void> setProfileFieldShared(String key, bool shared) async {
    final existing = await (select(
      profileFieldEntries,
    )..where((f) => f.key.equals(key))).getSingleOrNull();

    await into(profileFieldEntries).insertOnConflictUpdate(
      ProfileFieldEntriesCompanion.insert(
        key: key,
        value: Value(existing?.value),
        shared: Value(shared),
      ),
    );
  }

  Stream<ProfileMetaData> watchProfileMeta() {
    return (select(profileMeta)..where((m) => m.id.equals(0))).watchSingle();
  }

  Future<void> setProfilePhotoPath(String? path) async {
    await (update(profileMeta)..where((m) => m.id.equals(0))).write(
      ProfileMetaCompanion(photoPath: Value(path)),
    );
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  Future<Map<String, int>> getCallCountsByDay(
    DateTime since, {
    DateTime? until,
    String? contactNumberSuffix,
    int? callType,
  }) async {
    final buffer = StringBuffer('''
      SELECT strftime(
        '%Y-%m-%d',
        timestamp / 1000,
        'unixepoch',
        'localtime'
      ) AS day,
      COUNT(*) AS count
      FROM calls
      WHERE timestamp >= ?
    ''');

    final variables = <Variable>[
      Variable.withInt(since.millisecondsSinceEpoch),
    ];

    if (until != null) {
      buffer.write(' AND timestamp <= ?');
      variables.add(Variable.withInt(until.millisecondsSinceEpoch));
    }

    if (contactNumberSuffix != null) {
      buffer.write(' AND number LIKE ?');
      variables.add(Variable.withString('%$contactNumberSuffix'));
    }

    if (callType != null) {
      buffer.write(' AND type = ?');
      variables.add(Variable.withInt(callType));
    }

    buffer.write(' GROUP BY day');

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls},
    );

    final rows = await query.get();

    return {
      for (final row in rows) row.read<String>('day'): row.read<int>('count'),
    };
  }

  Future<List<CallNumberStat>> getCallStatsByNumber({
    DateTime? since,
    DateTime? until,
    String? contactNumberSuffix,
    int? callType,
    int? tagId,
  }) async {
    final buffer = StringBuffer('''
      SELECT
        number,
        COUNT(*) AS count,
        MAX(timestamp) AS last_timestamp,
        SUM(duration) AS total_duration,
        name
      FROM calls
      WHERE number IS NOT NULL
    ''');

    final variables = <Variable>[];

    if (since != null) {
      buffer.write(' AND timestamp >= ?');
      variables.add(Variable.withInt(since.millisecondsSinceEpoch));
    }

    if (until != null) {
      buffer.write(' AND timestamp <= ?');
      variables.add(Variable.withInt(until.millisecondsSinceEpoch));
    }

    if (contactNumberSuffix != null) {
      buffer.write(' AND number LIKE ?');
      variables.add(Variable.withString('%$contactNumberSuffix'));
    }

    if (callType != null) {
      buffer.write(' AND type = ?');
      variables.add(Variable.withInt(callType));
    }

    if (tagId != null) {
      buffer.write(
        ' AND id IN (SELECT call_id FROM call_tags WHERE tag_id = ?)',
      );
      variables.add(Variable.withInt(tagId));
    }

    buffer.write(' GROUP BY number');

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls, callTags},
    );

    final rows = await query.get();

    return rows.map((row) {
      return CallNumberStat(
        number: row.read<String>('number'),
        count: row.read<int>('count'),
        lastTimestamp: row.read<int>('last_timestamp'),
        totalDuration: row.readNullable<int>('total_duration') ?? 0,
        name: row.readNullable<String>('name'),
      );
    }).toList();
  }

  Future<Map<int, int>> getCallCountsByType({
    DateTime? since,
    DateTime? until,
    String? contactNumberSuffix,
    int? callType,
    int? tagId,
  }) async {
    final buffer = StringBuffer('''
      SELECT type, COUNT(*) AS count
      FROM calls
      WHERE 1 = 1
    ''');

    final variables = <Variable>[];

    if (since != null) {
      buffer.write(' AND timestamp >= ?');
      variables.add(Variable.withInt(since.millisecondsSinceEpoch));
    }

    if (until != null) {
      buffer.write(' AND timestamp <= ?');
      variables.add(Variable.withInt(until.millisecondsSinceEpoch));
    }

    if (contactNumberSuffix != null) {
      buffer.write(' AND number LIKE ?');
      variables.add(Variable.withString('%$contactNumberSuffix'));
    }

    if (callType != null) {
      buffer.write(' AND type = ?');
      variables.add(Variable.withInt(callType));
    }

    if (tagId != null) {
      buffer.write(
        ' AND id IN (SELECT call_id FROM call_tags WHERE tag_id = ?)',
      );
      variables.add(Variable.withInt(tagId));
    }

    buffer.write(' GROUP BY type');

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls, callTags},
    );

    final rows = await query.get();

    return {
      for (final row in rows) row.read<int>('type'): row.read<int>('count'),
    };
  }

  Future<Map<String, int>> getCallCountsByPeriod(
    DateTime since,
    DateTime until,
    String periodFormat, {
    String? contactNumberSuffix,
    int? callType,
    int? tagId,
  }) async {
    final buffer = StringBuffer('''
      SELECT
        strftime(
          '$periodFormat',
          timestamp / 1000,
          'unixepoch',
          'localtime'
        ) AS period,
        COUNT(*) AS count
      FROM calls
      WHERE timestamp >= ?
        AND timestamp <= ?
    ''');

    final variables = <Variable>[
      Variable.withInt(since.millisecondsSinceEpoch),
      Variable.withInt(until.millisecondsSinceEpoch),
    ];

    if (contactNumberSuffix != null) {
      buffer.write(' AND number LIKE ?');
      variables.add(Variable.withString('%$contactNumberSuffix'));
    }

    if (callType != null) {
      buffer.write(' AND type = ?');
      variables.add(Variable.withInt(callType));
    }

    if (tagId != null) {
      buffer.write(
        ' AND id IN (SELECT call_id FROM call_tags WHERE tag_id = ?)',
      );
      variables.add(Variable.withInt(tagId));
    }

    buffer.write(' GROUP BY period');

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls, callTags},
    );

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read<String>('period'): row.read<int>('count'),
    };
  }

  Future<Map<String, int>> getCallCountsByTag({
    DateTime? since,
    DateTime? until,
    String? contactNumberSuffix,
    int? callType,
  }) async {
    final buffer = StringBuffer('''
      SELECT
        tags.name AS tag_name,
        COUNT(*) AS count
      FROM call_tags
      INNER JOIN tags
        ON tags.id = call_tags.tag_id
      INNER JOIN calls
        ON calls.id = call_tags.call_id
      WHERE 1 = 1
    ''');

    final variables = <Variable>[];

    if (since != null) {
      buffer.write(' AND calls.timestamp >= ?');
      variables.add(Variable.withInt(since.millisecondsSinceEpoch));
    }

    if (until != null) {
      buffer.write(' AND calls.timestamp <= ?');
      variables.add(Variable.withInt(until.millisecondsSinceEpoch));
    }

    if (contactNumberSuffix != null) {
      buffer.write(' AND calls.number LIKE ?');
      variables.add(Variable.withString('%$contactNumberSuffix'));
    }

    if (callType != null) {
      buffer.write(' AND calls.type = ?');
      variables.add(Variable.withInt(callType));
    }

    buffer.write('''
      GROUP BY tags.name
      ORDER BY count DESC
    ''');

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls, callTags, tags},
    );

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read<String>('tag_name'): row.read<int>('count'),
    };
  }

  Future<Map<int, int>> getCallCountsByHour({
    DateTime? since,
    DateTime? until,
    String? contactNumberSuffix,
    int? callType,
    int? tagId,
  }) async {
    final buffer = StringBuffer('''
      SELECT
        CAST(
          strftime(
            '%H',
            timestamp / 1000,
            'unixepoch',
            'localtime'
          ) AS INTEGER
        ) AS hour,
        COUNT(*) AS count
      FROM calls
      WHERE 1 = 1
    ''');

    final variables = <Variable>[];

    if (since != null) {
      buffer.write(' AND timestamp >= ?');
      variables.add(Variable.withInt(since.millisecondsSinceEpoch));
    }

    if (until != null) {
      buffer.write(' AND timestamp <= ?');
      variables.add(Variable.withInt(until.millisecondsSinceEpoch));
    }

    if (contactNumberSuffix != null) {
      buffer.write(' AND number LIKE ?');
      variables.add(Variable.withString('%$contactNumberSuffix'));
    }

    if (callType != null) {
      buffer.write(' AND type = ?');
      variables.add(Variable.withInt(callType));
    }

    if (tagId != null) {
      buffer.write(
        ' AND id IN (SELECT call_id FROM call_tags WHERE tag_id = ?)',
      );
      variables.add(Variable.withInt(tagId));
    }

    buffer.write(' GROUP BY hour');

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls, callTags},
    );

    final rows = await query.get();

    return {
      for (final row in rows) row.read<int>('hour'): row.read<int>('count'),
    };
  }

  Future<int> getLongestCallDuration({
    DateTime? since,
    DateTime? until,
    String? contactNumberSuffix,
    int? callType,
    int? tagId,
  }) async {
    final buffer = StringBuffer('''
      SELECT MAX(duration) AS max_duration
      FROM calls
      WHERE 1 = 1
    ''');

    final variables = <Variable>[];

    if (since != null) {
      buffer.write(' AND timestamp >= ?');
      variables.add(Variable.withInt(since.millisecondsSinceEpoch));
    }

    if (until != null) {
      buffer.write(' AND timestamp <= ?');
      variables.add(Variable.withInt(until.millisecondsSinceEpoch));
    }

    if (contactNumberSuffix != null) {
      buffer.write(' AND number LIKE ?');
      variables.add(Variable.withString('%$contactNumberSuffix'));
    }

    if (callType != null) {
      buffer.write(' AND type = ?');
      variables.add(Variable.withInt(callType));
    }

    if (tagId != null) {
      buffer.write(
        ' AND id IN (SELECT call_id FROM call_tags WHERE tag_id = ?)',
      );
      variables.add(Variable.withInt(tagId));
    }

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls, callTags},
    );

    final row = await query.getSingle();

    return row.readNullable<int>('max_duration') ?? 0;
  }

  Future<Map<String, int>> getDurationByPeriod(
    DateTime since,
    DateTime until,
    String periodFormat, {
    String? contactNumberSuffix,
    int? callType,
    int? tagId,
  }) async {
    final buffer = StringBuffer('''
      SELECT
        strftime(
          '$periodFormat',
          timestamp / 1000,
          'unixepoch',
          'localtime'
        ) AS period,
        SUM(duration) AS total_duration
      FROM calls
      WHERE timestamp >= ?
        AND timestamp <= ?
    ''');

    final variables = <Variable>[
      Variable.withInt(since.millisecondsSinceEpoch),
      Variable.withInt(until.millisecondsSinceEpoch),
    ];

    if (contactNumberSuffix != null) {
      buffer.write(' AND number LIKE ?');
      variables.add(Variable.withString('%$contactNumberSuffix'));
    }

    if (callType != null) {
      buffer.write(' AND type = ?');
      variables.add(Variable.withInt(callType));
    }

    if (tagId != null) {
      buffer.write(
        ' AND id IN (SELECT call_id FROM call_tags WHERE tag_id = ?)',
      );
      variables.add(Variable.withInt(tagId));
    }

    buffer.write(' GROUP BY period');

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls, callTags},
    );

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read<String>('period'):
            row.readNullable<int>('total_duration') ?? 0,
    };
  }

  Future<Map<int, int>> getCallCountsByWeekday({
    DateTime? since,
    DateTime? until,
    String? contactNumberSuffix,
    int? callType,
    int? tagId,
  }) async {
    final buffer = StringBuffer('''
      SELECT
        CAST(
          strftime(
            '%w',
            timestamp / 1000,
            'unixepoch',
            'localtime'
          ) AS INTEGER
        ) AS weekday,
        COUNT(*) AS count
      FROM calls
      WHERE 1 = 1
    ''');

    final variables = <Variable>[];

    if (since != null) {
      buffer.write(' AND timestamp >= ?');
      variables.add(Variable.withInt(since.millisecondsSinceEpoch));
    }

    if (until != null) {
      buffer.write(' AND timestamp <= ?');
      variables.add(Variable.withInt(until.millisecondsSinceEpoch));
    }

    if (contactNumberSuffix != null) {
      buffer.write(' AND number LIKE ?');
      variables.add(Variable.withString('%$contactNumberSuffix'));
    }

    if (callType != null) {
      buffer.write(' AND type = ?');
      variables.add(Variable.withInt(callType));
    }

    if (tagId != null) {
      buffer.write(
        ' AND id IN (SELECT call_id FROM call_tags WHERE tag_id = ?)',
      );
      variables.add(Variable.withInt(tagId));
    }

    buffer.write(' GROUP BY weekday');

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls, callTags},
    );

    final rows = await query.get();

    return {
      for (final row in rows) row.read<int>('weekday'): row.read<int>('count'),
    };
  }

  Future<Map<String, dynamic>> getContactCallStats(
    String normalizedNumber, {
    DateTime? since,
    DateTime? until,
    int? callType,
  }) async {
    final buffer = StringBuffer('''
      SELECT
        COUNT(*) AS total,
        SUM(duration) AS total_duration,
        AVG(duration) AS avg_duration,
        MAX(timestamp) AS last_ts,
        SUM(
          CASE WHEN type = 1 THEN 1 ELSE 0 END
        ) AS incoming,
        SUM(
          CASE WHEN type = 2 THEN 1 ELSE 0 END
        ) AS outgoing
      FROM calls
      WHERE number LIKE ?
    ''');

    final variables = <Variable>[Variable.withString('%$normalizedNumber')];

    if (since != null) {
      buffer.write(' AND timestamp >= ?');
      variables.add(Variable.withInt(since.millisecondsSinceEpoch));
    }

    if (until != null) {
      buffer.write(' AND timestamp <= ?');
      variables.add(Variable.withInt(until.millisecondsSinceEpoch));
    }

    if (callType != null) {
      buffer.write(' AND type = ?');
      variables.add(Variable.withInt(callType));
    }

    final query = customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {calls},
    );

    final row = await query.getSingle();

    final avgDuration = row.readNullable<double>('avg_duration') ?? 0.0;

    return {
      'total': row.readNullable<int>('total') ?? 0,
      'totalDuration': row.readNullable<int>('total_duration') ?? 0,
      'avgDuration': avgDuration,
      'incoming': row.readNullable<int>('incoming') ?? 0,
      'outgoing': row.readNullable<int>('outgoing') ?? 0,
      'lastCallAt': row.readNullable<int>('last_ts'),
    };
  }

  Future<int?> getFirstCallTimestamp(String normalizedNumberSuffix) async {
    final query = customSelect(
      'SELECT MIN(timestamp) AS first_ts FROM calls WHERE number LIKE ?',
      variables: [Variable.withString('%$normalizedNumberSuffix')],
      readsFrom: {calls},
    );
    final row = await query.getSingle();
    return row.readNullable<int>('first_ts');
  }
}

// ============================================================
// DATABASE CONNECTION
// ============================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();

    final file = File(p.join(dbFolder.path, 'convolens.sqlite'));

    return NativeDatabase(file);
  });
}
