-- delete from public.onstreet_cash_transport_vs_tickets_per_month -- xx
-- where client_id = 49
--   and start_of_month >= '1jan2019';

with m_range AS (SELECT generate_series('1jan2019', now()::date - INTERVAL '1' MONTH, '1 month'::interval) as start_of_month),

     month_range AS (SELECT start_of_month,
                            start_of_month + INTERVAL '1 month' AS end_of_month
                     FROM m_range),

     unique_meter_codes as (
         SELECT DISTINCT client_id,
                         meter_code
         FROM street_parking_transactions
         WHERE client_id = 49
        union    -- xx
         SELECT 49, '008000'  -- f iets apparaat erbij, zit wel in
     ),

     unique_meter_codes_month as (
         SELECT client_id,
                meter_code,
                start_of_month,
                end_of_month
         FROM month_range as mr
                  INNER JOIN unique_meter_codes as um on 1=1
     ),

     average_time_in_date_collection as (
         -- als we voor een cash transport geen TA bonnetje hebben (en dus geen exacte tijd),
         -- dan een gemiddelde nemen van de tickets van run van die dag
         select client_id,
                collection_dt::date as collection_date,
                to_timestamp(avg(extract(epoch from collection_dt))) as avg_collection_time,
                count(1) as nr
         from onstreet_collections
         where client_id = 49
         group by 1,2
     ),

     onstreet_collections_rank_wise as (
         -- we willen geen last hebben van meerdere collecties op een dag,
         -- dus neem de laatste qua tijd en tel alle bedragen op
         select client_id,
                meter_code,
                collection_dt::date as collection_date,
                max(collection_dt) as collection_dt,
                sum(coalesce(amount_ct,0)) as amount_ct
         from onstreet_collections
         where client_id = 49
         group by 1, 2, 3
     ),

     modified_cash_transport_pre as (
         -- cash transport met zo goed mogelijk ingeschatte tijd erbij (meestal exact omdat er ook data is van Parkfolio),
         -- en geen last meer van rank gedoe. Dit is een pre, omdat we in volgende stap nog even de collection_prev_dt
         -- gaan bepalen, dat lukt niet overzichtelijk in deze stap
         select aa.client_id,
                aa.meter_code,
                aa.transport_d,
                bb.collection_dt as collection_dt_with_possible_null_values,
                aa.payment_type_id,
                coalesce(bb.collection_dt, cc.avg_collection_time, aa.transport_d + interval '11 hours') as collection_dt,
                aa.amount_ct  as cash_transport_amount_ct,
                bb.amount_ct  as collection_amount_ct
         from onstreet_cash_transport as aa
                  left join onstreet_collections_rank_wise as bb on aa.meter_code = bb.meter_code
             and aa.transport_d::date = bb.collection_date
             and bb.client_id = 49
                  left join average_time_in_date_collection as cc on aa.client_id = cc.client_id
             and aa.transport_d::date = cc.collection_date
         where aa.client_id = 49
           and aa.transport_d > '1jan2017'
     ),

     modified_cash_transport as (
         select *,
                lag(collection_dt) over (partition by client_id, meter_code  order by collection_dt) as collection_prev_dt
         from modified_cash_transport_pre
     ),

     last_collection_before_start_of_month as (
         SELECT mr.client_id,
                mr.meter_code,
                mr.start_of_month,
                mr.end_of_month,
                coalesce(max(oc.collection_dt), '1jan2000') as last_col_date_before_end_of_month
         FROM unique_meter_codes_month as mr
                  LEFT JOIN modified_cash_transport AS oc on mr.meter_code = oc.meter_code
             and oc.collection_dt < mr.start_of_month
             and oc.client_id = 49
         GROUP BY 1,2,3,4),

     cash_transactions as (   -- xxx
         select bb.client_id,
                bb.meter_code,
                bb.start_parking_dt,
                bb.amount_paid_cents
         from public.street_parking_transactions as bb
         where bb.client_id = 49
           and bb.payment_type_id = 1
           and bb.start_parking_dt >= '1-jan-2019'
         union
         select cc.client_id,
                lpad(cc.facility_id::text, 6, '0'),
                cc.payment_dt,
                cc.amount_eur_incl_vat*100
         from public.bicycle_parking_payments as cc
         where cc.client_id = 49
           and cc.payment_dt::date >= '1-jan-2019'
           and cc.payment_type_cid = 'CASH'
     ),

     still_present_in_apparaat_start_of_month as (
         SELECT
             a.client_id,
             a.meter_code,
             a.start_of_month,
             a.end_of_month,
             a.last_col_date_before_end_of_month,
             SUM((coalesce(b.amount_paid_cents, 0) / 100.) :: NUMERIC(12, 2)) AS tickets_amount_in_apparatus_start_of_month
         FROM last_collection_before_start_of_month AS a
                  LEFT JOIN cash_transactions AS b ON a.meter_code = b.meter_code   -- xx
         --   AND b.payment_type_id = 1   -- xx
             AND b.start_parking_dt >= COALESCE(a.last_col_date_before_end_of_month, '1jan2000') AND b.start_parking_dt < a.start_of_month
             AND b.client_id = 49  -- keep this, with this an index is used and the query
         GROUP BY 1, 2, 3, 4, 5),

     total_tickets_in_month as (
         SELECT mr.client_id,
                mr.meter_code,
                mr.start_of_month,
                SUM(coalesce(b.amount_paid_cents,0) / 100.) :: NUMERIC(12, 2) AS total_tickets_amount_in_month
         FROM unique_meter_codes_month AS mr
                  LEFT JOIN cash_transactions AS b ON mr.meter_code = b.meter_code  -- xx
         --   AND b.payment_type_id = 1   -- xx
             AND b.start_parking_dt >= mr.start_of_month AND b.start_parking_dt < mr.end_of_month
             AND b.client_id = 49  -- keep this, with this an index is used and the query

         GROUP BY 1,2,3),

     last_collection_before_end_of_month as (
         SELECT mr.client_id,
                mr.meter_code,
                mr.start_of_month,
                mr.end_of_month,
                coalesce(max(oc.collection_dt), '1jan2000') AS last_col_date_before_end_of_month
         FROM unique_meter_codes_month AS mr
                  LEFT JOIN modified_cash_transport AS oc ON mr.client_id = oc.client_id
             AND mr.meter_code = oc.meter_code
             AND oc.collection_dt < mr.end_of_month
             AND oc.client_id = 49
         GROUP BY 1,2,3,4),

     left_in_apparaat_end_of_month as (
         SELECT
             a.client_id,
             a.meter_code,
             a.start_of_month,
             a.end_of_month,
             a.last_col_date_before_end_of_month,
             SUM((coalesce(b.amount_paid_cents,0) / 100.) :: NUMERIC(12, 2)) AS tickets_amount_in_apparatus_end_of_month
         FROM last_collection_before_end_of_month as a
                  left JOIN cash_transactions AS b ON a.client_id = b.client_id  -- xx
             AND a.meter_code = b.meter_code
             --AND b.payment_type_id = 1  --xx
             AND b.start_parking_dt >= COALESCE(a.last_col_date_before_end_of_month, '1jan2000') AND b.start_parking_dt < a.end_of_month
             AND b.client_id = 49
         GROUP BY 1, 2, 3, 4, 5),

     tickets_in_month_with_cash_transport as (
         SELECT a.client_id,
                a.meter_code,
                a.collection_dt,
                a.cash_transport_amount_ct,
                SUM((coalesce(amount_paid_cents,0) / 100.) :: NUMERIC(12, 2)) AS total_tickets_amount_between_2_collections,
                SUM(case when b.start_parking_dt < date_trunc('MONTH', a.collection_dt) then (amount_paid_cents / 100.) :: NUMERIC(12, 2)else 0 end) as tickets_amount_pre_month,
                SUM(case when b.start_parking_dt >= date_trunc('MONTH', a.collection_dt) then (amount_paid_cents / 100.) :: NUMERIC(12, 2) else 0 end) as tickets_amount_current_month
         FROM modified_cash_transport AS a
                  left JOIN cash_transactions AS b ON a.client_id = b.client_id  -- xx
             AND a.meter_code = b.meter_code
             --  AND a.payment_type_id = b.payment_type_id
             AND b.start_parking_dt >= COALESCE(a.collection_prev_dt, '1jan2000')
             AND b.start_parking_dt < a.collection_dt
             AND b.client_id = 49
             AND a.payment_type_id = 1
             AND a.collection_dt > '1jan2019'
         GROUP BY 1, 2, 3, 4),

     cash_transport_tickets_per_month as (
         select client_id,
                meter_code,
                date_trunc('MONTH', collection_dt) as start_of_month,
                sum(cash_transport_amount_ct)/100. ::numeric(12,2) as cash_transport_amount_euro,  -- wat heeft G4S deze maand opgehaald
                SUM(total_tickets_amount_between_2_collections) as tickets_amount_collected_in_month,      -- wat was het bedrag van de losse tickets van alle cash transports in deze maand
                SUM(tickets_amount_pre_month) as tickets_amount_pre_month_collected,   -- welk bedrag van de tickets komen uit oude maand(en)
                SUM(tickets_amount_current_month) as tickets_amount_current_month_collected,  -- welk bedrag van de tickets komt uit deze maand
                min(collection_dt) as first_cash_transport_dt_of_month,
                max(collection_dt) as last_cash_transport_dt_of_month
         from tickets_in_month_with_cash_transport
         group by 1, 2, 3)

-- insert into public.onstreet_cash_transport_vs_tickets_per_month  --xx
select a.client_id,
       a.meter_code,
       a.start_of_month::timestamp without time zone as start_of_month,
       coalesce(d.tickets_amount_collected_in_month, 0) as tickets_amount_collected_in_month,
       coalesce(d.cash_transport_amount_euro, 0) as cash_transport_amount_euro,
       coalesce(d.cash_transport_amount_euro,0) - coalesce(d.tickets_amount_collected_in_month,0) as diff_cash_transport_tickets,
       case when d.cash_transport_amount_euro is not null
                then a.tickets_amount_in_apparatus_start_of_month - coalesce(d.tickets_amount_pre_month_collected, 0)
            else 0
           end as diff_pre_month,   -- zou altijd 0 moeten zijn, check, check, double check
       a.tickets_amount_in_apparatus_start_of_month,
       b.total_tickets_amount_in_month,
       c.tickets_amount_in_apparatus_end_of_month,
       coalesce(d.tickets_amount_current_month_collected, 0) as tickets_amount_current_month_collected,
       coalesce(d.tickets_amount_pre_month_collected, 0) as tickets_amount_pre_month_collected,
       d.first_cash_transport_dt_of_month,
       d.last_cash_transport_dt_of_month
from still_present_in_apparaat_start_of_month as a
         left join total_tickets_in_month as b on a.client_id=b.client_id
    and a.meter_code=b.meter_code
    and a.start_of_month = b.start_of_month
         left join left_in_apparaat_end_of_month  as c on a.client_id=c.client_id
    and a.meter_code=c.meter_code
    and a.start_of_month = c.start_of_month
         left join cash_transport_tickets_per_month as d on a.client_id = d.client_id
    and a.meter_code=d.meter_code
    and a.start_of_month = d.start_of_month
order by 1,2,3