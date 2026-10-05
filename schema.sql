-- HolyWeed POS database setup. Run once in Supabase → SQL Editor → New query → Run.

create table if not exists public.docs (
  collection text not null,
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (collection, id)
);

create index if not exists docs_tx_created_idx
  on public.docs (collection, ((data->>'createdAt')::bigint) desc)
  where collection = 'transactions';

-- Only signed-in shop devices can read or write. Nobody else, not even with the public key.
alter table public.docs enable row level security;

drop policy if exists "shop devices read"   on public.docs;
drop policy if exists "shop devices write"  on public.docs;
create policy "shop devices read"  on public.docs for select to authenticated using (true);
create policy "shop devices write" on public.docs for all    to authenticated using (true) with check (true);

revoke all on public.docs from anon;

-- Live updates across phones and tablets.
alter table public.docs replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null;
end $$;
