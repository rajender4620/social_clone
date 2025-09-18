import 'package:flutter/material.dart';

class CaptionInputWidget extends StatefulWidget {
  final String caption;
  final ValueChanged<String> onCaptionChanged;

  const CaptionInputWidget({
    super.key,
    required this.caption,
    required this.onCaptionChanged,
  });

  @override
  State<CaptionInputWidget> createState() => _CaptionInputWidgetState();
}

class _CaptionInputWidgetState extends State<CaptionInputWidget> {
  late TextEditingController _controller;
  final int _maxLength = 2200; // Instagram's caption limit

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.caption);
  }

  @override
  void didUpdateWidget(CaptionInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.caption != _controller.text) {
      _controller.text = widget.caption;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingChars = _maxLength - _controller.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Write a caption',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 8),

        // Caption input field
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: _controller,
            onChanged: widget.onCaptionChanged,
            maxLines: null,
            maxLength: _maxLength,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Share what\'s on your mind...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '', // Hide default counter
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Character counter and suggestions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Suggestions
            Expanded(
              child: Text(
                'Add hashtags or mention friends with @',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),

            // Character counter
            Text(
              '$remainingChars',
              style: theme.textTheme.bodySmall?.copyWith(
                color: remainingChars < 100
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Quick action buttons
        _buildQuickActions(theme),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Wrap(
      spacing: 8,
      children: [
        _buildQuickActionChip(
          theme,
          '📸 #photography',
          () => _insertText('#photography'),
        ),
        _buildQuickActionChip(
          theme,
          '🌟 #mood',
          () => _insertText('#mood'),
        ),
        _buildQuickActionChip(
          theme,
          '🎯 #inspiration',
          () => _insertText('#inspiration'),
        ),
        _buildQuickActionChip(
          theme,
          '💭 #thoughts',
          () => _insertText('#thoughts'),
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(
    ThemeData theme,
    String label,
    VoidCallback onTap,
  ) {
    return ActionChip(
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: theme.colorScheme.outline.withOpacity(0.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  void _insertText(String text) {
    final currentText = _controller.text;
    final selection = _controller.selection;
    
    String newText;
    int newCursorPosition;

    if (selection.isValid) {
      // Insert at cursor position
      newText = currentText.substring(0, selection.start) +
          text +
          currentText.substring(selection.end);
      newCursorPosition = selection.start + text.length;
    } else {
      // Append to end
      newText = currentText.isEmpty ? text : '$currentText $text';
      newCursorPosition = newText.length;
    }

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newCursorPosition);
    widget.onCaptionChanged(newText);
  }
}
