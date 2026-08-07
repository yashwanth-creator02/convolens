import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart' hide Table;

import '../../../core/database/app_database.dart';

class DatabaseBrowserScreen extends StatefulWidget {
  final AppDatabase db;

  const DatabaseBrowserScreen({super.key, required this.db});

  @override
  State<DatabaseBrowserScreen> createState() => _DatabaseBrowserScreenState();
}

class _DatabaseBrowserScreenState extends State<DatabaseBrowserScreen> {
  late final Map<String, TableInfo<Table, DataClass>> _tables = {
    'Calls': widget.db.calls,
    'Settings': widget.db.settings,
    'CallDetails': widget.db.callDetails,
    'Tags': widget.db.tags,
    'CallTags': widget.db.callTags,
  };

  String? _selectedTable;
  List<Map<String, dynamic>>? _rows;
  bool _loading = false;

  Future<void> _loadTable(String tableName) async {
    setState(() {
      _selectedTable = tableName;
      _loading = true;
      _rows = null;
    });

    final rows = await widget.db.getRawRows(_tables[tableName]!);

    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Browser')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: _tables.keys.map((name) {
                return ChoiceChip(
                  label: Text(name),
                  selected: _selectedTable == name,
                  onSelected: (_) => _loadTable(name),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows == null
                ? const Center(child: Text('Select a table above.'))
                : _rows!.isEmpty
                ? const Center(child: Text('No rows.'))
                : ListView.builder(
                    itemCount: _rows!.length,
                    itemBuilder: (context, index) {
                      final row = _rows![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: row.entries
                                .map(
                                  (entry) => Text(
                                    '${entry.key}: ${entry.value}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
