delete from public.onstreet_cash_transport_vs_tickets_explained
where client_id = 49;

with m_range AS (SELECT generate_series('1jan2019', now()::date - INTERVAL '1' MONTH, '1 month'::interval) as start_of_month),

     average_time_in_date_collection as (
         -- als we voor een cash transport geen TA bonnetje hebben (en dus geen exacte tijd),
         -- dan een gemiddelde nemen van de tickets van run van die dag
         select client_id,
                collection_dt::date as collection_date,
                to_timestamp(avg(extract(epoch from collection_dt))) as avg_collection_time,
                count(1) as nr
         from onstreet_collections
         where client_id = 49
           and collection_dt >= '1-jul-2018'
         group by 1,2
     ),

     onstreet_collections_rank_wise as (
         -- we willen geen last hebben van meerdere collecties op een dag,
         -- dus neem de laatste qua tijd en tel alle bedragen op
         select client_id,
                meter_code,
                collection_dt::date as collection_date,
                max(collection_dt) as collection_dt,
                sum(coalesce(amount_ct,0)) as amount_ct,
                min(collection_nr) as collection_nr
         from public.onstreet_collections
         where client_id = 49
           and collection_dt >= '1-jul-2018'
         group by 1, 2, 3
     ),

     modified_cash_transport_pre as (
         -- cash transport met zo goed mogelijk ingeschatte tijd erbij (meestal exact omdat er ook data is van Parfolio),
         -- en geen last meer van rank gedoe. Dit is een pre, omdat we in volgende stap nog even de collection_prev_dt
         -- gaan bepalen, dat lukt niet overzichtelijk in deze stap
         select aa.client_id,
                aa.meter_code,
                aa.transport_d,
                -- bb.collection_dt as collection_dt_with_possible_null_values,
                aa.payment_type_id,
                coalesce(bb.collection_dt, cc.avg_collection_time, aa.transport_d + interval '11 hours') as collection_dt,
                aa.amount_ct  as cash_transport_amount_ct,
                -- bb.amount_ct  as collection_amount_ct,
                aa.cash_transport_info
         from onstreet_cash_transport as aa
                  left join onstreet_collections_rank_wise as bb on aa.meter_code = bb.meter_code
             and aa.transport_d::date = bb.collection_date
             and bb.client_id = 49
                  left join average_time_in_date_collection as cc on aa.client_id = cc.client_id
             and aa.transport_d::date = cc.collection_date
         where aa.client_id = 49
           and aa.transport_d > '1-jul-2018'
     ),

     modified_cash_transport as (
         select *,
                lag(collection_dt) over (partition by client_id, meter_code  order by collection_dt) as collection_prev_dt
         from modified_cash_transport_pre
     ),

     cash_transactions as (
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

     ticket_value_between_g4s_collections as (
         SELECT a.client_id,
                a.meter_code,
                a.collection_prev_dt,
                a.collection_dt,
                a.cash_transport_amount_ct/100. as g4s_transport_amount,
                SUM((coalesce(b.amount_paid_cents,0) / 100.) :: NUMERIC(12, 2)) AS total_tickets_amount_between_2_collections,
                a.cash_transport_info
         FROM modified_cash_transport AS a
                  left JOIN cash_transactions AS b ON a.client_id = b.client_id
             AND a.meter_code = b.meter_code
             AND b.start_parking_dt >= COALESCE(a.collection_prev_dt, '1jan2000')
             AND b.start_parking_dt < a.collection_dt
             AND b.client_id = 49
             AND a.payment_type_id = 1
             AND a.collection_dt > '1-jul-2018'
         GROUP BY 1, 2, 3, 4, 5, 7
     ),

     with_collection_data as (
         select coalesce(a.client_id, b.client_id) as client_id,
                coalesce(a.meter_code, b.meter_code) as meter_code,
                coalesce(a.collection_dt, b.collection_dt) as sort_dt,
                a.collection_prev_dt,
                a.collection_dt,
                a.g4s_transport_amount,
                a.total_tickets_amount_between_2_collections,
                a.g4s_transport_amount - total_tickets_amount_between_2_collections as verschil_g4s_tickets,
                a.cash_transport_info,
                b.collection_dt as automaat_colletie_dt,
                b.amount_ct/100 as bonbedrag,
                coalesce(a.g4s_transport_amount,0) - coalesce(b.amount_ct/100, 0) as verschil_g4s_bonbedrag,
                b.collection_nr as bonnummer
         from ticket_value_between_g4s_collections as a
                  full outer join onstreet_collections_rank_wise as b on  a.meter_code = b.meter_code and a.collection_dt::date = b.collection_dt::date
     )

insert into public.onstreet_cash_transport_vs_tickets_explained
select client_id,
       meter_code,
       sort_dt::timestamp without time zone as sort_dt,
       collection_prev_dt::timestamp without time zone as "vorige G4S collectie datum",
       collection_dt::timestamp without time zone as "G4 collectie datum",
       g4s_transport_amount as "G4S bedrag",
       total_tickets_amount_between_2_collections as "Ticket bedrag tussen collecties",
       verschil_g4s_tickets as "Verschil bedrag",
       cash_transport_info as "Zegelnummer G4S",
       automaat_colletie_dt::timestamp without time zone as automaat_collectie_dt,
       bonbedrag,
       verschil_g4s_bonbedrag,
       bonnummer
from with_collection_data
where sort_dt >= '1-jan-2019'
order by 1, 2, 3