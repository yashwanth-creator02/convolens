import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../models/search_filters.dart';
import '../widgets/call_card.dart';

class SearchScreen extends StatefulWidget {
  final AppDatabase db;
  final String? initialContactQuery;

  const SearchScreen({super.key, required this.db, this.initialContactQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _titleController = GlassLargeTitleController();
  SearchFilters _filters = const SearchFilters();
  Timer? _debounce;

  final _contactController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagController = TextEditingController();

  void _onFieldChanged(SearchFilters Function(SearchFilters) update) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _filters = update(_filters);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _contactController.dispose();
    _noteController.dispose();
    _tagController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialContactQuery != null) {
      _contactController.text = widget.initialContactQuery!;
      _filters = _filters.copyWith(contactQuery: widget.initialContactQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Search'),
        largeTitleController: _titleController,
      ),
      body: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: _titleController.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
            ),
            GlassLargeTitle(text: 'Search', controller: _titleController),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact name or number',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          _onFieldChanged((f) => f.copyWith(contactQuery: v)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Search notes',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          _onFieldChanged((f) => f.copyWith(noteQuery: v)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Search tags',
                        prefixIcon: Icon(Icons.label_outline),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          _onFieldChanged((f) => f.copyWith(tagQuery: v)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Has Attachment'),
                          selected: _filters.hasAttachment,
                          onSelected: (v) => setState(() {
                            _filters = _filters.copyWith(hasAttachment: v);
                          }),
                        ),
                        FilterChip(
                          label: const Text('Has Reminder'),
                          selected: _filters.hasReminder,
                          onSelected: (v) => setState(() {
                            _filters = _filters.copyWith(hasReminder: v);
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            _filters.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Text('Start typing or pick a filter to search.'),
                    ),
                  )
                : StreamBuilder<List<Call>>(
                    stream: widget.db.searchCalls(
                      contactQuery: _filters.contactQuery,
                      noteQuery: _filters.noteQuery,
                      tagQuery: _filters.tagQuery,
                      hasAttachment: _filters.hasAttachment,
                      hasReminder: _filters.hasReminder,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final results = snapshot.data!;
                      if (results.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(child: Text('No matching calls.')),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              CallCard(call: results[index], db: widget.db),
                          childCount: results.length,
                        ),
                      );
                    },
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}
