import dotenv from 'dotenv';
dotenv.config();
import { createClient } from '@supabase/supabase-js';
import { v4 as uuidv4 } from 'uuid';

// Init Supabase
const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

const LONDON_LAT = 51.509364;
const LONDON_LONG = -0.128928;

async function seed() {
    console.log("🌱 Seeding Database...");

    // 1. Create Fake Users
    const users = [];
    for (let i = 0; i < 10; i++) {
        const id = uuidv4();
        // We need to insert into auth.users first usually, but for public.profiles mock:
        // Note: Real Supabase requires auth.users. We will just insert into profiles 
        // and assume RLS is bypassed or we use service role.
        // Actually, without auth.users foreign key, insert to profiles might fail if FK exists.
        // Let's check schema. yes: REFERENCES auth.users ON DELETE CASCADE.
        // So we can't easily seed users without creating real Auth users.
        // ALTERNATIVE: Insert Traces for the *current* user or a generic 'system' user if one exists.
        
        // Strategy: We will just drop traces with a random UUID for author_id 
        // IF the FK constraint allows it or if we can disable it? No.
        // We must fetch existing users.
        
        console.log("Skipping User Creation (Auth FK constraint). Using existing users if any.");
    }

    // Get an existing user to be the "Author"
    const { data: existingUsers } = await supabase.from('profiles').select('id');
    if (!existingUsers || existingUsers.length === 0) {
        console.error("❌ No users found. Sign up in the app first!");
        return;
    }
    const authorId = existingUsers[0].id;

    // 2. Create Traces
    const traceTypes = ['STANDARD', 'STORY', 'CHALLENGE', 'ORB', 'FRIEND'];
    const traces = [];
    
    for (let i = 0; i < 20; i++) {
        const lat = LONDON_LAT + (Math.random() - 0.5) * 0.02; // ~2km radius
        const long = LONDON_LONG + (Math.random() - 0.5) * 0.02;
        
        traces.push({
            author_id: authorId,
            location: `POINT(${long} ${lat})`,
            content_text: `This is a seeded trace #${i}. The world is liquid glass.`,
            type: traceTypes[Math.floor(Math.random() * traceTypes.length)],
            visibility: 'public',
            created_at: new Date().toISOString()
        });
    }

    const { error: traceError } = await supabase.from('traces').insert(traces);
    if (traceError) console.error("Error seeding traces:", traceError);
    else console.log("✅ Seeded 20 Traces around London.");

    // 3. Create Leaderboard (Update Rep)
    const { error: repError } = await supabase.from('profiles')
        .update({ reputation_points: Math.floor(Math.random() * 1000) })
        .eq('id', authorId);
        
    if (repError) console.error("Error updating rep:", repError);
    else console.log("✅ Updated Leaderboard Stats.");

    console.log("🌱 Seeding Complete.");
}

seed();
