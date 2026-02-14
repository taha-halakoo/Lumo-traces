import { supabase } from '../lib/supabase';

export class NotificationService {
    
    /**
     * Sends an in-app notification to a user.
     * (Future: Also trigger Push Notification via FCM/Expo)
     */
    static async send(userId: string, type: string, title: string, body: string, data?: any) {
        await supabase.from('notifications').insert({
            user_id: userId,
            type,
            title,
            body,
            data
        });
    }

    /**
     * Notify Friends that a user dropped a trace.
     */
    static async notifyFriendsOfTrace(userId: string, traceId: string) {
        // 1. Fetch Friends
        const { data: friendships } = await supabase
            .from('friendships')
            .select('user_id_1, user_id_2')
            .or(`user_id_1.eq.${userId},user_id_2.eq.${userId}`)
            .eq('status', 'accepted');

        if (!friendships) return;

        // 2. Identify Recipients
        const recipients = friendships.map(f => f.user_id_1 === userId ? f.user_id_2 : f.user_id_1);

        // 3. Send (Batch insert for efficiency)
        const notifications = recipients.map(fid => ({
            user_id: fid,
            type: 'friend_trace',
            title: 'New Friend Trace!',
            body: 'A friend dropped something nearby.',
            data: { trace_id: traceId }
        }));

        if (notifications.length > 0) {
            await supabase.from('notifications').insert(notifications);
        }
    }
}
