import { FastifyInstance } from 'fastify';
import { UserController } from '../controllers/userController';
import { requireAuth } from '../middleware/auth';

export async function userRoutes(fastify: FastifyInstance) {
  fastify.get('/me', { preHandler: [requireAuth] }, UserController.getMe);
  fastify.put('/me', { preHandler: [requireAuth] }, UserController.updateMe);
  
  fastify.get('/settings', { preHandler: [requireAuth] }, UserController.getSettings);
  fastify.put('/settings', { preHandler: [requireAuth] }, UserController.updateSettings);
  
  fastify.get('/leaderboard', { preHandler: [requireAuth] }, UserController.getLeaderboard);
  fastify.get('/search', { preHandler: [requireAuth] }, UserController.search);
  
  // Social Graph
  fastify.get('/friends', { preHandler: [requireAuth] }, UserController.getFriends);
  fastify.get('/requests/pending', { preHandler: [requireAuth] }, UserController.getPending);
  fastify.post('/requests', { preHandler: [requireAuth] }, UserController.sendRequest);
  fastify.post('/requests/respond', { preHandler: [requireAuth] }, UserController.respondRequest);
  
  fastify.post('/follow', { preHandler: [requireAuth] }, UserController.follow);
  fastify.post('/unfollow', { preHandler: [requireAuth] }, UserController.unfollow);
  fastify.get('/follow/:targetId', { preHandler: [requireAuth] }, UserController.getFollowStatus);

  fastify.get('/:id', { preHandler: [requireAuth] }, UserController.getProfile);
}
