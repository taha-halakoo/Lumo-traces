-- ==============================================================================
-- 001_ALGO_UPDATE.sql
-- DATE: 2026-02-07
-- DESCRIPTION: Adds decay logic to the Interest Graph
-- ==============================================================================

create or replace function decay_all_interests(decay_factor float)
returns void
language plpgsql
security definer
as $$
declare
  profile_record record;
  new_graph jsonb;
  key text;
  val float;
begin
  -- Loop through all profiles that have an interest graph
  for profile_record in select id, interests_graph from public.profiles where interests_graph is not null loop
    new_graph := '{}'::jsonb;
    
    -- Iterate keys in the jsonb
    for key, val in select * from jsonb_each_text(profile_record.interests_graph) loop
      -- Apply decay
      val := val::float * decay_factor;
      
      -- Keep if meaningful
      if val > 1.0 then
        new_graph := jsonb_set(new_graph, array[key], to_jsonb(val));
      end if;
    end loop;

    -- Update the profile
    update public.profiles set interests_graph = new_graph where id = profile_record.id;
  end loop;
end;
$$;
