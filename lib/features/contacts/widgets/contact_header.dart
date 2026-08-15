import 'package:flutter/material.dart';

class ContactHeader extends StatelessWidget {
  final String displayName;
  final String displayNumber;
  final bool isFavorite;
  final VoidCallback? onFavoritePressed;

  const ContactHeader({
    super.key,
    required this.displayName,
    required this.displayNumber,
    required this.isFavorite,
    this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(child: _buildContactInfo()),
        _buildFavoriteButton(),
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 28,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 22),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        if (displayNumber.isNotEmpty)
          Text(displayNumber, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber : Colors.grey,
        size: 28,
      ),
      onPressed: onFavoritePressed,
    );
  }
}
