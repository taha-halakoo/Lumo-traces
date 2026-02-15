import { FastifyInstance } from 'fastify';
import { TraceController } from '../controllers/traceController';
import { requireAuth } from '../middleware/auth';

export async function traceRoutes(fastify: FastifyInstance) {
  // Public / Semi-public
  fastify.get('/nearby', { preHandler: [requireAuth] }, TraceController.getNearby);
  fastify.get('/feed', { preHandler: [requireAuth] }, TraceController.getFeed);
  fastify.get('/discovery', { preHandler: [requireAuth] }, TraceController.getDiscovery);
  fastify.get('/:id', { preHandler: [requireAuth] }, TraceController.getDetails);

  // Authenticated Actions
  fastify.post('/', { preHandler: [requireAuth] }, TraceController.create);
  fastify.post('/:id/unlock', { preHandler: [requireAuth] }, TraceController.unlock);
  fastify.post('/:id/like', { preHandler: [requireAuth] }, TraceController.like);
  fastify.post('/:id/comment', { preHandler: [requireAuth] }, TraceController.comment);
  fastify.post('/:id/infect', { preHandler: [requireAuth] }, TraceController.infect);
  fastify.post('/:id/report', { preHandler: [requireAuth] }, TraceController.report);
  
  // User specific
  fastify.get('/me', { preHandler: [requireAuth] }, TraceController.getMyTraces);
  fastify.get('/user/:userId', { preHandler: [requireAuth] }, TraceController.getUserTraces);
}
