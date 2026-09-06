import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../screens/share_contact_screen.dart';
import 'profile_qr_view.dart';

class ProfileQrSheet extends StatefulWidget {
  final AppDatabase db;
  final ShareQrType initialType;

  const ProfileQrSheet({
    super.key,
    required this.db,
    this.initialType = ShareQrType.personal,
  });

  @override
  State<ProfileQrSheet> createState() => _ProfileQrSheetState();
}

class _ProfileQrSheetState extends State<ProfileQrSheet> {
  late ShareQrType _selectedType;
  late final PageController _pageController;

  // True only while we're driving the PageView ourselves (a segmented-
  // control tap, or a page-control dot tap, animating it to match). Lets
  // onPageChanged tell "the user swiped" apart from "we just animated to
  // here", so neither control ever fights the swipe and haptics don't
  // double-fire on a tap.
  bool _isProgrammaticPageChange = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _pageController = PageController(
      initialPage: ShareQrType.values.indexOf(_selectedType),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectType(ShareQrType type, {required bool fromSwipe}) {
    if (type == _selectedType) return;
    setState(() => _selectedType = type);
    HapticFeedback.selectionClick();

    if (!fromSwipe) {
      _isProgrammaticPageChange = true;
      _pageController
          .animateToPage(
            ShareQrType.values.indexOf(type),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          )
          .then((_) => _isProgrammaticPageChange = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            // GlassModalSheet.show()'s builder only hands back a
            // BuildContext (no ScrollController, unlike showCupertinoSheet's
            // scrollableBuilder) — its own detent drag/resize handling is
            // internal to the package, not driven by this content's scroll
            // position. So this no longer needs to be forced
            // always-scrollable just to give a short sheet something to
            // drag against.
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: StreamBuilder<Map<String, ProfileFieldEntry>>(
              stream: widget.db.watchProfileFields(),
              builder: (context, snapshot) {
                final fields = snapshot.data ?? {};

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Share Contact',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassSegmentedControl(
                      quality: GlassQuality.premium,
                      selectedIndex: ShareQrType.values.indexOf(_selectedType),
                      onSegmentSelected: (index) => _selectType(
                        ShareQrType.values[index],
                        fromSwipe: false,
                      ),
                      segments: const [
                        GlassSegment(label: 'Personal'),
                        GlassSegment(label: 'Work'),
                        GlassSegment(label: 'All'),
                        GlassSegment(label: 'Custom'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Fixed height: PageView needs a bounded main-axis
                    // extent, and pinning it keeps the sheet from resizing
                    // as you swipe between categories with different field
                    // counts (the caption text below still wraps per page).
                    SizedBox(
                      height: 340,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: ShareQrType.values.length,
                        onPageChanged: (index) {
                          if (_isProgrammaticPageChange) return;
                          _selectType(
                            ShareQrType.values[index],
                            fromSwipe: true,
                          );
                        },
                        // Each generated QR sits inside its own glass slab.
                        // useOwnLayer:true + premium quality is exactly the
                        // combo liquid_glass_widgets #192 documents as
                        // detaching its refracted lens from its content
                        // under a continuous ancestor transform — and a
                        // PageView page sliding mid-swipe is precisely that.
                        // Standard quality without its own layer paints
                        // inline instead of through a transform-tracking
                        // layer, so it can't desync from the QR/text under
                        // it, at the cost of the premium shader look. If
                        // you're already on liquid_glass_widgets >=0.29.3
                        // (where #192 was fixed) and want the premium look
                        // back, it's worth retrying useOwnLayer:true here
                        // specifically — but this is the version-independent
                        // fix.
                        itemBuilder: (context, index) => GlassContainer(
                          useOwnLayer: false,
                          quality: GlassQuality.standard,
                          shape: const LiquidRoundedRectangle(borderRadius: 24),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: ProfileQrView(
                              type: ShareQrType.values[index],
                              fields: fields,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // GlassPageControl's capsule isn't a per-dot tap target —
                    // tapping anywhere on it just advances to the next page
                    // (cycling), matching iOS Weather/Home. That's fine here
                    // since the segmented control above already covers
                    // jumping straight to a specific category.
                    GlassPageControl(
                      count: ShareQrType.values.length,
                      currentPage: ShareQrType.values.indexOf(_selectedType),
                      onPageChanged: (page) => _selectType(
                        ShareQrType.values[page],
                        fromSwipe: false,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GlassButton(
                      onTap: () {
                        // Implementation for sharing the vcard text could go here
                      },
                      icon: const Icon(Icons.share),
                      label: 'Share VCard',
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
