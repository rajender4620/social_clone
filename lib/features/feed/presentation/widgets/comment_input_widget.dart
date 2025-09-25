import 'package:flutter/material.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/services/snackbar_service.dart';

class CommentInputWidget extends StatefulWidget {
  final Function(String) onCommentSubmitted;
  final bool isSubmitting;

  const CommentInputWidget({
    super.key,
    required this.onCommentSubmitted,
    this.isSubmitting = false,
  });

  @override
  State<CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends State<CommentInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isCommentValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isValid = _controller.text.trim().isNotEmpty;
    if (isValid != _isCommentValid) {
      setState(() {
        _isCommentValid = isValid;
      });
    }
  }

  void _submitComment() {
    final content = _controller.text.trim();
    if (content.isEmpty || widget.isSubmitting) return;

    // Add haptic feedback for comment submission
    HapticService.comment();

    widget.onCommentSubmitted(content);
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Comment input field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !widget.isSubmitting,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: null,
                    minLines: 1,
                    maxLength: 500, // Instagram-like limit
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      // Hide counter unless close to limit
                      if (maxLength != null && currentLength > maxLength * 0.8) {
                        return Text(
                          '$currentLength/$maxLength',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: currentLength > maxLength
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        );
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: widget.isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : GestureDetector(
                        onTap: _isCommentValid ? _submitComment : null,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _isCommentValid
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.send,
                            size: 18,
                            color: _isCommentValid
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onPrimary.withOpacity(0.5),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
