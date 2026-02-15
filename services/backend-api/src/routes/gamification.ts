import { FastifyInstance } from 'fastify';
import { GamificationService } from '../services/gamificationService';
import { requireAuth } from '../middleware/auth';

export async function gamificationRoutes(fastify: FastifyInstance) {
  
  fastify.post('/badges/check', { preHandler: [requireAuth] }, async (request, reply) => {
    const userId = (request as any).user.id;
    await GamificationService.checkBadges(userId);
    return { success: true };
  });

  fastify.get('/stats', { preHandler: [requireAuth] }, async (request, reply) => {
    const userId = (request as any).user.id;
    const stats = await GamificationService.getUserStats(userId);
    return stats;
  });

  fastify.post('/cure', { preHandler: [requireAuth] }, async (request, reply) => {
    const userId = (request as any).user.id;
    const { lat, long } = request.body as any;
    const result = await GamificationService.checkCure(userId, lat, long);
    return result;
  });
}
