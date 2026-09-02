import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactHeader extends StatefulWidget {
  final String displayName;
  final String displayNumber;
  final Contact? deviceContact;
  final bool isFavorite;
  final VoidCallback? onFavoritePressed;
  final int? colorValue;

  const ContactHeader({
    super.key,
    required this.displayName,
    required this.displayNumber,
    this.deviceContact,
    required this.isFavorite,
    this.onFavoritePressed,
    this.colorValue,
  });

  @override
  State<ContactHeader> createState() => _ContactHeaderState();
}

class _ContactHeaderState extends State<ContactHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    if (widget.displayNumber.isEmpty) return;

    final uri = Uri(
      scheme: 'tel',
      path: widget.displayNumber,
    );

    await launchUrl(uri);
  }

  Future<void> _message() async {
    if (widget.displayNumber.isEmpty) return;

    final uri = Uri(
      scheme: 'sms',
      path: widget.displayNumber,
    );

    await launchUrl(uri);
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Column(
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    _buildAvatar(radius: 42),
                    const SizedBox(height: 16),
                    _buildContactInfo(organization, email),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: _buildFavoriteButton(),
              ),
            ],
          ),

          if (widget.displayNumber.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildCallActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildCallActions() {
    return SizedBox(
      height: 138,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SideActionButton(
            icon: Icons.message_outlined,
            tooltip: 'Message',
            onPressed: _message,
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 140,
            height: 138,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _orbitController.value * math.pi * 2,
                      child: CircularPhoneNumber(
                        text: widget.displayNumber,
                        radius: 52,
                        startAngle: math.pi * 1.08,
                        sweepAngle: math.pi * 0.84,
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    );
                  },
                ),

                Material(
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _call,
                    child: const SizedBox(
                      width: 68,
                      height: 68,
                      child: Icon(
                        Icons.call_rounded,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          _SideActionButton(
            icon: Icons.videocam_outlined,
            tooltip: 'Video',
            onPressed: _call,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({double radius = 28}) {
    final thumbnail = widget.deviceContact?.thumbnail;
    final color =
        widget.colorValue != null ? Color(widget.colorValue!) : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      backgroundImage: thumbnail != null
          ? MemoryImage(thumbnail)
          : null,
      child: thumbnail == null
          ? Text(
              widget.displayName.isNotEmpty
                  ? widget.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: (radius * 0.8).roundToDouble(),
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }

  Widget _buildContactInfo(
    Organization? organization,
    String? email,
  ) {
    return Column(
      children: [
        Text(
          widget.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),

        const SizedBox(height: 4),

        if (organization != null &&
            (organization.company.isNotEmpty ||
                organization.title.isNotEmpty))
          Text(
            [
              organization.title,
              organization.company,
            ].where((s) => s.isNotEmpty).join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),

        if (email != null && email.isNotEmpty)
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      tooltip: widget.isFavorite
          ? 'Remove from favorites'
          : 'Add to favorites',
      icon: Icon(
        widget.isFavorite
            ? Icons.star
            : Icons.star_border,
        size: 28,
      ),
      onPressed: widget.onFavoritePressed,
    );
  }
}

class _SideActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _SideActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 21,
        padding: const EdgeInsets.all(11),
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
            _buildCharacter(
              characters[index],
              index,
              characters.length,
            ),
        ],
      ),
    );
  }

  Widget _buildCharacter(
    String character,
    int index,
    int count,
  ) {
    final progress = count <= 1
        ? 0.5
        : index / (count - 1);

    final angle = startAngle + (sweepAngle * progress);

    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: angle + (math.pi / 2),
        child: Text(
          character,
          style: textStyle,
        ),
      ),
    );
  }
}
