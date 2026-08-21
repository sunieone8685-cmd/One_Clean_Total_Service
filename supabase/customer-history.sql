create table if not exists public.customer_notes (
  name text not null,
  address text not null,
  note text not null default '',
  updated_at timestamptz not null default now(),
  primary key (name, address)
);

alter table public.customer_notes enable row level security;

create or replace function public.admin_customer_history(p_password text)
returns table(name text, phone text, address text, visit_count bigint, service_dates date[], note text)
language sql security definer set search_path = public as $$
  with completed_customers as (
    select b.name, (array_agg(b.phone order by b.booking_date desc))[1] as phone, b.address,
           count(*)::bigint as visit_count,
           array_agg(b.booking_date order by b.booking_date desc) as service_dates
    from public.bookings b
    where p_password = '8685'
      and b.completed = true
      and btrim(coalesce(b.address, '')) <> ''
    group by b.name, b.address
  )
  select c.name, c.phone, c.address, c.visit_count, c.service_dates,
         coalesce(n.note, '') as note
  from completed_customers c
  left join public.customer_notes n on n.name = c.name and n.address = c.address
  order by c.name, c.address;
$$;

create or replace function public.admin_save_customer_note(p_name text, p_address text, p_note text, p_password text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if p_password <> '8685' or btrim(coalesce(p_name, '')) = '' or btrim(coalesce(p_address, '')) = '' then
    return false;
  end if;
  insert into public.customer_notes (name, address, note, updated_at)
  values (btrim(p_name), btrim(p_address), coalesce(p_note, ''), now())
  on conflict (name, address) do update
    set note = excluded.note, updated_at = now();
  return true;
end;
$$;

grant execute on function public.admin_customer_history(text) to anon, authenticated;
grant execute on function public.admin_save_customer_note(text,text,text,text) to anon, authenticated;
