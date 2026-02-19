import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/ui/glass_shimmer.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import 'feed_notifier.dart';
import 'widgets/trace_card.dart';

class FeedDrawer extends ConsumerStatefulWidget {
  const FeedDrawer({super.key});

  @override
  ConsumerState<FeedDrawer> createState() => _FeedDrawerState();
}

class _FeedDrawerState extends ConsumerState<FeedDrawer> {
  int _lastHapticTime = 0;

  void _onScroll(ScrollController scrollController) {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  bool _onNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastHapticTime > 150 && (notification.scrollDelta?.abs() ?? 0) > 2.0) {
        HapticService.lightImpact(); // Light impact for scrolling texture
        _lastHapticTime = now;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);
    final currentFilter = ref.watch(feedFilterProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        // Attach listener for load more
        scrollController.addListener(() => _onScroll(scrollController));

        return GlassPanel(
          radius: 32,
          blur: DesignTokens.blurHigh, 
          backgroundColor: DesignTokens.glassDarkBase.withOpacity(0.7),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 4)],
                  ),
                ),
              ),

              // Filters
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: ['All', 'Standard', 'Story', 'Orb', 'Friend'].map((f) {
                    final isSelected = currentFilter == f;
                    return GestureDetector(
                      onTap: () {
                        HapticService.selectionClick();
                        ref.read(feedFilterProvider.notifier).state = f;
                      },
                      child: GlassPanel.pill(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: isSelected ? DesignTokens.liquidBlue.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                        border: isSelected ? Border.all(color: DesignTokens.liquidBlue) : null,
                        child: Text(f, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onNotification,
                  child: feedAsync.when(
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 5,
                      itemBuilder: (_, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassShimmer.card(height: 120),
                      ),
                    ),
                    error: (err, _) => Center(child: Text("Connection Error: $err", style: const TextStyle(color: Colors.white))),
                    data: (traces) {
                      if (traces.isEmpty) {
                        return const Center(child: Text("No memories nearby yet.", style: TextStyle(color: Colors.white24)));
                      }
                      return RefreshIndicator(
                        onRefresh: () => ref.read(feedProvider.notifier).loadInitial(),
                        color: DesignTokens.liquidBlue,
                        backgroundColor: Colors.white10,
                        child: ListView.builder(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: traces.length,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemBuilder: (context, index) => TraceCard(trace: traces[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutQuart);
      },
    );
  }
}
