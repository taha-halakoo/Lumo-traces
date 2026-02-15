import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/ui/glass_shimmer.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import 'package:traces_mobile/src/core/api/api_client.dart';
import 'feed_notifier.dart';

class FeedDrawer extends ConsumerStatefulWidget {
  const FeedDrawer({super.key});

  @override
  ConsumerState<FeedDrawer> createState() => _FeedDrawerState();
}

class _FeedDrawerState extends ConsumerState<FeedDrawer> {
  
  void _onScroll(ScrollController scrollController) {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  Future<void> _likeTrace(String id) async {
    HapticService.lightImpact();
    // Optimistic UI update could be handled by local state or riverpod mutation
    // For now, just fire and forget the API call
    try {
      await ref.read(apiClientProvider).post('/traces/$id/like');
    } catch (_) {}
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
        // Attach listener
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
                      onTap: () => ref.read(feedFilterProvider.notifier).state = f,
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
                        itemBuilder: (context, index) => _buildTraceCard(context, traces[index], index),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutQuart);
      },
    );
  }

  Widget _buildTraceCard(BuildContext context, dynamic trace, int index) {
    final theme = Theme.of(context);
    final profile = trace['profiles'] ?? {};
    final username = profile['username'] ?? 'Anonymous';
    final avatar = profile['avatar_url'] ?? "https://api.dicebear.com/7.x/bottts/svg?seed=$username";
    final text = trace['content_text'] ?? '';
    final id = trace['id'];
    // final isLiked = trace['is_liked'] ?? false; // Assuming backend sends this, which it doesn't yet fully in 'feed' query
    
    return GestureDetector(
      onTap: () => context.push('/trace/$id'),
      child: GlassPanel(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.white.withOpacity(0.05),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'trace_avatar_$id',
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(avatar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("${trace['type']} • Just now", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white38, size: 20),
                  onPressed: () => _likeTrace(id),
                ),
                Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.2)),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
            if (trace['media_url'] != null) ...[
              const SizedBox(height: 12),
              Hero(
                tag: 'trace_image_$id',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(trace['media_url'], height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(delay: (30 * index).ms).slideX(begin: 0.05, end: 0),
    );
  }
}
