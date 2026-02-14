import { LRUCache } from 'lru-cache';

const options = {
  max: 500, // Max 500 items
  ttl: 1000 * 60 * 1, // 1 minute TTL
};

export const cache = new LRUCache(options);

export class CacheService {
    static get(key: string) {
        return cache.get(key);
    }

    static set(key: string, value: any) {
        cache.set(key, value);
    }

    static del(key: string) {
        cache.delete(key);
    }
    
    static flush() {
        cache.clear();
    }
}
