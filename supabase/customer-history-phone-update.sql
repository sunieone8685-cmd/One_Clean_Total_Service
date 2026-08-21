drop function if exists public.admin_customer_history(text);

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
