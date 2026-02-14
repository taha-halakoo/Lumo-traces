import { supabase } from '../lib/supabase';
import { CacheService } from './cacheService';

export class FeatureFlagService {
    static async getAllFlags() {
        const cached = CacheService.get('feature_flags');
        if (cached) return cached;

        const { data, error } = await supabase.from('feature_flags').select('key, is_enabled');
        
        if (error) {
            console.error('Error fetching flags:', error);
            return {}; // Fallback
        }

        const flags = data.reduce((acc, curr) => {
            acc[curr.key] = curr.is_enabled;
            return acc;
        }, {} as Record<string, boolean>);

        CacheService.set('feature_flags', flags); // Cache for 1 min (default TTL)
        return flags;
    }
}
