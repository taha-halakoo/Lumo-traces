import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/ui/glass_shimmer.dart';
import 'package:traces_mobile/src/core/widgets/liquid_background.dart';
import 'explorer_providers.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracesAsync = ref.watch(explorerTracesProvider);
    final recsAsync = ref.watch(userRecommendationsProvider);
    final selectedFilter = ref.watch(explorerFilterProvider);
    final filters = ['All', 'People', 'Standard', 'Stories', 'Orbs', 'Challenges'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const LiquidBackground(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GlassPanel.pill(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                icon: const Icon(Icons.search, color: Colors.white54),
                                hintText: "Search memories...",
                                hintStyle: const TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                                suffixIcon: _searchCtrl.text.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        ref.read(explorerSearchProvider.notifier).state = '';
                                      },
                                    )
                                  : null,
                              ),
                              onSubmitted: (val) {
                                ref.read(explorerSearchProvider.notifier).state = val;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 60,
                            child: recsAsync.when(
                              data: (recs) => ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: recs.length,
                                itemBuilder: (context, i) => Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () => context.push('/profile/${recs[i]['id']}'),
                                    child: Hero(
                                      tag: 'user_avatar_${recs[i]['id']}',
                                      child: Container(
                                        width: 50, height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: DesignTokens.liquidBlue.withOpacity(0.3), width: 2),
                                          image: DecorationImage(
                                            image: NetworkImage(recs[i]['avatar_url'] ?? ''),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: filters.map((filter) {
                                final isSelected = selectedFilter == filter;
                                return GestureDetector(
                                  onTap: () => ref.read(explorerFilterProvider.notifier).state = filter,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? DesignTokens.liquidBlue.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? DesignTokens.liquidBlue : Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Text(
                                      filter,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white54,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (selectedFilter == 'People')
                recsAsync.when(
                  data: (recs) => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: GlassPanel(
                          onTap: () => context.push('/profile/${recs[i]['id']}'),
                          child: Row(
                            children: [
                              CircleAvatar(backgroundImage: NetworkImage(recs[i]['avatar_url'] ?? "https://api.dicebear.com/7.x/bottts/svg?seed=${recs[i]['username']}")),
                              const SizedBox(width: 16),
                              Text(recs[i]['username'] ?? 'Explorer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              const Icon(Icons.chevron_right, color: Colors.white24),
                            ],
                          ),
                        ),
                      ),
                      childCount: recs.length,
                    ),
                  ),
                  loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => SliverToBoxAdapter(child: Text("Error: $e")),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: tracesAsync.when(
                    loading: () => SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      itemBuilder: (context, index) => GlassShimmer.card(height: (index % 3 + 1) * 100.0),
                      childCount: 6,
                    ),
                    error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white)))),
                    data: (traces) {
                      if (traces.isEmpty) {
                        return const SliverToBoxAdapter(child: Center(child: Text("No results found", style: TextStyle(color: Colors.white54))));
                      }
                      return SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemBuilder: (context, index) {
                          final trace = traces[index];
                          final id = trace['id'];
                          final hasImage = trace['media_url'] != null;
                          
                          return GestureDetector(
                            onTap: () => context.push('/trace/$id'),
                            child: Hero(
                              tag: 'trace_card_$id',
                              child: GlassPanel(
                                padding: EdgeInsets.zero,
                                radius: 20,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hasImage)
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        child: CachedNetworkImage(
                                          imageUrl: trace['media_url'], 
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => GlassShimmer.card(height: 150),
                                          errorWidget: (context, url, error) => const Icon(Icons.error),
                                        ),
                                      )
                                    else
                                      Container(
                                        height: (index % 2 + 1) * 80.0,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [DesignTokens.liquidBlue.withOpacity(0.2), Colors.transparent],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white10, size: 40)),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            trace['content_text'] ?? '',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 8,
                                                backgroundImage: NetworkImage(trace['profiles']?['avatar_url'] ?? "https://api.dicebear.com/7.x/bottts/svg?seed=anon"),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  trace['profiles']?['username'] ?? 'Anonymous',
                                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
                        },
                        childCount: traces.length,
                      );
                    },
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
            ],
          ),
        ],
      ),
    );
  }
}
