import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class CallNoteSection extends StatefulWidget {
  final String? note;
  final ValueChanged<String>? onSave;
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;

  const CallNoteSection({
    super.key,
    required this.note,
    this.onSave,
    this.onAdd,
    this.onEdit,
  });

  @override
  State<CallNoteSection> createState() => _CallNoteSectionState();
}

class _CallNoteSectionState extends State<CallNoteSection> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isModified = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CallNoteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note != widget.note && !_focusNode.hasFocus) {
      _controller.text = widget.note ?? '';
      _isModified = false;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    final hasChanged = val.trim() != (widget.note?.trim() ?? '');
    if (hasChanged != _isModified) {
      setState(() {
        _isModified = hasChanged;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final text = _controller.text.trim();
    if (widget.onSave != null) {
      widget.onSave!(text);
    } else if (widget.onEdit != null) {
      widget.onEdit!();
    }
    if (mounted) {
      setState(() {
        _isModified = false;
        _isSaving = false;
      });
      _focusNode.unfocus();
    }
  }

  void _handleCancel() {
    _controller.text = widget.note ?? '';
    _focusNode.unfocus();
    setState(() {
      _isModified = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassTextArea(
          controller: _controller,
          focusNode: _focusNode,
          placeholder: 'Add a note about this call…',
          minLines: 3,
          maxLines: 6,
          quality: GlassQuality.standard,
          useOwnLayer: false,
          shape: const LiquidRoundedRectangle(borderRadius: 14),
          padding: const EdgeInsets.all(14),
          textStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: 14.5,
            height: 1.4,
          ),
          placeholderStyle: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          onChanged: _onChanged,
          onSubmitted: (_) => _handleSave(),
        ),
        if (_isModified) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : _handleCancel,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, size: 16),
                label: const Text('Save Note'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
