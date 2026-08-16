import 'package:flutter/material.dart';

abstract class AlphabetIndexStyle extends StatelessWidget {
  final List<String> letters;
  final ValueChanged<String> onLetterSelected;

  const AlphabetIndexStyle({
    super.key,
    required this.letters,
    required this.onLetterSelected,
  });
}
