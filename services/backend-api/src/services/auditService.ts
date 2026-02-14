import { supabase } from '../lib/supabase';

export class AuditService {
    static async log(userId: string, action: string, table: string, recordId: string, details?: any) {
        // Fire and forget (don't block main thread)
        supabase.from('audit_logs').insert({
            user_id: userId,
            action,
            table_name: table,
            record_id: recordId,
            details
        }).then(({ error }) => {
            if (error) console.error('Audit Log Failed:', error);
        });
    }
}
