import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/call_launcher.dart';

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
    // 1. Check if device contact has a registered WhatsApp account
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

    // 2. Check if WhatsApp is installed on device
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
    final number = _activeNumber.isNotEmpty ? _activeNumber : widget.displayNumber;
    if (number.isEmpty) return;
    await CallLauncher.call(number);
  }

  Future<void> _callWhatsApp() async {
    final number = _activeNumber.isNotEmpty ? _activeNumber : widget.displayNumber;
    if (number.isEmpty) return;
    await CallLauncher.openWhatsAppCall(number);
  }

  Future<void> _openMessageDefault() async {
    final number = _activeNumber.isNotEmpty ? _activeNumber : widget.displayNumber;
    if (number.isEmpty) return;

    final launched = await CallLauncher.openWhatsAppChat(number);
    if (!launched) {
      await CallLauncher.message(number);
    }
  }

  void _showQuickComposeSheet(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = TextEditingController();

    final quickTemplates = [
      'Can I call you back?',
      'I am on my way.',
      'Please call me when free.',
      'Got it, thanks!',
      'Running 5 minutes late.',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message ${widget.displayName}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _activeNumber,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: quickTemplates.map((template) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(template,
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            controller.text = template;
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: scheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final text = controller.text;
                          Navigator.of(ctx).pop();
                          await CallLauncher.openWhatsAppChat(_activeNumber,
                              text: text);
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('WhatsApp',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        onPressed: () async {
                          final text = controller.text;
                          Navigator.of(ctx).pop();
                          await CallLauncher.messageWithText(
                              _activeNumber, text);
                        },
                        icon: const Icon(Icons.sms_outlined, size: 18),
                        label: const Text('Messages',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final organization = widget.deviceContact?.organizations.isNotEmpty == true
        ? widget.deviceContact!.organizations.first
        : null;

    final email = widget.deviceContact?.emails.isNotEmpty == true
        ? widget.deviceContact!.emails.first.address
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 10),
          _buildContactInfo(organization, email),
          if (_activeNumber.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildCallActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildCallActions() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Outer orbit radius: 52 for single call button, 64 for dual (Cellular + WhatsApp)
    final orbitRadius = _hasWhatsApp ? 64.0 : 52.0;
    final containerSize = (orbitRadius * 2) + 24.0;

    return SizedBox(
      height: containerSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SideActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'WhatsApp (Hold for options)',
            onPressed: _openMessageDefault,
            onLongPress: () => _showQuickComposeSheet(context),
          ),
          const SizedBox(width: 14),
          SizedBox(
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
                        startAngle: math.pi * 1.05,
                        sweepAngle: math.pi * 0.90,
                        textStyle: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  },
                ),

                // Center Action Buttons inside Orbit
                if (!_hasWhatsApp)
                  // Single Large Cellular Call Button
                  Material(
                    shape: const CircleBorder(),
                    elevation: 3,
                    color: scheme.primary,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _callCellular,
                      child: const SizedBox(
                        width: 66,
                        height: 66,
                        child: Icon(Icons.call_rounded,
                            size: 28, color: Colors.white),
                      ),
                    ),
                  )
                else
                  // Dual Call Buttons: Cellular + WhatsApp
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cellular Call Button
                      Material(
                        shape: const CircleBorder(),
                        elevation: 3,
                        color: scheme.surfaceContainerHigh,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _callCellular,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.call_rounded,
                              size: 22,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // WhatsApp Call Button
                      Material(
                        shape: const CircleBorder(),
                        elevation: 3,
                        color: const Color(0xFF25D366),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _callWhatsApp,
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.phone_in_talk_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _SideActionButton(
            icon: Icons.sms_outlined,
            tooltip: 'SMS (Hold for options)',
            onPressed: () => CallLauncher.message(_activeNumber),
            onLongPress: () => _showQuickComposeSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final photo =
        widget.deviceContact?.photo ?? widget.deviceContact?.thumbnail;
    final color = widget.colorValue != null
        ? Color(widget.colorValue!)
        : scheme.primaryContainer;

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null && photo.isNotEmpty
          ? Image.memory(
              photo,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            )
          : Center(
              child: Text(
                _getInitials(widget.displayName),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: widget.colorValue != null
                      ? Colors.white
                      : scheme.onPrimaryContainer,
                ),
              ),
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

  Widget _buildContactInfo(Organization? organization, String? email) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (widget.isArchived) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ARCHIVED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (organization != null &&
            (organization.company.isNotEmpty || organization.title.isNotEmpty)) ...[
          const SizedBox(height: 3),
          Text(
            [
              organization.title,
              organization.company,
            ].where((s) => s.isNotEmpty).join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (email != null && email.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }
}

class _SideActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  const _SideActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      shape: const CircleBorder(),
      color: scheme.surfaceContainerHigh,
      elevation: 1.5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        onLongPress: onLongPress,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 20,
              color: scheme.onSurface,
            ),
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
  final double sweepAngle;
  final TextStyle? textStyle;

  const CircularPhoneNumber({
    super.key,
    required this.text,
    required this.radius,
    required this.startAngle,
    required this.sweepAngle,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final characters = text.characters.toList();

    if (characters.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: radius * 2 + 20,
      height: radius * 2 + 20,
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
    final progress = count <= 1 ? 0.5 : index / (count - 1);
    final angle = startAngle + (sweepAngle * progress);

    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: angle + (math.pi / 2),
        child: Text(character, style: textStyle),
      ),
    );
  }
}
