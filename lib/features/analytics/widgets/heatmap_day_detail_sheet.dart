import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../contacts/models/contact_summary.dart';
import '../../history/screens/call_details_screen.dart';
import '../../history/utils/call_type_label.dart';
import '../../history/utils/format_call_time.dart';
import '../../history/utils/format_duration.dart';
import '../models/analytics_filters.dart';

class HeatmapDayDetailSheet extends StatefulWidget {
  final DateTime day;
  final int count;
  final AppDatabase db;
  final List<Contact> deviceContacts;
  final AnalyticsFilters filters;
  final void Function(ContactSummary contact)? onContactTap;

  const HeatmapDayDetailSheet({
    super.key,
    required this.day,
    required this.count,
    required this.db,
    this.deviceContacts = const [],
    this.filters = const AnalyticsFilters(),
    this.onContactTap,
  });

  @override
  State<HeatmapDayDetailSheet> createState() => _HeatmapDayDetailSheetState();
}

class _HeatmapDayDetailSheetState extends State<HeatmapDayDetailSheet> {
  late Future<List<Call>> _callsFuture;

  @override
  void initState() {
    super.initState();
    _callsFuture = _fetchCalls();
  }

  Future<List<Call>> _fetchCalls() {
    return widget.db.getCallsForDay(
      widget.day,
      contactNumberSuffix: widget.filters.contactNormalizedNumber,
      callType: widget.filters.callTypeCode,
    );
  }

  Contact? _matchContact(String? rawNumber) {
    if (rawNumber == null || rawNumber.isEmpty) return null;
    final clean = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return null;
    for (final c in widget.deviceContacts) {
      for (final p in c.phones) {
        final pc = p.number.replaceAll(RegExp(r'[^0-9+]'), '');
        if (pc.isNotEmpty && (pc.endsWith(clean) || clean.endsWith(pc))) {
          return c;
        }
      }
    }
    return null;
  }

  String _formatDate(DateTime day) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}, ${day.year}';
  }

  Color _getCallTypeColor(int type, ColorScheme scheme) {
    switch (type) {
      case 1:
        return const Color(0xFF10B981);
      case 2:
        return const Color(0xFF3B82F6);
      case 3:
        return const Color(0xFFEF4444);
      case 5:
        return const Color(0xFFF59E0B);
      default:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formattedDate = _formatDate(widget.day);

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header Bar ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.count > 0
                                ? [
                                    scheme.primary,
                                    scheme.primary.withValues(alpha: 0.7),
                                  ]
                                : [
                                    scheme.onSurfaceVariant.withValues(alpha: 0.4),
                                    scheme.onSurfaceVariant.withValues(alpha: 0.2),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: widget.count > 0
                              ? [
                                  BoxShadow(
                                    color: scheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          widget.count > 0
                              ? Icons.local_fire_department_rounded
                              : Icons.bedtime_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.count == 0
                                  ? 'No calls recorded'
                                  : '${widget.count} call${widget.count == 1 ? '' : 's'} recorded',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: widget.count > 0
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Calls & Breakdown ───────────────────────────────────────
                FutureBuilder<List<Call>>(
                  future: _callsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
                        ),
                      );
                    }

                    final calls = snapshot.data ?? [];

                    if (calls.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.nightlight_round_outlined,
                                size: 32,
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Quiet Day',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No phone calls were recorded on this date.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final totalSeconds = calls.fold<int>(0, (sum, c) => sum + c.duration);
                    final incoming = calls.where((c) => c.type == 1).length;
                    final outgoing = calls.where((c) => c.type == 2).length;
                    final missed = calls.where((c) => c.type == 3).length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Metrics Strip ───────────────────────────────────
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 16,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'TOTAL TALK',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                          color: scheme.onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      Text(
                                        formatDuration(totalSeconds),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (incoming > 0)
                                  _buildPill(
                                    label: '$incoming in',
                                    color: const Color(0xFF10B981),
                                    icon: Icons.call_received_rounded,
                                  ),
                                if (outgoing > 0)
                                  _buildPill(
                                    label: '$outgoing out',
                                    color: const Color(0xFF3B82F6),
                                    icon: Icons.call_made_rounded,
                                  ),
                                if (missed > 0)
                                  _buildPill(
                                    label: '$missed missed',
                                    color: const Color(0xFFEF4444),
                                    icon: Icons.call_missed_rounded,
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ── Calls Section Title ─────────────────────────────
                        Row(
                          children: [
                            Text(
                              'LOGGED CALLS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${calls.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ── Call Cards List ─────────────────────────────────
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: calls.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final call = calls[index];
                            final color = _getCallTypeColor(call.type, scheme);
                            final icon = callTypeIcon(call.type);
                            final matchedContact = _matchContact(call.number);
                            final displayName = (call.name != null &&
                                    call.name!.trim().isNotEmpty)
                                ? call.name!
                                : (matchedContact?.displayName ??
                                    call.number ??
                                    'Unknown');
                            final timeStr = formatCallTime(call.timestamp);
                            final typeStr = callTypeLabel(call.type);
                            final isMissed = call.type == 3;

                            return Container(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      CupertinoPageRoute(
                                        builder: (context) => CallDetailScreen(
                                          call: call,
                                          db: widget.db,
                                          initialContact: matchedContact,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            icon,
                                            size: 18,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: scheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    timeStr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: scheme
                                                          .onSurfaceVariant
                                                          .withValues(alpha: 0.8),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 5,
                                                    ),
                                                    child: Text(
                                                      '•',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: scheme
                                                            .onSurfaceVariant
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    typeStr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: color,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMissed
                                                ? const Color(0xFFEF4444)
                                                    .withValues(alpha: 0.12)
                                                : scheme.surfaceContainerHighest
                                                    .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isMissed
                                                ? 'Missed'
                                                : formatDuration(call.duration),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isMissed
                                                  ? const Color(0xFFEF4444)
                                                  : scheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: scheme.onSurfaceVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
