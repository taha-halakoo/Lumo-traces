import { FastifyInstance } from 'fastify';
import { supabase } from '../lib/supabase';
import { requireAuth } from '../middleware/auth';

export async function notificationRoutes(server: FastifyInstance) {
  
  // GET /notifications
  server.get('/notifications', { preHandler: requireAuth }, async (req, reply) => {
    const user = (req as any).user;

    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', user.id)
      .eq('is_read', false)
      .order('created_at', { ascending: false })
      .limit(20);

    if (error) return reply.code(500).send(error);
    return data;
  });

  // POST /notifications/:id/read
  server.post('/notifications/:id/read', { preHandler: requireAuth }, async (req, reply) => {
    const user = (req as any).user;
    const { id } = req.params as any;

    await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id)
      .eq('user_id', user.id); // Security: only mark your own as read

    return { success: true };
  });
}
