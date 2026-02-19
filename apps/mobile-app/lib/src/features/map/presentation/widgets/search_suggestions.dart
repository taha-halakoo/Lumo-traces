import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import '../../data/geocoding_repository.dart';

class SearchSuggestionsOverlay extends StatelessWidget {
  final List<PlaceResult> suggestions;
  final Function(PlaceResult) onSelect;

  const SearchSuggestionsOverlay({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return GlassPanel(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.zero,
      radius: 20,
      // More transparent, darker base for "Liquid" depth
      backgroundColor: DesignTokens.glassDarkBase.withOpacity(0.7),
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1, 
            color: Colors.white.withOpacity(0.05),
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final place = suggestions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticService.selectionClick();
                  onSelect(place);
                },
                overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DesignTokens.liquidBlue.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: DesignTokens.liquidBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              place.displayName.split(',')[0],
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              place.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.north_west, color: Colors.white.withOpacity(0.3), size: 16),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
          },
        ),
      ),
    ).animate()
     .fadeIn(duration: 300.ms)
     .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
