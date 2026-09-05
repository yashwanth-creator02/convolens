import 'package:flutter/material.dart';

import 'alphabet_index_style.dart';

class SideBarAlphabetIndex extends AlphabetIndexStyle {
  const SideBarAlphabetIndex({
    super.key,
    required super.letters,
    required super.onLetterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: letters.map((letter) {
          return Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onLetterSelected(letter),
              child: Container(
                width: 28,
                constraints: const BoxConstraints(maxHeight: 16),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
