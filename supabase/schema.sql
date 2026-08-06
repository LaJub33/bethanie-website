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
