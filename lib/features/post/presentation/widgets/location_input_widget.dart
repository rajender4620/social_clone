import 'package:flutter/material.dart';

class LocationInputWidget extends StatefulWidget {
  final String? location;
  final ValueChanged<String?> onLocationChanged;

  const LocationInputWidget({
    super.key,
    this.location,
    required this.onLocationChanged,
  });

  @override
  State<LocationInputWidget> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<LocationInputWidget> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.location ?? '');
    _isExpanded = widget.location?.isNotEmpty == true;
  }

  @override
  void didUpdateWidget(LocationInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != _controller.text) {
      _controller.text = widget.location ?? '';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (!_isExpanded) {
                _controller.clear();
                widget.onLocationChanged(null);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isExpanded && _controller.text.isNotEmpty
                        ? _controller.text
                        : 'Add location',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _isExpanded && _controller.text.isNotEmpty
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: _isExpanded && _controller.text.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),

        // Location input field (expanded)
        if (_isExpanded) ...[
          const SizedBox(height: 8),
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
              onChanged: widget.onLocationChanged,
              textCapitalization: TextCapitalization.words,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Where was this taken?',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () {
                          _controller.clear();
                          widget.onLocationChanged(null);
                        },
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Popular locations (mock data for now)
          _buildPopularLocations(theme),
        ],
      ],
    );
  }

  Widget _buildPopularLocations(ThemeData theme) {
    final popularLocations = [
      '📍 New York, NY',
      '🗽 Times Square',
      '🌉 Brooklyn Bridge',
      '🏞️ Central Park',
      '🌆 Manhattan',
      '🎭 Broadway',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular locations',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: popularLocations
              .map((location) => _buildLocationChip(theme, location))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLocationChip(ThemeData theme, String location) {
    return ActionChip(
      label: Text(
        location,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      onPressed: () {
        _controller.text = location;
        widget.onLocationChanged(location);
      },
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: theme.colorScheme.outline.withOpacity(0.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
