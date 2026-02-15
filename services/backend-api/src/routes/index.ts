import { FastifyInstance } from 'fastify';
import { traceRoutes } from './traces';
import { userRoutes } from './users';
import { friendRoutes } from './friends';
import { notificationRoutes } from './notifications';
import { gamificationRoutes } from './gamification';

export async function appRoutes(fastify: FastifyInstance) {
  fastify.register(traceRoutes, { prefix: '/traces' });
  fastify.register(userRoutes, { prefix: '/users' });
  fastify.register(friendRoutes, { prefix: '/friends' });
  fastify.register(notificationRoutes, { prefix: '/notifications' });
  fastify.register(gamificationRoutes, { prefix: '/gamification' });
  
  fastify.get('/health', async () => ({ status: 'ok', timestamp: new Date() }));
}
