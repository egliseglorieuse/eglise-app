-- =====================================================================
--  Base de données de l’application de gestion d’église
--  À coller en entier dans Supabase > SQL Editor, puis cliquer sur "Run".
-- =====================================================================

-- 1. Profils : un profil par compte, avec son rôle
create table if not exists public.profiles (
  id    uuid primary key references auth.users(id) on delete cascade,
  email text,
  role  text not null default 'aucun'
        check (role in ('aucun','admin','pasteur','secretaire','tresorier'))
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email)
  on conflict do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- comptes déjà existants
insert into public.profiles (id, email)
select id, email from auth.users on conflict do nothing;

alter table public.profiles enable row level security;
drop policy if exists "lire son propre profil" on public.profiles;
create policy "lire son propre profil" on public.profiles
  for select using (id = auth.uid());
-- aucune règle de modification : seul l'administrateur change un rôle (voir LISEZMOI.md)

create or replace function public.mon_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

-- 2. Données de l'église : une ligne par rubrique
--    membres (membres, départements, groupes, mouvements, cellules, classes),
--    cultes, programmes, finances
create table if not exists public.eglise_data (
  key        text primary key check (key in ('membres','cultes','programmes','finances')),
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create or replace function public.maj_date()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists eglise_data_maj on public.eglise_data;
create trigger eglise_data_maj before update on public.eglise_data
  for each row execute function public.maj_date();

alter table public.eglise_data enable row level security;

drop policy if exists "lecture" on public.eglise_data;
create policy "lecture" on public.eglise_data for select using (
  (key in ('membres','cultes','programmes') and public.mon_role() in ('admin','pasteur','secretaire','tresorier'))
  or (key = 'finances' and public.mon_role() in ('admin','pasteur','tresorier'))
);

drop policy if exists "ajout" on public.eglise_data;
create policy "ajout" on public.eglise_data for insert with check (
  (key in ('membres','cultes','programmes') and public.mon_role() in ('admin','pasteur','secretaire'))
  or (key = 'finances' and public.mon_role() in ('admin','pasteur','tresorier'))
);

drop policy if exists "modification" on public.eglise_data;
create policy "modification" on public.eglise_data for update
using (
  (key in ('membres','cultes','programmes') and public.mon_role() in ('admin','pasteur','secretaire'))
  or (key = 'finances' and public.mon_role() in ('admin','pasteur','tresorier'))
) with check (
  (key in ('membres','cultes','programmes') and public.mon_role() in ('admin','pasteur','secretaire'))
  or (key = 'finances' and public.mon_role() in ('admin','pasteur','tresorier'))
);
-- aucune règle de suppression : les lignes ne peuvent pas être effacées depuis l'application

-- 3. Photos des programmes
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

drop policy if exists "envoi de photos" on storage.objects;
create policy "envoi de photos" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and public.mon_role() in ('admin','pasteur','secretaire'));
