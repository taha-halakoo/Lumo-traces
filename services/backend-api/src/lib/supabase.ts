import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

// We use explicit fallbacks to prevent the Supabase client from throwing an error 
// during initialization in CI/Test environments where secrets are not available.
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://placeholder.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || 'placeholder-key';

if (SUPABASE_URL === 'https://placeholder.supabase.co' || SUPABASE_SERVICE_KEY === 'placeholder-key') {
  // Only warn if we are NOT in a test environment, to keep test logs clean.
  // However, since we might run integration tests locally without env vars (which skips them),
  // we can suppress this warning in 'test' mode.
  if (process.env.NODE_ENV !== 'test') {
    console.warn('⚠️ Missing SUPABASE_URL or SUPABASE_SERVICE_KEY environment variables. Using placeholder strings.');
  }
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
