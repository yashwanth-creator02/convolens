import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../models/analytics_filters.dart';
import '../models/yearly_recap.dart';
import '../repository/analytics_repository.dart';

class YearlyRecapScreen extends StatefulWidget {
  final AppDatabase db;
  final List<Contact> deviceContacts;
  final int year;

  const YearlyRecapScreen({
    super.key,
    required this.db,
    required this.deviceContacts,
    required this.year,
  });

  @override
  State<YearlyRecapScreen> createState() => _YearlyRecapScreenState();
}

class _YearlyRecapScreenState extends State<YearlyRecapScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = AnalyticsRepository(widget.db);
    final yearStart = DateTime(widget.year, 1, 1);
    final yearEnd = DateTime(widget.year, 12, 31, 23, 59, 59);

    final filters = AnalyticsFilters(
      dateRange: DateRangeOption.custom,
      customStart: yearStart,
      customEnd: yearEnd,
    );

    return GlassScaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder(
        stream: repository.watchSummary(widget.deviceContacts, filters),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final recap = YearlyRecap.fromSummary(widget.year, snapshot.data!);
          final pages = _buildPages(recap);

          return Stack(
            children: [
              GestureDetector(
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < screenWidth / 2) {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  } else {
                    if (_currentPage < pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  }
                },
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: pages,
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 12,
                right: 12,
                child: Row(
                  children: List.generate(pages.length, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? Colors.white
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 24,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPages(YearlyRecap recap) {
    return [
      _recapCard(
        '${recap.year}',
        'You made',
        '${recap.totalCalls}',
        'calls this year',
      ),
      _recapCard(
        '⏱️',
        'You spent',
        '${recap.totalTalkHours} hours',
        'on the phone',
      ),
      if (recap.topContact != null)
        _recapCard(
          '🥇',
          'You talked most to',
          recap.topContact!.displayName,
          '${recap.topContact!.callCount} calls together',
        ),
      _recapCard(
        '🔥',
        'Your longest streak was',
        '${recap.longestStreak} days',
        'in a row',
      ),
      if (recap.busiestDay != null)
        _recapCard(
          '📅',
          'Your busiest day was',
          recap.busiestDay!,
          '${recap.busiestDayCount} calls',
        ),
      _recapCard(
        '📆',
        'Your busiest day of the week',
        'was ${recap.busiestWeekday}',
        '',
      ),
      _recapCard('🕐', 'You call most around', '${recap.busiestHour}:00', ''),
      _recapCard(
        '📞',
        'Your missed call rate was',
        '${(recap.missedRate * 100).round()}%',
        '',
      ),
    ];
  }

  Widget _recapCard(String emoji, String lead, String headline, String sub) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 24),
              Text(
                lead,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
