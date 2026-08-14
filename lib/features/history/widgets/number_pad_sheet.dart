import 'package:flutter/material.dart';

Future<String?> showNumberPadSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _NumberPadSheet(),
  );
}

class _NumberPadSheet extends StatefulWidget {
  const _NumberPadSheet();

  @override
  State<_NumberPadSheet> createState() => _NumberPadSheetState();
}

class _NumberPadSheetState extends State<_NumberPadSheet> {
  String _digits = '';

  void _addDigit(String digit) {
    setState(() => _digits += digit);
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _digits.isEmpty ? 'Enter a number' : _digits,
            style: const TextStyle(fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          _NumberPadGrid(onDigit: _addDigit, onBackspace: _backspace),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _digits.isEmpty
                  ? null
                  : () => Navigator.pop(context, _digits),
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberPadGrid extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _NumberPadGrid({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 64, height: 64);
            return SizedBox(
              width: 64,
              height: 64,
              child: TextButton(
                onPressed: key == '⌫' ? onBackspace : () => onDigit(key),
                child: Text(key, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
