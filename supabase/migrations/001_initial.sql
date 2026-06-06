-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Users table (extends Supabase auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  phone text unique,
  name text,
  monthly_budget numeric default 0,
  ads_removed boolean default false,
  biometric_enabled boolean default false,
  email text,
  email_notifications boolean default true,
  weekly_report boolean default true,
  monthly_report boolean default true,
  created_at timestamptz default now()
);

-- Transactions table
create table public.transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  amount numeric(12,2) not null check (amount > 0),
  merchant text not null,
  category text not null,
  is_credit boolean not null default false,
  account_last4 text,
  transaction_date timestamptz not null,
  raw_sms_hash text,
  source text not null check (source in ('sms', 'manual', 'aa')),
  note text,
  is_ignored boolean default false,
  is_synced boolean default false,
  created_at timestamptz default now()
);

-- Budgets table
create table public.budgets (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  category text not null,
  monthly_limit numeric(12,2) not null,
  month_year text not null,
  is_synced boolean default false,
  created_at timestamptz default now(),
  unique(user_id, category, month_year)
);

-- Enable Row Level Security
alter table public.profiles enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;

-- RLS Policies
create policy "Users see own profile"
  on public.profiles for all
  using (auth.uid() = id);

create policy "Users see own transactions"
  on public.transactions for all
  using (auth.uid() = user_id);

create policy "Users see own budgets"
  on public.budgets for all
  using (auth.uid() = user_id);

-- Indexes for performance
create index idx_transactions_user_date on public.transactions(user_id, transaction_date desc);
create index idx_transactions_category on public.transactions(user_id, category);
create index idx_transactions_hash on public.transactions(raw_sms_hash);
create index idx_budgets_user_month on public.budgets(user_id, month_year);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, phone, email, name)
  values (
    new.id,
    new.phone,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', null)
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
