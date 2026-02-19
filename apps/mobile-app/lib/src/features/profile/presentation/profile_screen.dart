import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import '../data/user_repository.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(userRepositoryProvider).getMe();
});

final userTracesProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  return ref.read(userRepositoryProvider).getUserTraces(user.id);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  int _calculateAge(String? birthdateIso) {
    if (birthdateIso == null) return 0;
    final birthDate = DateTime.parse(birthdateIso);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final tracesAsync = ref.watch(userTracesProvider);

    return Scaffold(
      backgroundColor: DesignTokens.glassDarkBase,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
        data: (profile) {
          final stats = profile['stats'] ?? {};
          final username = profile['username'] ?? 'Explorer';
          final fullName = profile['full_name'] ?? '';
          final avatarUrl = profile['avatar_url'] ?? "https://api.dicebear.com/7.x/bottts/svg?seed=$username";
          
          final bio = profile['bio'] as String?;
          final personality = profile['personality_type'] as String?;
          final birthdate = profile['birthdate'] as String?;
          final age = _calculateAge(birthdate);

          return CustomScrollView(
            slivers: [
              // 1. App Bar with Liquid Header
              SliverAppBar(
                expandedHeight: 320,
                floating: false,
                pinned: true,
                backgroundColor: DesignTokens.glassDarkBase,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [theme.colorScheme.primary.withOpacity(0.2), DesignTokens.glassDarkBase],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              width: 110, height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 2),
                                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                                image: DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover),
                              ),
                            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                            const SizedBox(height: 16),
                            Text(fullName.isNotEmpty ? fullName : username, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                            Text("@$username", style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white54)),
                            const SizedBox(height: 16),
                            _buildInfoChip(context, "Level ${stats['level'] ?? 1}", Icons.auto_awesome),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Personality & Bio
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (personality != null) _buildInfoChip(context, personality, Icons.psychology),
                          if (age > 0) const SizedBox(width: 12),
                          if (age > 0) _buildInfoChip(context, "$age Years", Icons.cake),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (bio != null && bio.isNotEmpty)
                        GlassPanel(
                          width: double.infinity,
                          backgroundColor: Colors.white.withOpacity(0.03),
                          child: Text(bio, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Stats Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12, crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatTile(context, "Traces Found", "${stats['found_count'] ?? 0}", Icons.radar),
                    _buildStatTile(context, "Dropped", "${stats['dropped_count'] ?? 0}", Icons.location_on),
                    _buildStatTile(context, "Reputation", "${stats['reputation'] ?? 0}", Icons.star),
                    _buildStatTile(context, "Unlocked", "100%", Icons.lock_open), 
                  ],
                ),
              ),

              // 4. Memory History Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
                  child: Text("MEMORY LOG", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),

              // 5. Memory History List
              tracesAsync.when(
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (err, _) => SliverToBoxAdapter(child: Center(child: Text("Error: $err"))),
                data: (traces) {
                  if (traces.isEmpty) {
                    return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No memories logged yet", style: TextStyle(color: Colors.white24)))));
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final trace = traces[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: GestureDetector(
                            onTap: () => context.push('/trace/${trace['id']}'),
                            child: GlassPanel(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.white.withOpacity(0.05),
                              radius: 16,
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(color: DesignTokens.liquidBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.location_on, color: DesignTokens.liquidBlue, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(trace['content_text'] ?? 'Untitled Trace', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        Text(trace['type'] ?? 'STANDARD', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2)),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1);
                      },
                      childCount: traces.length,
                    ),
                  );
                }
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    return GlassPanel.pill(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: Colors.white.withOpacity(0.05),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value, IconData icon, {int delay = 0}) {
    return GlassPanel(
      backgroundColor: Colors.white.withOpacity(0.05),
      radius: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        height: 60,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        radius: 16,
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2);
  }
}
