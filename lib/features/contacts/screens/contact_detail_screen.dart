import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/contact_cache.dart';
import '../../../core/toast/toast_service.dart';
import '../tabs/contact_activity_tab.dart';
import '../tabs/contact_analytics_tab.dart';
import '../tabs/contact_more_tab.dart';
import '../tabs/contact_overview_tab.dart';
import '../widgets/contact_header.dart';
import '../widgets/contact_share_qr_sheet.dart';
import '../widgets/edit_contact_screen.dart';
import '../widgets/add_contact_screen.dart';

class ContactDetailScreen extends StatefulWidget {
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final Contact? deviceContact;
  final AppDatabase db;

  const ContactDetailScreen({
    super.key,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.deviceContact,
    required this.db,
  });

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  int _selectedTab = 0;
  late final PageController _pageController;
  late Contact? _deviceContact;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTab);
    _deviceContact = widget.deviceContact ??
        ContactCache.findContact(
          number: widget.normalizedNumber,
          name: widget.displayName,
        );
    if (_deviceContact != null && _deviceContact!.photo == null) {
      _loadFullResPhoto();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFullResPhoto() async {
    if (_deviceContact == null) return;
    try {
      final full = await FlutterContacts.getContact(
        _deviceContact!.id,
        withAccounts: true,
        withProperties: true,
        withPhoto: true,
        withThumbnail: true,
      );
      if (full != null && mounted) {
        setState(() {
          _deviceContact = full;
        });
        ContactCache.updateContact(full);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(bool isFavorite) async {
    await widget.db.toggleContactFavorite(widget.normalizedNumber, !isFavorite);
  }

  String _getTitleText() {
    final name = widget.displayName.trim();
    if (name.isNotEmpty &&
        name != widget.normalizedNumber &&
        name != widget.displayNumber) {
      return name;
    }
    if (widget.displayNumber.trim().isNotEmpty) {
      return widget.displayNumber.trim();
    }
    return 'Contact';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ContactDetail?>(
      stream: widget.db.watchContactDetails(widget.normalizedNumber),
      builder: (context, snapshot) {
        final detail = snapshot.data;

        // ── Dynamic background tint from selected contact color ──────────
        final colorValue = detail?.colorValue;
        final scheme = Theme.of(context).colorScheme;
        final bgColor = colorValue != null
            ? Color.lerp(
                scheme.surface,
                Color(colorValue),
                0.06,
              )!
            : null;

        return Material(
          child: GlassScaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: bgColor,
            appBar: GlassAppBar.pinned(
              title: Text(
                _getTitleText(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                GlassBarItem.menu(
                  icon: const Icon(Icons.more_horiz),
                  id: 'contact_more',
                  label: 'More',
                  menuAlignment: GlassMenuAlignment.topRight,
                  menuWidth: 215,
                  menuItems: [
                    GlassMenuItem(
                      title: detail?.isFavorite == true
                          ? 'Remove Favorite'
                          : 'Add to Favorite',
                      icon: Icon(
                        detail?.isFavorite == true
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                        color: detail?.isFavorite == true
                            ? Colors.amber
                            : scheme.onSurfaceVariant,
                      ),
                      titleStyle: TextStyle(
                        decoration: TextDecoration.none,
                        color: detail?.isFavorite == true
                            ? Colors.amber
                            : scheme.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      onTap: () =>
                          _toggleFavorite(detail?.isFavorite ?? false),
                    ),
                    GlassMenuItem(
                      title: 'Copy Number',
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      titleStyle: TextStyle(
                        decoration: TextDecoration.none,
                        color: scheme.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      onTap: () {
                        final numberToCopy =
                            widget.displayNumber.isNotEmpty
                                ? widget.displayNumber
                                : widget.normalizedNumber;
                        Clipboard.setData(
                            ClipboardData(text: numberToCopy));
                        ToastService.info(
                            context, 'Phone number copied.');
                      },
                    ),
                    GlassMenuItem(
                      title: 'Share Contact',
                      icon: Icon(
                        Icons.share_outlined,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      titleStyle: TextStyle(
                        decoration: TextDecoration.none,
                        color: scheme.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      onTap: () {
                        showContactShareQrSheet(
                          context,
                          displayName: _getTitleText(),
                          phoneNumber: widget.displayNumber.isNotEmpty
                              ? widget.displayNumber
                              : widget.normalizedNumber,
                          deviceContact: _deviceContact,
                        );
                      },
                    ),
                    if (_deviceContact != null)
                      GlassMenuItem(
                        title: 'Edit Contact',
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        titleStyle: TextStyle(
                          decoration: TextDecoration.none,
                          color: scheme.onSurface,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        onTap: () async {
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                CupertinoPageRoute(
                                  builder: (context) => EditContactScreen(
                                    contact: _deviceContact!,
                                  ),
                                ),
                              );

                          if (updated == true && mounted) {
                            setState(() {});
                            if (context.mounted) {
                              ToastService.success(
                                  context, 'Contact updated.');
                            }
                          }
                        },
                      )
                    else
                      GlassMenuItem(
                        title: 'Create Contact',
                        icon: Icon(
                          Icons.person_add_outlined,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        titleStyle: TextStyle(
                          decoration: TextDecoration.none,
                          color: scheme.onSurface,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        onTap: () async {
                          final created = await showAddContactScreen(
                            context,
                            initialName: widget.displayName,
                            initialPhone: widget.displayNumber,
                          );

                          if (created != null && mounted) {
                            setState(() => _deviceContact = created);
                            if (context.mounted) {
                              ToastService.success(
                                  context, 'Contact created.');
                            }
                          }
                        },
                      ),
                    GlassMenuItem(
                      title: detail?.isArchived == true
                          ? 'Unarchive'
                          : 'Archive',
                      icon: Icon(
                        detail?.isArchived == true
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      titleStyle: TextStyle(
                        decoration: TextDecoration.none,
                        color: scheme.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      onTap: () async {
                        final isArchived = detail?.isArchived ?? false;

                        await widget.db.setContactFields(
                          widget.normalizedNumber,
                          ContactDetailsCompanion(
                            isArchived: drift.Value(!isArchived),
                          ),
                        );

                        if (!context.mounted) return;

                        ToastService.success(
                          context,
                          isArchived
                              ? 'Contact unarchived'
                              : 'Contact archived',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        8,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                    child: ContactHeader(
                      displayName: widget.displayName,
                      displayNumber: widget.displayNumber,
                      deviceContact: _deviceContact,
                      isFavorite: detail?.isFavorite ?? false,
                      isArchived: detail?.isArchived ?? false,
                      onFavoritePressed: () =>
                          _toggleFavorite(detail?.isFavorite ?? false),
                      colorValue: detail?.colorValue,
                      db: widget.db,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassSegmentedControl.scrollable(
                      quality: GlassQuality.standard,
                      selectedIndex: _selectedTab,
                      onSegmentSelected: (index) {
                        if (_selectedTab == index) {
                          return;
                        }

                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedTab = index;
                        });
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      segments: const [
                        GlassSegment(label: 'Overview'),
                        GlassSegment(label: 'Activity'),
                        GlassSegment(label: 'Analytics'),
                        GlassSegment(label: 'More'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        if (_selectedTab != index) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedTab = index;
                          });
                        }
                      },
                      children: [
                        _KeepAlivePage(
                          child: ContactOverviewTab(
                            normalizedNumber: widget.normalizedNumber,
                            displayNumber: widget.displayNumber,
                            deviceContact: _deviceContact,
                            detail: detail,
                            db: widget.db,
                          ),
                        ),
                        _KeepAlivePage(
                          child: ContactActivityTab(
                            normalizedNumber: widget.normalizedNumber,
                            db: widget.db,
                            deviceContact: _deviceContact,
                          ),
                        ),
                        _KeepAlivePage(
                          child: ContactAnalyticsTab(
                            normalizedNumber: widget.normalizedNumber,
                            db: widget.db,
                          ),
                        ),
                        _KeepAlivePage(
                          child: ContactMoreTab(
                            normalizedNumber: widget.normalizedNumber,
                            displayName: widget.displayName,
                            displayNumber: widget.displayNumber,
                            detail: detail,
                            db: widget.db,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
