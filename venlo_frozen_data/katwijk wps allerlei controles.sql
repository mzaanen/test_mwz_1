select card_type, substring(sourcefile, 18, 8), count(1) as aantal, sum(payment_amount) as totaal
from katwijk_sti_hst.sti_hst_katwijk_wps_enterprise_tra as a
where time_of_payment::date >= '23-dec-2019'
--and substring(sourcefile from 'Gemeente Katwijk (.*) ') = 'Princehaven'
--and card_type like '%Princehaven'
group by 1, 2
order by 1, 2;

select sourcefile,
       card_type,
       case when time_of_entry is null and time_of_exit is null then 'pay only' else 'both' end as paym,
       case when (payment_amount=10) then 'dagkaart' else 'nd' end as dgk,
       count(1)
from katwijk_sti_hst.sti_hst_katwijk_wps_enterprise_tra as a
where time_of_payment::date between '1-nov-2019' and '1-dec-2019'
group by 1, 2, 3, 4
order by 1, 2, 3, 4;



select count(1), sum(transaction_amount)
from katwijk_sti_hst.sti_hst_katwijk_parkeergarage_boulevard_zeezijde
where submission_mid = 2100897231
  and transaction_date = '23-dec-2019'
limit 100;

select pay_parking_dt::DATE as "Datum|DATE|120",
       garage_nm as "Parkeergarage|TEXTL|120",
       card_type_nm as "Soort parkeerder|TEXTL|120",
       var,
       count(*) as "Aantal transacties|INTCS|120",
       sum(case when total_eur_incl_vat > 0 then 1 else 0 end) as "Aantal betalingen|INTCS|120",
       sum(total_eur_incl_vat)                                 as "Totaalbedrag (incl. btw)|EUR02|120"
from garage_parking_transactions t
         left join garage_parking_card_type gpct on t.card_type_id = gpct.id and gpct.client_id = t.client_id
         left join garage_parking_garage gpg on t.client_id = gpg.client_id and t.garage_id = gpg.id
where t.client_id = 17
  --and gpg.garage_nm = 'Princehaven'
  and pay_parking_dt::date between '1-dec-2019' and '31-dec-2019'
group by 1, 2, 3, 4

union

select time_of_payment::DATE as "Datum|DATE|120",
       'Princehaven',
       'kp',
       'weekkaart uit wps',
       count(1),
       sum(case when payment_amount > 0 then 1 else 0 end) as "Aantal betalingen|INTCS|120",
       sum(payment_amount)                                 as "Totaalbedrag (incl. btw)|EUR02|120"
from katwijk_sti_hst.sti_hst_katwijk_wps_enterprise_tra t
where coalesce(entry_station, exit_station, 'xx') not like 'ParkID%'
  and coalesce(entry_station, exit_station, payment_station) like '%PR%'
  and lower(sourcefile) not like '%kustwerk%'
  and card_type like 'Weekkaart%'
  and time_of_payment::DATE between '1-nov-2019' and '31-dec-2019'
group by 1,2,3,4
order by 1 desc, 2, 3,4;




select a.time_of_payment
     , a.payment_amount
     , case when substring(a.sourcefile, 18, 8) = 'Kustwerk' then 'Kustwerk'
            when substring(a.sourcefile, 18, 8) = 'Princeha' and substring(a.card_type from '.* (.*)') = 'Princehaven' then 'Princehaven'
            when substring(a.sourcefile, 18, 8) = 'Princeha' and substring(a.card_type from '.* (.*)') = 'Tramstraat' then 'Tramstraat'
            else 'raar'
    end as garage
     , 'wps' as source
from katwijk_sti_hst.sti_hst_katwijk_wps_enterprise_tra as a
where time_of_payment::date between '1-oct-2019' and '13-nov-2019'
  and a.payment_amount != 0
  and not exists(select 1
                 from katwijk_sti_hst.sti_hst_katwijk_parkeergarage_boulevard_zeezijde as b
                 where b.transaction_date + b.transaction_time between (a.time_of_payment - interval '240' second) and a.time_of_payment
                   and b.transaction_amount = a.payment_amount
                   and ((b.submission_mid = 2100893482 and substring(a.sourcefile, 18, 8) = 'Kustwerk') or
                        (b.submission_mid = 2100897231 and substring(a.sourcefile, 18, 8) = 'Princeha' and substring(a.card_type from '.* (.*)') = 'Princehaven') or
                        (b.submission_mid = 2100897232 and substring(a.sourcefile, 18, 8) = 'Princeha' and substring(a.card_type from '.* (.*)') = 'Tramstraat'))
    )
union
select b.transaction_date + b.transaction_time
     , b.transaction_amount
     , case when submission_mid = 2100893482 then 'Kustwerk'
            when submission_mid = 2100897231 then 'Princehaven'
            when submission_mid = 2100897232 then 'Tramstraat'
            else 'raar' end as garage
     , 'iMerch' as source
from katwijk_sti_hst.sti_hst_katwijk_parkeergarage_boulevard_zeezijde as b
where transaction_date between '1-oct-2019' and '13-nov-2019'
  and not exists(select 1
                 from katwijk_sti_hst.sti_hst_katwijk_wps_enterprise_tra as a
                 where b.transaction_date + b.transaction_time between (a.time_of_payment - interval '240' second) and a.time_of_payment
                   and b.transaction_amount = a.payment_amount
                   and ((b.submission_mid = 2100893482 and substring(a.sourcefile, 18, 8) = 'Kustwerk') or
                        (b.submission_mid = 2100897231 and substring(a.sourcefile, 18, 8) = 'Princeha' and substring(a.card_type from '.* (.*)') = 'Princehaven') or
                        (b.submission_mid = 2100897232 and substring(a.sourcefile, 18, 8) = 'Princeha' and substring(a.card_type from '.* (.*)') = 'Tramstraat'))
    )
order by 1, 2;






select count(*),
       round(sum(payment_amount)::numeric,2) as payment_amount,
       time_of_entry notnull as "Entry",
       time_of_payment notnull as "Payment",
       time_of_exit notnull as "Exit",
       id_transaction notnull as "Transaction_ID",
       card_type notnull as "Card_type",
       case
           when lower(sourcefile) like '%kustwerk%' then 'Boulevard Zeezijde'
           when coalesce(entry_station, exit_station, payment_station) like '%TR%' then 'Tramstraat'
           when coalesce(entry_station, exit_station, payment_station) like '%PR%' then 'Princehaven'
           else coalesce(entry_station, exit_station, payment_station)
           end as garage,
       case when card_type isnull then 'Abonnement'
            else card_type
           end as card_type,
       case when payment_method isnull and payment_station isnull then 'geen betaling'
            when payment_method isnull then 'geen betaling, wel payment_station'
            else payment_method
           end as payment_method,
       number_plate notnull as "Number_plate"
from katwijk_sti_hst.sti_hst_katwijk_wps_enterprise_tra
where coalesce(time_of_entry, time_of_payment, time_of_exit) >= '1-jan-2019'
group by 3,4,5,6,7,8,9,10,11
order by 1 desc;



select payment_amount,
       time_of_entry,
       time_of_payment,
       time_of_exit,
       id_transaction,
       card_type,
       case
           when lower(sourcefile) like '%kustwerk%' then 'Boulevard Zeezijde'
           when coalesce(entry_station, exit_station, payment_station) like '%TR%' then 'Tramstraat'
           when coalesce(entry_station, exit_station, payment_station) like '%PR%' then 'Princehaven'
           else coalesce(entry_station, exit_station, payment_station)
           end as garage,
       card_type,
       payment_method,
       sourcefile
from katwijk_sti_hst.sti_hst_katwijk_wps_enterprise_tra
where coalesce(time_of_entry, time_of_payment, time_of_exit) >= '1-jan-2019'
  and  payment_method isnull and payment_station is not null
order by coalesce(time_of_entry, time_of_payment, time_of_exit) desc
limit 100;

select *
from sti_hst_zwolle_wps_enterprise_tra
where time_of_entry::date != time_of_payment::date
limit 10;

select * --max(time_of_entry)
from sti_hst_katwijk_wps_enterprise_tra
where time_of_entry::date != time_of_payment::date
limit 10;