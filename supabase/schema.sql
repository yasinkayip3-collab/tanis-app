-- ============================================
-- TANIS APP - Supabase Veritabanı Şeması
-- supabase.com > SQL Editor'a yapıştır > Run
-- ============================================

-- UUID extension
create extension if not exists "uuid-ossp";

-- ─── USERS ───────────────────────────────────
create table public.users (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  birthdate date not null,
  gender text not null check (gender in ('Erkek', 'Kadın', 'Diğer')),
  city text not null,
  bio text default '',
  is_verified boolean default false,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  last_seen timestamp with time zone default now(),
  constraint age_check check (
    extract(year from age(birthdate)) >= 18
  )
);

-- ─── PHOTOS ──────────────────────────────────
create table public.photos (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users on delete cascade not null,
  url text not null,
  "order" int default 0,
  is_profile boolean default false,
  created_at timestamp with time zone default now()
);

-- ─── PREFERENCES ─────────────────────────────
create table public.preferences (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users on delete cascade unique not null,
  seeking_gender text default 'Fark etmez',
  age_min int default 18 check (age_min >= 18),
  age_max int default 35 check (age_max <= 60),
  purpose text default 'Arkadaşlık' check (purpose in ('Arkadaşlık', 'İlişki', 'Gezmek'))
);

-- ─── INTERESTS ───────────────────────────────
create table public.user_interests (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users on delete cascade not null,
  interest text not null,
  unique(user_id, interest)
);

-- ─── SWIPES ──────────────────────────────────
create table public.swipes (
  id uuid default uuid_generate_v4() primary key,
  from_user uuid references public.users on delete cascade not null,
  to_user uuid references public.users on delete cascade not null,
  action text not null check (action in ('like', 'dislike')),
  created_at timestamp with time zone default now(),
  unique(from_user, to_user)
);

-- ─── MATCHES ─────────────────────────────────
create table public.matches (
  id uuid default uuid_generate_v4() primary key,
  user1_id uuid references public.users on delete cascade not null,
  user2_id uuid references public.users on delete cascade not null,
  is_active boolean default true,
  matched_at timestamp with time zone default now(),
  unique(user1_id, user2_id)
);

-- ─── MESSAGES ────────────────────────────────
create table public.messages (
  id uuid default uuid_generate_v4() primary key,
  match_id uuid references public.matches on delete cascade not null,
  sender_id uuid references public.users on delete cascade not null,
  content text not null,
  type text default 'text' check (type in ('text', 'image')),
  is_read boolean default false,
  sent_at timestamp with time zone default now()
);

-- ─── REPORTS ─────────────────────────────────
create table public.reports (
  id uuid default uuid_generate_v4() primary key,
  reporter_id uuid references public.users on delete cascade not null,
  reported_id uuid references public.users on delete cascade not null,
  reason text not null,
  status text default 'pending' check (status in ('pending', 'reviewed', 'resolved')),
  created_at timestamp with time zone default now()
);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

alter table public.users enable row level security;
alter table public.photos enable row level security;
alter table public.preferences enable row level security;
alter table public.user_interests enable row level security;
alter table public.swipes enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;

-- Users: herkes görebilir, sadece kendi profilini düzenleyebilir
create policy "Users are viewable by everyone" on public.users for select using (true);
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.users for insert with check (auth.uid() = id);

-- Photos
create policy "Photos are viewable by everyone" on public.photos for select using (true);
create policy "Users manage own photos" on public.photos for all using (auth.uid() = user_id);

-- Preferences: sadece kendi
create policy "Users manage own preferences" on public.preferences for all using (auth.uid() = user_id);

-- Interests
create policy "Interests are viewable by everyone" on public.user_interests for select using (true);
create policy "Users manage own interests" on public.user_interests for all using (auth.uid() = user_id);

-- Swipes: sadece kendi
create policy "Users manage own swipes" on public.swipes for all using (auth.uid() = from_user);

-- Matches: eşleşen iki kişi görebilir
create policy "Users see own matches" on public.matches for select using (
  auth.uid() = user1_id or auth.uid() = user2_id
);

-- Messages: sadece match'deki iki kişi
create policy "Users see own messages" on public.messages for select using (
  exists (
    select 1 from public.matches
    where id = match_id
    and (user1_id = auth.uid() or user2_id = auth.uid())
  )
);
create policy "Users send messages" on public.messages for insert with check (
  auth.uid() = sender_id
);

-- ============================================
-- OTOMATİK MATCH OLUŞTURMA (Trigger)
-- ============================================
create or replace function public.check_match()
returns trigger as $$
begin
  if NEW.action = 'like' then
    if exists (
      select 1 from public.swipes
      where from_user = NEW.to_user
      and to_user = NEW.from_user
      and action = 'like'
    ) then
      insert into public.matches (user1_id, user2_id)
      values (least(NEW.from_user, NEW.to_user), greatest(NEW.from_user, NEW.to_user))
      on conflict do nothing;
    end if;
  end if;
  return NEW;
end;
$$ language plpgsql security definer;

create trigger on_swipe_insert
  after insert on public.swipes
  for each row execute procedure public.check_match();

-- ============================================
-- STORAGE BUCKET (Profil fotoğrafları)
-- ============================================
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict do nothing;

create policy "Anyone can view photos" on storage.objects
  for select using (bucket_id = 'photos');

create policy "Users upload own photos" on storage.objects
  for insert with check (bucket_id = 'photos' and auth.uid()::text = (storage.foldername(name))[1]);
