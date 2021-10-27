with archipel as (
    select transaction_date as dt,
           terminal_id as meter,
           transaction_amount * 100 as amount_ct
    from smartfolio_sti_hst.sti_hst_smartfolio_payment_transactions
    where process_flow_account_id = 49
      and transaction_status = 'COMPLETED'
      and transaction_date between '1-sep-2019' and '30-sep-2019'
      and terminal_id != 8000),
     transact as (
         select start_parking_dt as dt,
                meter_code::INT as meter,
                amount_paid_cents as amount_ct
         from street_parking_transactions
         where client_id = 49
           and start_parking_dt between '1-sep-2019' and '30-sep-2019'
           and payment_type_id = 3
         order by 1),
     left_j as (
         select distinct case when a.dt is not null and b.dt is not null then 'B'
                              else 'LO'
                             end as jc,
                         a.meter,
                         coalesce(a.dt, b.dt),
                         round(coalesce(b.amount_ct, a.amount_ct)::numeric, 2) as amount_ct
         from archipel as a left join transact as b
                                      on a.meter = b.meter
                                          and abs(EXTRACT(EPOCH FROM (a.dt - b.dt))) < 61.
                                          and abs(a.amount_ct - b.amount_ct) < 1.
         order by 2),
     right_j as (
         select distinct case when a.dt is not null and b.dt is not null then 'B'
                              else 'RO'
                             end as jc,
                         b.meter,
                         coalesce(a.dt, b.dt),
                         round(coalesce(b.amount_ct, a.amount_ct)::numeric, 2) as amount_ct
         from archipel as a right join transact as b
                                       on a.meter = b.meter
                                           and abs(EXTRACT(EPOCH FROM (a.dt - b.dt))) < 61.
                                           and abs(a.amount_ct - b.amount_ct) < 1.
         order by 2)

select * from left_j where jc = 'LO'
union all
select * from right_j where jc = 'RO'
;