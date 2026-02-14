import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../lib/supabase';

export async function requireAuth(req: FastifyRequest, reply: FastifyReply) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return reply.code(401).send({ error: 'Missing Authorization Header' });
  }

  const token = authHeader.replace('Bearer ', '');
  
  // Verify JWT via Supabase
  const { data: { user }, error } = await supabase.auth.getUser(token);

  if (error || !user) {
    return reply.code(401).send({ error: 'Invalid Token' });
  }

  // Attach user to request for downstream use
  (req as any).user = user;
}
