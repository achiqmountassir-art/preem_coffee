-- PREEM COFFEE order foundation
-- Paste this into Supabase → SQL Editor and run it once.
-- Does not seed the customer menu. Products stay empty until a later migration.

create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type public.order_status as enum (
      'pending',
      'accepted',
      'preparing',
      'ready',
      'completed',
      'cancelled'
    );
  end if;
end
$$;

create sequence if not exists public.order_number_seq;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  price numeric(10, 2) not null check (price >= 0),
  category text not null,
  image_url text,
  available boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique default ('PC-' || lpad(nextval('public.order_number_seq')::text, 6, '0')),
  status public.order_status not null default 'pending',
  total numeric(10, 2) not null check (total >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid references public.products (id) on delete restrict,
  product_name text not null,
  price numeric(10, 2) not null check (price >= 0),
  quantity integer not null check (quantity > 0)
);

create index if not exists products_category_idx on public.products (category);
create index if not exists products_available_idx on public.products (available);
create index if not exists orders_status_idx on public.orders (status);
create index if not exists orders_created_at_idx on public.orders (created_at desc);
create index if not exists order_items_order_id_idx on public.order_items (order_id);
create index if not exists order_items_product_id_idx on public.order_items (product_id);

comment on column public.order_items.product_id is
  'Nullable until the hardcoded Flutter menu is migrated into products.';

alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists "products_public_read_available" on public.products;
create policy "products_public_read_available"
on public.products
for select
to anon, authenticated
using (available = true);

-- No INSERT/UPDATE/DELETE policies on products, orders, or order_items.
-- Table Editor / SQL Editor (postgres + service_role) still work because those
-- roles bypass RLS. Guest checkout goes through place_pending_order only.

create or replace function public.place_pending_order(p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item jsonb;
  v_order_id uuid;
  v_order_number text;
  v_total numeric(10, 2) := 0;
  v_quantity integer;
  v_price numeric(10, 2);
  v_name text;
  v_product_id uuid;
  v_created_at timestamptz;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'order must contain at least one item';
  end if;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_name := nullif(trim(v_item->>'product_name'), '');
    v_quantity := (v_item->>'quantity')::integer;
    v_price := (v_item->>'price')::numeric;

    if v_name is null then
      raise exception 'each item needs a product_name';
    end if;
    if v_quantity is null or v_quantity < 1 then
      raise exception 'each item needs a quantity of at least 1';
    end if;
    if v_price is null or v_price < 0 then
      raise exception 'each item needs a non-negative price';
    end if;

    v_total := v_total + (v_price * v_quantity);
  end loop;

  insert into public.orders (status, total)
  values ('pending', v_total)
  returning id, order_number, created_at
  into v_order_id, v_order_number, v_created_at;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_product_id := nullif(v_item->>'product_id', '')::uuid;
    v_name := trim(v_item->>'product_name');
    v_quantity := (v_item->>'quantity')::integer;
    v_price := (v_item->>'price')::numeric;

    if v_product_id is not null and not exists (
      select 1 from public.products where id = v_product_id
    ) then
      raise exception 'unknown product_id %', v_product_id;
    end if;

    insert into public.order_items (order_id, product_id, product_name, price, quantity)
    values (v_order_id, v_product_id, v_name, v_price, v_quantity);
  end loop;

  return jsonb_build_object(
    'id', v_order_id,
    'order_number', v_order_number,
    'status', 'pending',
    'total', v_total,
    'created_at', v_created_at
  );
end;
$$;

revoke all on function public.place_pending_order(jsonb) from public;
grant execute on function public.place_pending_order(jsonb) to anon, authenticated;
