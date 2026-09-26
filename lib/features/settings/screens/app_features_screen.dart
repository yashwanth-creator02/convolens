import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class AppFeaturesScreen extends StatefulWidget {
  const AppFeaturesScreen({super.key});

  @override
  State<AppFeaturesScreen> createState() => _AppFeaturesScreenState();
}

class _AppFeaturesScreenState extends State<AppFeaturesScreen> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String summary,
    required List<String> bulletPoints,
    required List<String> tags,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = accentColor ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(icon, size: 20, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Summary
            Text(
              summary,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 12),

            // Tag Pills
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Bullet points
            ...bulletPoints.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: scheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Point Features'),
        largeTitleController: _titleController,
      ),
      body: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: _titleController.scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
            ),
            GlassLargeTitle(
              text: 'Point Features',
              controller: _titleController,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Easter Egg Banner
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Easter Egg Unlocked!',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'You discovered the complete capabilities guide of Point.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Feature 1: Call History & Multi-Tier Timeline Wave Navigator
                  _buildFeatureCard(
                    context: context,
                    title: 'Call History & Timeline Wave',
                    icon: Icons.timeline_rounded,
                    accentColor: const Color(0xFF38BDF8),
                    summary:
                        'Intuitive timeline interface with fluid multi-tier wave scrubbing to navigate decades of call records instantly.',
                    tags: ['Liquid Wave', 'Thumb Preview', 'Audio Attachments'],
                    bulletPoints: [
                      'Edge Scrubbing: Pull inward from the screen edge to scrub by Year (Tier 1), Month (Tier 2), or individual Date (Tier 3).',
                      'Fluid Wave Canvas: Real-time dynamic canvas rendering fluid wave crests with animated text markers.',
                      'Pop-out Preview: Floating badge projects left of your thumb, giving instant temporal feedback before release.',
                      'Call Cards: Detailed logs displaying avatar, call type, duration, attachments, and scheduled follow-ups.',
                    ],
                  ),

                  // Feature 2: Relationship Analytics & Visualizations
                  _buildFeatureCard(
                    context: context,
                    title: 'Relationship Analytics',
                    icon: Icons.insights_rounded,
                    accentColor: const Color(0xFF818CF8),
                    summary:
                        'Interactive data visualization dashboard that turns call patterns into meaningful relationship insights.',
                    tags: ['Network Graph', 'Heatmap Calendar', 'Radial Clock'],
                    bulletPoints: [
                      'Relationship Web: Force-directed node graph visualizing your top contacts and connection frequencies.',
                      'Contribution Heatmaps: GitHub-style daily call volume calendars across weeks and months.',
                      '24-Hour Radial Clock: Visual clock face mapping your communication distribution throughout the day.',
                      'Communication Streaks: Consecutive day tracking with automated milestone celebrations.',
                    ],
                  ),

                  // Feature 3: Contact Intelligence & Personal CRM
                  _buildFeatureCard(
                    context: context,
                    title: 'Contact Intelligence & CRM',
                    icon: Icons.contacts_rounded,
                    accentColor: const Color(0xFFA855F7),
                    summary:
                        'Relationship management beyond standard phonebooks with rich notes, color tags, and reachability preferences.',
                    tags: ['SQLite Sync', 'Custom Tags', 'Preferences'],
                    bulletPoints: [
                      'Device Contact Sync: Auto-merges local contacts with local SQLite interaction history.',
                      'Rich Notes & Metadata: Add contextual notes, meeting logs, and relationship history.',
                      'Color-coded Tags: Categorize contacts into Client, VIP, Family, Work, and custom tags.',
                      'Reachability Settings: Specify preferred contact methods (Call, WhatsApp, Email, SMS) and optimal times of day.',
                      'Social Links & Archiving: Attach LinkedIn, X, GitHub, and websites to cards.',
                    ],
                  ),

                  // Feature 4: Digital Profile & QR Sharing
                  _buildFeatureCard(
                    context: context,
                    title: 'Digital Profile & QR Sharing',
                    icon: Icons.qr_code_2_rounded,
                    accentColor: const Color(0xFF34D399),
                    summary:
                        'Personal digital business card with dynamic QR code generation and direct vCard export.',
                    tags: ['vCard 3.0', 'Dynamic QR', 'Custom Fields'],
                    bulletPoints: [
                      'Interactive Profile: Manage your display name, company, title, email, and bio in one place.',
                      'Dynamic QR Generator: Generates standard vCard QR codes with customizable glass styling.',
                      'Custom Profile Fields: Add arbitrary key-value metadata fields to your digital card.',
                      'Instant Export: Share digital cards directly to contacts and external apps.',
                    ],
                  ),

                  // Feature 5: Liquid Glass UI Architecture
                  _buildFeatureCard(
                    context: context,
                    title: 'Liquid Glass UI System',
                    icon: Icons.lens_blur_rounded,
                    accentColor: const Color(0xFFF472B6),
                    summary:
                        'State-of-the-art visual architecture powered by liquid_glass_widgets and custom GLSL shaders.',
                    tags: ['Frosted Glass', 'GLSL Shaders', 'Adaptive Themes'],
                    bulletPoints: [
                      'Glass Scaffold & App Bars: Pinned title headers with fluid collapse/expand animations and refraction.',
                      'Tactile Feedback: Interaction scaling, liquid ripples, and native haptic click responses.',
                      'Morphing Sheets: Bottom sheets that spring and morph smoothly from user tap coordinates.',
                      'Multi-Theme Support: Purple, Cosmo, Dark, and Light themes tailored with HSL colors.',
                    ],
                  ),

                  // Feature 6: Interactive Contact Swipe Actions
                  _buildFeatureCard(
                    context: context,
                    title: 'Contact Quick Swipe Actions',
                    icon: Icons.swipe_rounded,
                    accentColor: const Color(0xFF10B981),
                    summary:
                        'Direct, gesture-driven calling and messaging from the contact list with non-destructive spring-back physics.',
                    tags: ['Swipe-to-Call', 'Swipe-to-SMS', 'Spring Physics', 'Haptics'],
                    bulletPoints: [
                      'Swipe Right (Emerald Green): Instantly initiates a direct cellular phone call.',
                      'Swipe Left (Accent Blue): Quickly opens SMS messaging for the contact.',
                      'Non-Destructive Spring: Contact cards spring back cleanly into place without record deletion.',
                      'Sensory Haptics: Crisp physical vibration feedback confirms gesture activation.',
                    ],
                  ),

                  // Feature 7: Callback Latency & Responsiveness Engine
                  _buildFeatureCard(
                    context: context,
                    title: 'Callback Latency & Responsiveness',
                    icon: Icons.speed_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    summary:
                        'Intelligent SQLite analytics engine measuring missed call response times and communication balance.',
                    tags: ['24h Return Rate', 'Average Latency', 'Initiation Balance', 'Best Time to Call'],
                    bulletPoints: [
                      '24-Hour Follow-Up Tracking: Calculates exact minutes elapsed before returning missed calls with normalized E.164 phone matching.',
                      'Missed Call Return Rate %: Visual gauge of your overall responsiveness and reliability.',
                      'Initiation Balance Split: Comparative balance bar showing what percentage of calls were initiated by you vs. the contact.',
                      'Automated "Best Time to Call": Identifies historical peak answering patterns (e.g., "Wednesdays, 4 PM – 6 PM") on contact profiles.',
                    ],
                  ),

                  // Feature 8: Precision Date Jumper & Filter Chips
                  _buildFeatureCard(
                    context: context,
                    title: 'Precision Date Jumper & Filter Chips',
                    icon: Icons.calendar_month_rounded,
                    accentColor: const Color(0xFF06B6D4),
                    summary:
                        'Zero-latency call history filtering and instant temporal navigation without scrolling lag.',
                    tags: ['Floating Jumper', 'Today Shortcut', 'In-Memory Filters', 'Live Counts'],
                    bulletPoints: [
                      'Floating Date Badge: Real-time date chip displays current list position and opens an interactive year/month selector.',
                      'Instant "Today" Shortcut: Jump directly to the most recent call logs with a single tap.',
                      'In-Memory Filter Chips: Instant pill bar switching between All, Missed, Incoming, Outgoing, and Unknown calls.',
                      'Reactive Badge Counters: Live call tallies update synchronously with zero database round-trip overhead.',
                    ],
                  ),

                  // Feature 9: Permanent Glass Alphabet Scrubber
                  _buildFeatureCard(
                    context: context,
                    title: 'Glass Alphabet Scrubber & Autocomplete',
                    icon: Icons.sort_by_alpha_rounded,
                    accentColor: const Color(0xFFE11D48),
                    summary:
                        'Tactile edge scrubber with precomputed jumps and real-time duplicate contact detection dropdown.',
                    tags: ['Alphabet Scrubber', 'Duplicate Detection', 'Autocomplete', 'Precomputed Offsets'],
                    bulletPoints: [
                      'Permanent Glass Scrubber: Semi-transparent vertical letter rail resting along the right bezel, blooming to full opacity on touch.',
                      'Precomputed Jump Offsets: Letter dragging moves the list instantaneously without queuing conflicting animations.',
                      'Live Duplicate Detection: Auto-suggests matching contacts as you type first name, last name, phone, or company.',
                      'One-Tap Redirection: Tapping any matched suggestion opens the pre-filled contact editor immediately.',
                    ],
                  ),

                  // Feature 10: Actionable Notifications & Deep Linking
                  _buildFeatureCard(
                    context: context,
                    title: 'Actionable Notifications & Deep Linking',
                    icon: Icons.notifications_active_rounded,
                    accentColor: const Color(0xFFEC4899),
                    summary:
                        'Interactive system alerts with quick actions and compound payload deep linking.',
                    tags: ['Call Back Button', 'Message Button', 'Deep Links', 'Diagnostics'],
                    bulletPoints: [
                      'Action Buttons: Return missed calls or send text messages directly from your device notification shade.',
                      'Deep Link Routing: Tapping alerts navigates straight to Call Details or Contact Profiles.',
                      'Daily Streak Reminders: Automated milestone tracking celebrating consistent relationship keeping.',
                      'Built-in Diagnostics: Dedicated notification tester screen under Settings to verify system channels.',
                    ],
                  ),

                  // Feature 11: Multi-Step Onboarding & Permissions Hub
                  _buildFeatureCard(
                    context: context,
                    title: 'Onboarding & Permissions Hub',
                    icon: Icons.verified_user_rounded,
                    accentColor: const Color(0xFF8B5CF6),
                    summary:
                        'Guided 3-step setup walkthrough with interactive permissions checklist and one-tap granting.',
                    tags: ['3-Step Guide', 'Grant All Required', 'Live Status', 'Local Privacy'],
                    bulletPoints: [
                      'Interactive Checklist: Live status cards for Call Logs, Contacts, Notifications, Microphone, and Exact Alarms.',
                      'One-Tap "Grant All Required": Sequentially prompts for essential permissions with emerald check badges.',
                      'Settings Revisit: Walkthrough can be relaunched anytime via Settings ➔ Permissions & Security ➔ Welcome Guide & Setup.',
                      'Privacy-First Architecture: Validates local-only offline storage guarantees.',
                    ],
                  ),

                  // Feature 12: Sub-Pixel Hero Alignment & Fluid Transitions
                  _buildFeatureCard(
                    context: context,
                    title: 'Sub-Pixel Hero Alignment & Fluid Transitions',
                    icon: Icons.auto_awesome_motion_rounded,
                    accentColor: const Color(0xFF6366F1),
                    summary:
                        'Coordinated Hero image positioning and directional slide navigation matching native back button physics.',
                    tags: ['Hero Morphs', 'Directional Tab Slide', 'Cupertino Navigation', 'GPU Blur Isolation'],
                    bulletPoints: [
                      'Sub-Pixel Hero Alignment: Call Details and Contact Details share exact physical coordinates (top: padding.top + kToolbarHeight + 16.0) for wobble-free morphs.',
                      'Directional Tab Sliding: Main shell switches tabs with horizontal slide-and-fade matching forward and back navigation.',
                      'Universal Cupertino Transitions: Pushing screens and tapping the top-left back button utilize consistent, smooth slide curves.',
                      'RepaintBoundary Isolation: Heavy backdrop blur shaders are isolated from sliver list redraws for silky 120 FPS scrolling.',
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
