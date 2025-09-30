import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/services/location_service.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/services/snackbar_service.dart';

class EnhancedLocationPicker extends StatefulWidget {
  final LocationData? selectedLocation;
  final ValueChanged<LocationData?> onLocationChanged;

  const EnhancedLocationPicker({
    super.key,
    this.selectedLocation,
    required this.onLocationChanged,
  });

  @override
  State<EnhancedLocationPicker> createState() => _EnhancedLocationPickerState();
}

class _EnhancedLocationPickerState extends State<EnhancedLocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _isExpanded = false;
  bool _isLoadingCurrentLocation = false;
  bool _isSearching = false;
  List<LocationData> _searchResults = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.selectedLocation != null;
    if (widget.selectedLocation != null) {
      _searchController.text = widget.selectedLocation!.address;
    }
    
    // Listen to search input
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    // Cancel previous search
    _searchDebounce?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    // Debounce search for 500ms
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await LocationService.searchLocations(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
        context.showErrorSnackbar('Failed to search locations');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      final location = await LocationService.getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _searchController.text = location.shortAddress;
        });
        widget.onLocationChanged(location);
        HapticService.selectionClick();
        context.showSuccessSnackbar('📍 Current location detected');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to get current location';
        if (e is LocationServiceException) {
          errorMessage = e.message;
        }
        context.showErrorSnackbar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
    }
  }

  void _selectLocation(LocationData location) {
    setState(() {
      _searchController.text = location.shortAddress;
      _searchResults.clear();
    });
    widget.onLocationChanged(location);
    _searchFocusNode.unfocus();
    HapticService.selectionClick();
  }

  void _clearLocation() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
      _isExpanded = false;
    });
    widget.onLocationChanged(null);
    HapticService.lightImpact();
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
                _clearLocation();
              } else {
                // Focus search field when expanding
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _searchFocusNode.requestFocus();
                });
              }
            });
            HapticService.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.selectedLocation?.shortAddress ?? 'Add location',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.selectedLocation != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: widget.selectedLocation != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (widget.selectedLocation != null)
                  GestureDetector(
                    onTap: _clearLocation,
                    child: Icon(
                      Icons.clear,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),

        // Expanded location picker
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          
          // Search field
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textCapitalization: TextCapitalization.words,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search for a location...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: _isSearching
                    ? Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Current location button
          _buildCurrentLocationButton(theme),

          // Search results
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSearchResults(theme),
          ],

          // Popular locations (when no search results)
          if (_searchResults.isEmpty && _searchController.text.isEmpty) ...[
            const SizedBox(height: 16),
            _buildPopularLocations(theme),
          ],
        ],
      ],
    );
  }

  Widget _buildCurrentLocationButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoadingCurrentLocation ? null : _getCurrentLocation,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_isLoadingCurrentLocation)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.my_location,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isLoadingCurrentLocation 
                        ? 'Getting your location...'
                        : 'Use current location',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.gps_fixed,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search results',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: _searchResults
                .asMap()
                .entries
                .map((entry) => _buildLocationItem(
                      theme,
                      entry.value,
                      isLast: entry.key == _searchResults.length - 1,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationItem(ThemeData theme, LocationData location, {bool isLast = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectLocation(location),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.shortAddress,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (location.address != location.shortAddress) ...[
                      const SizedBox(height: 2),
                      Text(
                        location.address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularLocations(ThemeData theme) {
    final popularLocations = [
      '🗽 New York, NY',
      '🌉 San Francisco, CA',
      '🏖️ Miami Beach, FL',
      '🎭 Los Angeles, CA',
      '🏙️ Chicago, IL',
      '🌆 Seattle, WA',
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
          color: theme.colorScheme.onSurface,
        ),
      ),
      onPressed: () {
        _searchController.text = location;
        // For popular locations, we'll create a simple LocationData
        final simpleLocation = LocationData(
          latitude: 0,
          longitude: 0,
          address: location,
        );
        widget.onLocationChanged(simpleLocation);
        HapticService.selectionClick();
      },
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: theme.colorScheme.outline.withOpacity(0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
