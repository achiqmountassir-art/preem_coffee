-- Admin allowlist + secure write policies (no public product writes).
-- Also enables Realtime on public.orders.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

drop policy if exists "Admins can read own admin row" on public.admin_users;
create policy "Admins can read own admin row"
on public.admin_users
for select
to authenticated
using (auth.uid() = user_id);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users au where au.user_id = auth.uid()
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated, anon;

drop policy if exists "Admin insert products" on public.products;
create policy "Admin insert products"
on public.products for insert to authenticated
with check (public.is_admin());

drop policy if exists "Admin update products" on public.products;
create policy "Admin update products"
on public.products for update to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admin delete products" on public.products;
create policy "Admin delete products"
on public.products for delete to authenticated
using (public.is_admin());

drop policy if exists "Admin select orders" on public.orders;
create policy "Admin select orders"
on public.orders for select to authenticated
using (public.is_admin());

drop policy if exists "Admin update orders" on public.orders;
create policy "Admin update orders"
on public.orders for update to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admin select order items" on public.order_items;
create policy "Admin select order items"
on public.order_items for select to authenticated
using (public.is_admin());

drop policy if exists "Admin update order items" on public.order_items;
create policy "Admin update order items"
on public.order_items for update to authenticated
using (public.is_admin())
with check (public.is_admin());

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'orders'
  ) then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;
