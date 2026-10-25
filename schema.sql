-- JUST 1€ v0.1 — Run in Supabase SQL Editor after creating a project.
-- Enable Email/Password authentication; create one user in Authentication > Users.
-- Then manually insert that user's UUID into public.editors.
create extension if not exists pgcrypto;
create table if not exists public.editors (user_id uuid primary key references auth.users(id) on delete cascade);
create table if not exists public.offers (
 id uuid primary key default gen_random_uuid(),
 created_at timestamptz not null default now(),
 seller_name text, place_name text not null, unit_description text not null,
 unit_type text not null default 'single', terms text not null default 'regular',
 unique_note text
);
create table if not exists public.observations (
 id uuid primary key default gen_random_uuid(),
 created_by uuid not null references auth.users(id),
 offer_id uuid references public.offers(id) on delete set null,
 observed_at timestamptz not null default now(),
 item_name text not null, place_name text not null,
 unit_type text not null check (unit_type in ('single','fixed_bundle','choice_bundle','variable','service')),
 unit_description text not null, terms text not null,
 notes text, latitude double precision, longitude double precision,
 object_path text not null, price_path text not null,
 evidence_type text not null default 'direct',
 status text not null default 'draft' check(status in ('draft','published'))
);
create index if not exists observations_observed_idx on public.observations(observed_at desc);
create index if not exists observations_offer_idx on public.observations(offer_id);
create or replace function public.is_editor() returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.editors where user_id=(select auth.uid()))$$;
revoke all on function public.is_editor() from public;
grant execute on function public.is_editor() to authenticated, anon;
alter table public.editors enable row level security;
alter table public.offers enable row level security;
alter table public.observations enable row level security;
create policy "editors self read" on public.editors for select to authenticated using (user_id=(select auth.uid()));
create policy "offers public read" on public.offers for select to anon,authenticated using (true);
create policy "offers editor insert" on public.offers for insert to authenticated with check (public.is_editor());
create policy "offers editor update" on public.offers for update to authenticated using(public.is_editor()) with check(public.is_editor());
create policy "offers editor delete" on public.offers for delete to authenticated using(public.is_editor());
create policy "observations public published read" on public.observations for select to anon,authenticated using(status='published' or public.is_editor());
create policy "observations editor insert" on public.observations for insert to authenticated with check(public.is_editor() and created_by=(select auth.uid()));
create policy "observations editor update" on public.observations for update to authenticated using(public.is_editor()) with check(public.is_editor());
create policy "observations editor delete" on public.observations for delete to authenticated using(public.is_editor());
-- Public view deliberately excludes precise coordinates and draft records.
create or replace view public.archive_records with (security_invoker=true) as
select id,offer_id,observed_at,item_name,place_name,unit_type,unit_description,terms,notes,object_path,price_path,evidence_type,status
from public.observations;
grant select on public.archive_records to anon,authenticated;
-- Public photos are served from a public bucket. DO NOT upload private photos.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('evidence','evidence',true,15728640,array['image/jpeg','image/png','image/webp','image/heic','image/heif'])
on conflict (id) do nothing;
create policy "evidence public read" on storage.objects for select to anon,authenticated using(bucket_id='evidence');
create policy "evidence editor insert" on storage.objects for insert to authenticated with check(bucket_id='evidence' and public.is_editor() and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "evidence editor delete" on storage.objects for delete to authenticated using(bucket_id='evidence' and public.is_editor());
-- IMPORTANT: After user creation, run manually (replace with the user's UUID):
-- insert into public.editors(user_id) values ('YOUR-AUTH-USER-UUID');
