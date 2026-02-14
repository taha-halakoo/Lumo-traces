import { FastifyRequest, FastifyReply } from 'fastify';
import { InterestService } from '../services/interestService';

export class AdminController {
    
    static async decayInterests(req: FastifyRequest, reply: FastifyReply) {
        const adminSecret = req.headers['x-admin-secret'];
        
        if (adminSecret !== process.env.ADMIN_SECRET) {
            return reply.code(403).send({ error: 'Unauthorized' });
        }

        try {
            await InterestService.decayAllInterests();
            return reply.send({ success: true, message: 'Decay process triggered' });
        } catch (err) {
            req.log.error(err);
            return reply.code(500).send({ error: 'Decay failed' });
        }
    }
}
