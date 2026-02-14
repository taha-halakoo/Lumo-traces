import sinon from 'sinon';
import { supabase } from '../src/lib/supabase';

// Helper to mock the Supabase chain: .from().select().eq().single() etc.
export const mockSupabase = () => {
    const stub = sinon.stub(supabase, 'from');
    const rpcStub = sinon.stub(supabase, 'rpc');
    
    return {
        from: stub,
        rpc: rpcStub,
        restore: () => {
            stub.restore();
            rpcStub.restore();
        }
    };
};

// Generic Chain Builder for Sinon
export const createChain = (data: any, error: any = null) => {
    return {
        select: sinon.stub().returnsThis(),
        insert: sinon.stub().returnsThis(),
        update: sinon.stub().returnsThis(),
        upsert: sinon.stub().returnsThis(),
        eq: sinon.stub().returnsThis(),
        or: sinon.stub().returnsThis(),
        single: sinon.stub().returns({ data, error }),
        then: (resolve: any) => resolve({ data, error }) // Allow await
    };
};
