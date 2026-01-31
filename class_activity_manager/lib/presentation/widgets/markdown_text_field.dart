import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// A text field that shows raw markdown when focused and rendered markdown
/// when unfocused. Tapping the preview requests focus to edit.
class MarkdownTextField extends StatefulWidget {
  const MarkdownTextField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.decoration,
    this.minLines,
    this.maxLines,
    this.hintText,
    this.readOnly = false,
  });

  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;
  final int? minLines;
  final int? maxLines;
  final String? hintText;

  /// When true, only the formatted preview is shown and the field cannot be focused.
  final bool readOnly;

  @override
  State<MarkdownTextField> createState() => _MarkdownTextFieldState();
}

class _MarkdownTextFieldState extends State<MarkdownTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isEditing) {
      setState(() => _isEditing = _focusNode.hasFocus);
    }
  }

  @override
  void didUpdateWidget(MarkdownTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != (widget.initialValue ?? '')) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  InputDecoration get _effectiveDecoration {
    return (widget.decoration ?? const InputDecoration()).copyWith(
      hintText: widget.hintText ?? widget.decoration?.hintText,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.readOnly && _isEditing) {
      return TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        decoration: _effectiveDecoration,
        minLines: widget.minLines,
        maxLines: widget.maxLines ?? 1,
        keyboardType: TextInputType.multiline,
      );
    }

    final preview = InputDecorator(
      decoration: _effectiveDecoration,
      isEmpty: _controller.text.isEmpty,
      child: Align(alignment: Alignment.topLeft, child: _buildPreview(context)),
    );

    if (widget.readOnly) {
      return IgnorePointer(child: preview);
    }

    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        child: preview,
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final text = _controller.text;
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    try {
      return MarkdownBody(
        data: text,
        selectable: false,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
      );
    } catch (e) {
      debugPrint(
        'MarkdownTextField: markdown parse error, falling back to plain text: $e',
      );
      return Text(text, style: Theme.of(context).textTheme.bodyLarge);
    }
  }
}
