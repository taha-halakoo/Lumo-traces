import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/widgets/liquid_background.dart';
import '../data/notification_repository.dart';

final notificationsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(notificationRepositoryProvider).getNotifications();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Notifications", style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
            data: (notifications) {
              if (notifications.isEmpty) {
                return const Center(child: Text("No notifications", style: TextStyle(color: Colors.white54)));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16), // Top padding for AppBar
                itemCount: notifications.length,
                itemBuilder: (context, index) {
              final notif = notifications[index];
              final isUnread = notif['is_read'] == false;
              final title = notif['title'] ?? 'Notification';
              final body = notif['body'] ?? '';
              final type = notif['type'] ?? 'info';
              
              return GlassPanel(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                backgroundColor: isUnread ? theme.colorScheme.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                radius: 16,
                border: Border.all(
                  color: isUnread ? theme.colorScheme.primary.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUnread ? theme.colorScheme.primary.withOpacity(0.2) : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(type),
                        color: isUnread ? theme.colorScheme.primary : Colors.white54,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (body.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                body,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            "Just now", 
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2);
            },
          );
        },
      ),
    ]));
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'LIKE': return Icons.favorite;
      case 'FRIEND_REQUEST': return Icons.person_add;
      case 'UNLOCK': return Icons.lock_open;
      default: return Icons.notifications;
    }
  }
}
