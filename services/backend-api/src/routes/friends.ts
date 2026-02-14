import { FastifyInstance } from 'fastify';
import { supabase } from '../lib/supabase';
import { requireAuth } from '../middleware/auth';

export async function friendRoutes(server: FastifyInstance) {
  
  // 1. Send Friend Request
  // POST /friends/request { targetUserId: "..." }
  server.post('/friends/request', { preHandler: requireAuth }, async (req, reply) => {
    const user = (req as any).user;
    const { targetUserId } = req.body as any;

    if (user.id === targetUserId) return reply.code(400).send({ error: "Self-love is important, but not here." });

    const { error } = await supabase
      .from('friendships')
      .insert({
        user_a: user.id,
        user_b: targetUserId,
        status: 'pending'
      });

    if (error) return reply.code(500).send({ error: 'Failed to send request' });
    return { success: true };
  });

  // 2. Accept Friend Request
  // POST /friends/accept { requestId: "..." }
  server.post('/friends/accept', { preHandler: requireAuth }, async (req, reply) => {
    const { requestId } = req.body as any;
    
    // We update status to 'accepted'
    const { error } = await supabase
      .from('friendships')
      .update({ status: 'accepted' })
      .eq('id', requestId);

    if (error) return reply.code(500).send({ error: 'Update failed' });
    return { success: true };
  });

  // 3. List Friends
  // GET /friends
  server.get('/friends', { preHandler: requireAuth }, async (req, reply) => {
    const user = (req as any).user;
    
    // Complex query: get all rows where I am A or B, and status is accepted
    const { data, error } = await supabase
      .from('friendships')
      .select('*')
      .or(`user_a.eq.${user.id},user_b.eq.${user.id}`)
      .eq('status', 'accepted');

    if (error) return reply.code(500).send(error);
    return data;
  });
}
