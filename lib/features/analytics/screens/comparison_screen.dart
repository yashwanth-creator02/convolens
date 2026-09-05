import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../models/analytics_summary.dart';
import '../models/comparison_config.dart';
import '../repository/analytics_repository.dart';

class ComparisonScreen extends StatefulWidget {
  final AppDatabase db;
  final List<Contact> deviceContacts;
  final ComparisonConfig config;

  const ComparisonScreen({
    super.key,
    required this.db,
    required this.deviceContacts,
    required this.config,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = AnalyticsRepository(widget.db);

    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Compare'),
        largeTitleController: _titleController,
      ),
      body: StreamBuilder<AnalyticsSummary>(
        stream: repository.watchSummary(
          widget.deviceContacts,
          widget.config.left,
        ),
        builder: (context, leftSnapshot) {
          return StreamBuilder<AnalyticsSummary>(
            stream: repository.watchSummary(
              widget.deviceContacts,
              widget.config.right,
            ),
            builder: (context, rightSnapshot) {
              if (!leftSnapshot.hasData || !rightSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final left = leftSnapshot.data!;
              final right = rightSnapshot.data!;

              return Material(
                type: MaterialType.transparency,
                child: CustomScrollView(
                  controller: _titleController.scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height:
                            MediaQuery.of(context).padding.top + kToolbarHeight,
                      ),
                    ),
                    GlassLargeTitle(
                      text: 'Compare',
                      controller: _titleController,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.config.leftLabel,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                              Expanded(
                                child: Text(
                                  widget.config.rightLabel,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _compareRow(
                            'Total Calls',
                            left.totalCalls,
                            right.totalCalls,
                          ),
                          _compareRow(
                            'Talk Time (min)',
                            (left.totalTalkSeconds / 60).round(),
                            (right.totalTalkSeconds / 60).round(),
                          ),
                          _compareRow(
                            'Contacts',
                            left.totalContacts,
                            right.totalContacts,
                          ),
                          _compareRow(
                            'Missed Rate %',
                            (left.missedCallRate * 100).round(),
                            (right.missedCallRate * 100).round(),
                          ),
                          _compareRow(
                            'Longest Call (s)',
                            left.longestCallSeconds,
                            right.longestCallSeconds,
                          ),
                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _compareRow(String label, int leftValue, int rightValue) {
    final delta = rightValue - leftValue;
    final deltaColor = delta > 0
        ? Colors.green
        : delta < 0
        ? Colors.red
        : Colors.grey;
    final deltaText = delta == 0 ? '—' : (delta > 0 ? '+$delta' : '$delta');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$leftValue',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  deltaText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: deltaColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '$rightValue',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
