-- À exécuter dans Supabase : SQL Editor > New query

create table evenements (
    id uuid primary key default gen_random_uuid(),
    date date not null,
    heure_debut time not null,
    heure_fin time not null,
    titre text not null,
    lien text,
    image text,
    created_at timestamptz not null default now()
);

alter table evenements enable row level security;

-- Tout le monde peut lire les évènements (site public)
create policy "Lecture publique des évènements"
    on evenements for select
    to anon
    using (true);

-- Seuls les utilisateurs connectés (admin) peuvent ajouter/modifier/supprimer
create policy "Ecriture reservee aux utilisateurs connectes"
    on evenements for all
    to authenticated
    using (true)
    with check (true);

-- Migration : si la table "evenements" existe déjà sans la colonne "image"
alter table evenements add column if not exists image text;

-- Migration : si la table "evenements" existe déjà sans la colonne "description"
alter table evenements add column if not exists description text;

-- Bucket de stockage pour les images des évènements
insert into storage.buckets (id, name, public)
values ('evenements', 'evenements', true)
on conflict (id) do nothing;

create policy "Lecture publique des images d'évènements"
    on storage.objects for select
    to anon
    using (bucket_id = 'evenements');

create policy "Upload reserve aux utilisateurs connectes"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'evenements');

create policy "Suppression reservee aux utilisateurs connectes"
    on storage.objects for delete
    to authenticated
    using (bucket_id = 'evenements');

-- Paramètres généraux du site (une seule ligne, id fixe à 1)
create table if not exists site_settings (
    id int primary key default 1,
    bandeau_evenement_actif boolean not null default false,
    constraint site_settings_singleton check (id = 1)
);

insert into site_settings (id) values (1) on conflict (id) do nothing;

alter table site_settings enable row level security;

-- Tout le monde peut lire les paramètres (site public)
create policy "Lecture publique des paramètres du site"
    on site_settings for select
    to anon
    using (true);

-- Les utilisateurs connectés (admin) doivent aussi pouvoir les lire
-- (sinon le switch de la page admin ne peut pas afficher l'état actuel)
create policy "Lecture pour les utilisateurs connectes"
    on site_settings for select
    to authenticated
    using (true);

-- Seuls les utilisateurs connectés (admin) peuvent les modifier
create policy "Modification reservee aux utilisateurs connectes"
    on site_settings for update
    to authenticated
    using (true)
    with check (true);

-- Table dédiée au "ping" automatisé qui empêche la mise en pause du
-- projet Supabase par inactivité (table vide, sans donnée sensible,
-- isolée des vraies données du site).
create table if not exists keepalive (
    id int primary key default 1,
    pinged_at timestamptz not null default now(),
    constraint keepalive_singleton check (id = 1)
);

insert into keepalive (id) values (1) on conflict (id) do nothing;

alter table keepalive enable row level security;

create policy "Ping public en lecture"
    on keepalive for select
    to anon
    using (true);

create policy "Ping public en ecriture"
    on keepalive for update
    to anon
    using (true)
    with check (true);
