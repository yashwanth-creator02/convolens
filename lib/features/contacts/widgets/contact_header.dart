import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/toast/toast_service.dart';
import '../../../core/utils/call_launcher.dart';
import 'contact_message_sheet.dart';

class ContactHeader extends StatefulWidget {
  final String displayName;
  final String displayNumber;
  final Contact? deviceContact;
  final bool isFavorite;
  final bool isArchived;
  final VoidCallback? onFavoritePressed;
  final int? colorValue;
  final AppDatabase? db;

  const ContactHeader({
    super.key,
    required this.displayName,
    required this.displayNumber,
    this.deviceContact,
    required this.isFavorite,
    this.isArchived = false,
    this.onFavoritePressed,
    this.colorValue,
    this.db,
  });

  @override
  State<ContactHeader> createState() => _ContactHeaderState();
}

class _ContactHeaderState extends State<ContactHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;
  late String _activeNumber;
  bool _hasWhatsApp = false;

  @override
  void initState() {
    super.initState();
    _activeNumber = widget.displayNumber;

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _resolveMostCalledNumber();
    _checkWhatsApp();
  }

  @override
  void didUpdateWidget(covariant ContactHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceContact != widget.deviceContact ||
        oldWidget.displayNumber != widget.displayNumber) {
      _resolveMostCalledNumber();
      _checkWhatsApp();
    }
  }

  Future<void> _resolveMostCalledNumber() async {
    if (widget.deviceContact != null &&
        widget.deviceContact!.phones.length > 1 &&
        widget.db != null) {
      final phoneNumbers =
          widget.deviceContact!.phones.map((p) => p.number).toList();
      final mostCalled =
          await widget.db!.getMostCalledNumber(phoneNumbers);
      if (mostCalled != null && mostCalled.isNotEmpty && mounted) {
        setState(() {
          _activeNumber = mostCalled;
        });
        return;
      }
    }
    if (mounted && _activeNumber != widget.displayNumber) {
      setState(() {
        _activeNumber = widget.displayNumber;
      });
    }
  }

  Future<void> _checkWhatsApp() async {
    final hasAccount = widget.deviceContact?.accounts.any(
          (a) =>
              a.type.toLowerCase().contains('whatsapp') ||
              a.name.toLowerCase().contains('whatsapp'),
        ) ??
        false;

    if (hasAccount) {
      if (mounted) setState(() => _hasWhatsApp = true);
      return;
    }

    final installed = await CallLauncher.isWhatsAppInstalled();
    if (mounted) {
      setState(() => _hasWhatsApp = installed);
    }
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  Future<void> _callCellular() async {
    final number =
        _activeNumber.isNotEmpty ? _activeNumber : widget.displayNumber;
    if (number.isEmpty) return;
    await CallLauncher.call(number);
  }

  Future<void> _callWhatsApp() async {
    final number =
        _activeNumber.isNotEmpty ? _activeNumber : widget.displayNumber;
    if (number.isEmpty) return;
    await CallLauncher.openWhatsAppCall(number);
  }

  Future<void> _openWhatsAppChatDirect() async {
    final number =
        _activeNumber.isNotEmpty ? _activeNumber : widget.displayNumber;
    if (number.isEmpty) return;

    final launched = await CallLauncher.openWhatsAppChat(number);
    if (!launched && mounted) {
      ToastService.info(context, 'Could not open WhatsApp for $number');
    }
  }

  void _openMessageComposeSheet() {
    final number =
        _activeNumber.isNotEmpty ? _activeNumber : widget.displayNumber;
    if (number.isEmpty) return;
    showMessageComposeSheet(
      context,
      displayName: widget.displayName,
      phoneNumber: number,
    );
  }

  Widget _buildGradientBackground(
    Color bannerColor,
    ColorScheme scheme,
    String initials,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bannerColor.withValues(alpha: 0.7),
            Color.lerp(bannerColor, scheme.surface, 0.5) ?? scheme.surface,
            scheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty && initials != '#' ? initials : '?',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.12),
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final photo =
        widget.deviceContact?.photo ?? widget.deviceContact?.thumbnail;

    final bannerColor = widget.colorValue != null
        ? Color(widget.colorValue!)
        : scheme.primary;

    final initials = _getInitials(widget.displayName);
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = (screenHeight * 0.32).clamp(220.0, 270.0);

    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Contact image as the full background of the upper header ─────
          Positioned.fill(
            child: photo != null && photo.isNotEmpty
                ? Image.memory(
                    photo,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.3),
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        _buildGradientBackground(
                            bannerColor, scheme, initials),
                  )
                : _buildGradientBackground(bannerColor, scheme, initials),
          ),

          // ── Scrim overlay – lighter at top to show more of the photo ──────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.60),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── Star Chip in top-right corner when favorited ───────────────────
          if (widget.isFavorite)
            Positioned(
              top: 14,
              right: 14,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: widget.onFavoritePressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.75),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Favorite',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade200,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Bottom-Right Corner Action Stack (Message on top of Call) ─────
          if (_activeNumber.isNotEmpty)
            Positioned(
              right: 14,
              bottom: 12,
              child: _buildRightCornerActionStack(scheme),
            ),
        ],
      ),
    );
  }

  Widget _buildRightCornerActionStack(ColorScheme scheme) {
    const double orbitRadius = 28.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Message button stacked on top of call button, with its own orbiting number
        _buildMessageOrbit(orbitRadius: orbitRadius),
        const SizedBox(height: 6),
        // Call button(s) at the bottom: individual rotating number for each button
        if (!_hasWhatsApp)
          _buildCellularCallOrbit(orbitRadius: orbitRadius, scheme: scheme)
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCellularCallOrbit(orbitRadius: orbitRadius, scheme: scheme),
              const SizedBox(width: 6),
              _buildWhatsAppCallOrbit(orbitRadius: orbitRadius),
            ],
          ),
      ],
    );
  }

  Widget _buildMessageOrbit({required double orbitRadius}) {
    final containerSize = (orbitRadius * 2) + 18.0;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating phone number track
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_orbitController.value * math.pi * 2,
                child: CircularPhoneNumber(
                  text: _activeNumber,
                  radius: orbitRadius,
                  charSpacing: 7.0,
                  textStyle: const TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 6, color: Colors.black87),
                    ],
                  ),
                ),
              );
            },
          ),

          // Center Message Button
          _SideActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: _openWhatsAppChatDirect,
            onLongPress: _openMessageComposeSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildCellularCallOrbit({
    required double orbitRadius,
    required ColorScheme scheme,
  }) {
    final containerSize = (orbitRadius * 2) + 18.0;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating phone number track
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_orbitController.value * math.pi * 2,
                child: CircularPhoneNumber(
                  text: _activeNumber,
                  radius: orbitRadius,
                  charSpacing: 7.0,
                  textStyle: const TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 6, color: Colors.black87),
                    ],
                  ),
                ),
              );
            },
          ),

          // Cellular Call Button
          Material(
            shape: const CircleBorder(),
            elevation: 3,
            color: Colors.black.withValues(alpha: 0.5),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _callCellular,
              child: Tooltip(
                message: 'Call $_activeNumber',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppCallOrbit({
    required double orbitRadius,
  }) {
    final containerSize = (orbitRadius * 2) + 18.0;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating phone number track
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_orbitController.value * math.pi * 2,
                child: CircularPhoneNumber(
                  text: _activeNumber,
                  radius: orbitRadius,
                  charSpacing: 7.0,
                  textStyle: const TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 6, color: Colors.black87),
                    ],
                  ),
                ),
              );
            },
          ),

          // WhatsApp Call Button
          Material(
            shape: const CircleBorder(),
            elevation: 3,
            color: const Color(0xFF25D366),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _callWhatsApp,
              child: Tooltip(
                message: 'WhatsApp Call $_activeNumber',
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.phone_in_talk_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _SideActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  const _SideActionButton({
    required this.icon,
    required this.onPressed,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.black.withValues(alpha: 0.35),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        onLongPress: onLongPress != null
            ? () {
                HapticFeedback.heavyImpact();
                onLongPress!();
              }
            : null,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class CircularPhoneNumber extends StatelessWidget {
  final String text;
  final double radius;
  final double startAngle;
  final double? sweepAngle;
  final TextStyle? textStyle;
  final double charSpacing;

  const CircularPhoneNumber({
    super.key,
    required this.text,
    required this.radius,
    this.startAngle = math.pi * 1.05,
    this.sweepAngle,
    this.textStyle,
    this.charSpacing = 7.2,
  });

  @override
  Widget build(BuildContext context) {
    final characters = text.characters.toList();

    if (characters.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: radius * 2 + 22,
      height: radius * 2 + 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int index = 0; index < characters.length; index++)
            _buildCharacter(characters[index], index, characters.length),
        ],
      ),
    );
  }

  Widget _buildCharacter(String character, int index, int count) {
    final double angle;
    if (sweepAngle != null) {
      final progress = count <= 1 ? 0.5 : index / (count - 1);
      angle = startAngle + (sweepAngle! * progress);
    } else {
      final angleStep = (charSpacing <= 0 ? 7.2 : charSpacing) / radius;
      angle = startAngle + (index * angleStep);
    }

    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: angle + (math.pi / 2),
        child: Text(
          character,
          style: textStyle?.copyWith(letterSpacing: 0) ??
              const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
              ),
        ),
      ),
    );
  }
}
