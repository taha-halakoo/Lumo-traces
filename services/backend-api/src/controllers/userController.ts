import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../lib/supabase';
import { z } from 'zod';
import { UserService } from '../services/userService';

const UpdateProfileSchema = z.object({
    username: z.string().min(3).max(30).optional(),
    bio: z.string().max(160).optional(),
    avatar_url: z.string().url().optional()
});

export class UserController {

    static async getMe(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        
        // Parallel fetch: Profile + Stats
        const [profile, stats] = await Promise.all([
            supabase.from('profiles').select('*').eq('id', user.id).single(),
            UserService.getStats(user.id)
        ]);

        if (profile.error) throw profile.error;

        return reply.send({
            ...profile.data,
            stats
        });
    }

    static async updateMe(req: FastifyRequest, reply: FastifyReply) {
        return UserController.updateProfile(req, reply);
    }

    static async getProfile(req: FastifyRequest, reply: FastifyReply) {
        const { id } = req.params as { id: string };
        const { data, error } = await supabase
            .from('profiles')
            .select('id, username, avatar_url, reputation_points, level, created_at') // Public fields only
            .eq('id', id)
            .single();

        if (error) throw { status: 404, message: 'User not found' };
        
        // Also fetch public stats (optional, maybe less detailed)
        const stats = await UserService.getStats(id); // Reuse for now

        return reply.send({ ...data, stats });
    }

    static async getStats(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const stats = await UserService.getStats(user.id);
        return reply.send(stats);
    }

    static async getFriends(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const friends = await UserService.getFriends(user.id);
        return reply.send(friends);
    }

    static async getLeaderboard(req: FastifyRequest, reply: FastifyReply) {
        const { scope, timeframe } = req.query as { scope?: 'global' | 'friends', timeframe?: 'all_time' | 'weekly' };
        const user = (req as any).user;
        const leaderboard = await UserService.getLeaderboard(scope, user.id, timeframe);
        return reply.send(leaderboard);
    }

    static async search(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const { q } = req.query as { q: string };
        if (!q) return reply.send([]);
        const results = await UserService.searchUsers(q, user.id);
        return reply.send(results);
    }

    static async sendRequest(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const { targetId } = req.body as { targetId: string };
        await UserService.sendFriendRequest(user.id, targetId);
        return reply.send({ success: true });
    }

    static async respondRequest(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const { targetId, accept } = req.body as { targetId: string, accept: boolean };
        await UserService.respondToRequest(user.id, targetId, accept);
        return reply.send({ success: true });
    }

    static async follow(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const { targetId } = req.body as { targetId: string };
        await UserService.followUser(user.id, targetId);
        return reply.send({ success: true });
    }

    static async unfollow(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const { targetId } = req.body as { targetId: string };
        await UserService.unfollowUser(user.id, targetId);
        return reply.send({ success: true });
    }

    static async getFollowStatus(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const { targetId } = req.params as { targetId: string };
        const isFollowing = await UserService.getFollowStatus(user.id, targetId);
        return reply.send({ isFollowing });
    }

    static async getPending(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const requests = await UserService.getPendingRequests(user.id);
        return reply.send(requests);
    }

    static async getSettings(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const { data, error } = await supabase.from('user_settings').select('*').eq('user_id', user.id).single();
        if (error) throw error;
        return reply.send(data);
    }

    static async updateSettings(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        const updates = req.body as any;
        const { error } = await supabase.from('user_settings').update(updates).eq('user_id', user.id);
        if (error) throw error;
        return reply.send({ success: true });
    }

    static async updateProfile(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;
        
        // Validation
        const result = UpdateProfileSchema.safeParse(req.body);
        if (!result.success) {
            // Throw standardized error structure
            const err = new Error('Validation Error');
            (err as any).statusCode = 400;
            (err as any).details = (result as any).error.errors;
            throw err;
        }

        const updates = result.data;
        
        const { error } = await supabase
            .from('profiles')
            .update(updates)
            .eq('id', user.id);

        if (error) {
            req.log.error(error);
            throw { status: 500, message: 'Update failed' };
        }

        return reply.send({ success: true });
    }
}