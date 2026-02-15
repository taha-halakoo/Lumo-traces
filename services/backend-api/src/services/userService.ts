import { supabase } from '../lib/supabase';

export class UserService {
    
    static async getVectors(userId: string): Promise<{ mood: number[], identity: number[] } | null> {
        const { data, error } = await supabase
            .from('profiles')
            .select('mood_embedding, identity_embedding')
            .eq('id', userId)
            .single();

        if (error || !data) return null;

        const parseVector = (v: any) => {
            if (!v) return [];
            if (Array.isArray(v)) return v;
            if (typeof v === 'string') {
                try {
                    return JSON.parse(v);
                } catch (e) {
                    // Handle postgres vector format "[0.1,0.2,...]" if it fails JSON.parse
                    return v.replace('[', '').replace(']', '').split(',').map(Number);
                }
            }
            return [];
        };

        return {
            mood: parseVector(data.mood_embedding),
            identity: parseVector(data.identity_embedding)
        };
    }

    static async updateMood(userId: string, newMood: number[]) {
        // Supabase/Postgres vector extension expects a string "[1,2,3]" or an array depending on the client config
        await supabase.from('profiles').update({ 
            mood_embedding: newMood, // Supabase-js handles arrays for vector types now
            last_mood_update: new Date().toISOString()
        }).eq('id', userId);
    }

    static async updateIdentity(userId: string, newIdentity: number[]) {
        await supabase.from('profiles').update({ 
            identity_embedding: newIdentity
        }).eq('id', userId);
    }

    static async getStats(userId: string) {
        // Parallel queries for speed
        const [dropped, found, profile] = await Promise.all([
            supabase.from('traces').select('*', { count: 'exact', head: true }).eq('author_id', userId),
            supabase.from('unlocked_traces').select('*', { count: 'exact', head: true }).eq('user_id', userId),
            supabase.from('profiles').select('reputation_points, xp, level').eq('id', userId).single()
        ]);

        return {
            dropped_count: dropped.count || 0,
            found_count: found.count || 0,
            reputation: profile.data?.reputation_points || 0,
            xp: profile.data?.xp || 0,
            level: profile.data?.level || 1
        };
    }

    static async searchUsers(query: string, currentUserId: string) {
        const { data } = await supabase
            .from('profiles')
            .select('id, username, avatar_url, level')
            .ilike('username', `%${query}%`)
            .neq('id', currentUserId)
            .limit(20);
        return data || [];
    }

    static async getFriendStatus(userId: string, targetId: string) {
        const { data } = await supabase
            .from('friendships')
            .select('status, user_id_1, user_id_2')
            .or(`and(user_id_1.eq.${userId},user_id_2.eq.${targetId}),and(user_id_1.eq.${targetId},user_id_2.eq.${userId})`)
            .single();
        
        if (!data) return 'none';
        if (data.status === 'accepted') return 'accepted';
        if (data.user_id_1 === userId) return 'sent'; // I sent it
        return 'received'; // They sent it
    }

    static async sendFriendRequest(userId: string, targetId: string) {
        // Check existing
        const status = await this.getFriendStatus(userId, targetId);
        if (status !== 'none') throw { status: 400, message: 'Request already exists or friends' };

        await supabase.from('friendships').insert({
            user_id_1: userId,
            user_id_2: targetId,
            status: 'pending'
        });
    }

    static async respondToRequest(userId: string, targetId: string, accept: boolean) {
        if (accept) {
            await supabase.from('friendships')
                .update({ status: 'accepted' })
                .match({ user_id_1: targetId, user_id_2: userId }); // Match the request sent BY target TO me
        } else {
            await supabase.from('friendships')
                .delete()
                .match({ user_id_1: targetId, user_id_2: userId });
        }
    }

    static async getPendingRequests(userId: string) {
        const { data } = await supabase
            .from('friendships')
            .select('user_id_1, created_at')
            .eq('user_id_2', userId) // I am the target
            .eq('status', 'pending');
            
        if (!data || data.length === 0) return [];

        const requesterIds = data.map(f => f.user_id_1);
        const { data: profiles } = await supabase.from('profiles').select('*').in('id', requesterIds);
        return profiles || [];
    }

    // ... (rest of methods)

    static async getFriends(userId: string) {
        // Fetch friendships where user is either 1 or 2, and status is accepted
        const { data, error } = await supabase
            .from('friendships')
            .select('user_id_1, user_id_2')
            .eq('status', 'accepted')
            .or(`user_id_1.eq.${userId},user_id_2.eq.${userId}`);

        if (error || !data) return [];

        // Extract Friend IDs
        const friendIds = data.map(f => f.user_id_1 === userId ? f.user_id_2 : f.user_id_1);
        
        if (friendIds.length === 0) return [];

        // Fetch Profiles
        const { data: friends } = await supabase
            .from('profiles')
            .select('id, username, avatar_url, reputation_points')
            .in('id', friendIds);

        return friends || [];
    }

    static async getLeaderboard() {
        const { data, error } = await supabase
            .from('profiles')
            .select(`
                id, username, avatar_url, reputation_points,
                user_settings!inner(incognito_mode)
            `)
            .eq('user_settings.incognito_mode', false)
            .order('reputation_points', { ascending: false })
            .limit(50);
        
        if (error) throw error;
        return data || [];
    }

    static async followUser(followerId: string, targetId: string) {
        if (followerId === targetId) throw { status: 400, message: 'Cannot follow yourself' };
        
        const { error } = await supabase
            .from('friendships')
            .insert({
                user_id_1: followerId,
                user_id_2: targetId,
                status: 'accepted' // Simplification: Follow is auto-accepted connection
            });
        
        if (error && error.code !== '23505') throw error; // Ignore if already following
    }

    static async unfollowUser(followerId: string, targetId: string) {
        await supabase
            .from('friendships')
            .delete()
            .match({ user_id_1: followerId, user_id_2: targetId });
    }

    static async getFollowStatus(userId: string, targetId: string) {
        const { data } = await supabase
            .from('friendships')
            .select('status')
            .match({ user_id_1: userId, user_id_2: targetId })
            .single();
        
        return !!data;
    }
}