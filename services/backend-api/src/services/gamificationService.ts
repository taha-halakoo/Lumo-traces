import { supabase } from '../lib/supabase';
import { ParasiteService } from './parasiteService';

export class GamificationService {
    
    /**
     * Checks if a user has earned any new badges based on their recent action.
     * This is a "Fire and Forget" background task.
     */
    static async checkBadges(userId: string) {
        // 1. Fetch User Stats
        const { data: profile } = await supabase
            .from('profiles')
            .select('reputation_points')
            .eq('id', userId)
            .single();

        if (!profile) return;

        // 2. Fetch All Badges (Cached in reality)
        const { data: allBadges } = await supabase.from('badges').select('*');
        if (!allBadges) return;

        // 3. Evaluate Logic (Simple Rule Engine)
        const newBadges: string[] = [];
        
        for (const badge of allBadges) {
            const criteria = badge.criteria as any;
            
            // Example: Check Reputation Threshold
            if (criteria.min_reputation && profile.reputation_points >= criteria.min_reputation) {
                newBadges.push(badge.id);
            }
            // Add more criteria checks here (e.g. unlock_count)
        }

        // 4. Award Badges (Ignore duplicates)
        if (newBadges.length > 0) {
            const inserts = newBadges.map(bId => ({ user_id: userId, badge_id: bId }));
            const { data } = await supabase.from('user_badges').upsert(inserts, { onConflict: 'user_id, badge_id' }).select();
            
            // Logic: Notify User!
            if (data && data.length > 0) {
                const { NotificationService } = await import('./notificationService');
                for (const badge of newBadges) {
                    await NotificationService.send(userId, 'badge', 'New Badge Unlocked!', `You earned: ${badge}`);
                }
            }
        }
    }

    /**
     * Handles the "Parasitic" Lifecycle.
     */
    static async handleInfection(userId: string, traceId: string, lat: number, long: number) {
        // 1. Create Infection Record
        const { error } = await supabase.from('parasitic_infections').insert({
            user_id: userId,
            trace_id: traceId,
            origin_lat: lat,
            origin_long: long,
            cure_distance_km: 1.0 // Default difficulty
        });
        
        if (error) throw error;
        
        return { status: 'INFECTED', message: 'You have caught a Virus Trace! Walk 1km to cure it.' };
    }

    static async checkCure(userId: string, currentLat: number, currentLong: number) {
        // ... (existing implementation)
        return { status: 'INFECTED', message: `Keep walking...` };
    }

    /**
     * Retrieves comprehensive gamification stats for the User HUD.
     */
    static async getUserStats(userId: string) {
        // Parallel Fetch for Performance
        const [profileRes, comboRes, badgesRes] = await Promise.all([
            supabase.from('profiles').select('reputation_points, faction, trust_score').eq('id', userId).single(),
            supabase.from('user_combos').select('current_combo, max_combo').eq('user_id', userId).single(),
            supabase.from('user_badges').select('badge_id, earned_at').eq('user_id', userId)
        ]);

        return {
            reputation: profileRes.data?.reputation_points || 0,
            faction: profileRes.data?.faction || 'NEUTRAL',
            trustScore: profileRes.data?.trust_score || 1.0,
            combo: {
                current: comboRes.data?.current_combo || 0,
                max: comboRes.data?.max_combo || 0
            },
            badges: badgesRes.data || []
        };
    }
}
