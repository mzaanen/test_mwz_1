-- WITH c (garage_nm, apparatuur, start_dt, end_dt, count_cars) as
--          (VALUES ('Citadel'       , 'SenB', '2020-06-10 08:27' :: TIMESTAMP, '2020-06-10 08:42' :: TIMESTAMP, 193),
--                  ('De Nieuwe Kolk',   'IP', '2020-06-11 08:48' :: TIMESTAMP, '2020-06-11 08:51' :: TIMESTAMP, 76),
--                  ('Drents Museum' ,   'IP', '2020-06-10 14:18' :: TIMESTAMP, '2020-06-10 14:23' :: TIMESTAMP, 140),
--                  ('Mercurius'     , 'SenB', '2020-06-10 08:47' :: TIMESTAMP, '2020-06-10 08:50' :: TIMESTAMP, 27),
--                  ('Neptunus'      ,   'IP', '2020-06-10 10:02' :: TIMESTAMP, '2020-06-10 10:05' :: TIMESTAMP, 28),
--                  ('Stadhuis'      , 'SenB', '2020-06-10 10:40' :: TIMESTAMP, '2020-06-10 10:45' :: TIMESTAMP, 128),
--                  ('Triade'        ,   'IP', '2020-06-11 18:27' :: TIMESTAMP, '2020-06-11 18:30' :: TIMESTAMP, 24)
--          )

-- WITH c (garage_nm, apparatuur, start_dt, end_dt, count_cars) as
--          (VALUES ('Citadel'       , 'SenB', '2020-06-17 19:18':: TIMESTAMP, '2020-06-17 19:24':: TIMESTAMP, 173),
--                  ('De Nieuwe Kolk',   'IP', '2020-06-16 13:22':: TIMESTAMP, '2020-06-16 13:31':: TIMESTAMP, 152),
--                  ('Drents Museum' ,   'IP', '2020-06-15 14:07':: TIMESTAMP, '2020-06-15 14:10':: TIMESTAMP,  78),
--                  ('Mercurius'     , 'SenB', '2020-06-15 10:16':: TIMESTAMP, '2020-06-15 10:20':: TIMESTAMP,  24),
--                  ('Neptunus'      ,   'IP', '2020-06-15 18:35':: TIMESTAMP, '2020-06-15 18:37':: TIMESTAMP,   6),
--                  ('Stadhuis'      , 'SenB', '2020-06-17 09:29':: TIMESTAMP, '2020-06-17 09:32':: TIMESTAMP, 108),
--                  ('Triade '       ,   'IP', '2020-06-15 18:39':: TIMESTAMP, '2020-06-15 18:42':: TIMESTAMP,  21)
--          )


WITH c (garage_nm, apparatuur, start_dt, end_dt, count_cars) as
         (VALUES ('Citadel'        , 'SenB', '2020-07-03 10:15':: TIMESTAMP, '2020-07-03 10:21':: TIMESTAMP, 207),
                 ('De Nieuwe Kolk' ,   'IP', '2020-07-02 14:34':: TIMESTAMP, '2020-07-02 14:40':: TIMESTAMP, 183),
                 ('Drents Museum'  ,   'IP', '2020-06-30 11:25':: TIMESTAMP, '2020-06-30 11:29':: TIMESTAMP, 128),
                 ('Mercurius'      , 'SenB', '2020-07-02 20:12':: TIMESTAMP, '2020-07-02 20:13':: TIMESTAMP,  86),
                 ('Neptunus'       ,   'IP', '2020-07-02 20:12':: TIMESTAMP, '2020-07-02 20:13':: TIMESTAMP,   9),
                 ('Neptunus Rabo'  ,   'IP', '2020-07-03 20:13':: TIMESTAMP, '2020-07-03 20:14':: TIMESTAMP,  23),
                 ('Stadhuis'       , 'SenB', '2020-07-03 09:19':: TIMESTAMP, '2020-07-03 09:21':: TIMESTAMP,  77),
                 ('Triade'         ,   'IP', '2020-07-03 09:04':: TIMESTAMP, '2020-07-03 09:07':: TIMESTAMP,  53)
    )


select garage.garage_nm                          as "Parkeergarage",
       c.apparatuur,
       to_char(c.start_dt, 'YYYY-MM-DD HH24:MI') as "Start telling",
       to_char(c.end_dt, 'YYYY-MM-DD HH24:MI')   as "Eind telling",
       t2.card_type_nm,
       gt.completeness_transaction,
       c.count_cars                              as "Aantal getelde voertuigen",
       count(*)                                  as "Totaal aantal transacties (deels) in meetmoment",
       sum(case when phone_amount != 0 then 1 else 0 end) as "Telefoon",
       sum(case when start_parking_dt >= c.start_dt then 1 else 0 end) as "Parkeerdata: In tijdens meting",
       sum(case when coalesce(end_parking_dt, pay_parking_dt) <= c.end_dt then 1 else 0 end)     as "Parkeerdata: Uit tijdens meting",
       sum(case when start_parking_dt <= c.start_dt then 1 else 0 end) as "Parkeerdata: Stand begin meting",
       sum(case when coalesce(end_parking_dt, pay_parking_dt) >= c.end_dt then 1 else 0 end)     as "Parkeerdata: Stand eind meting"
from garage_parking_transactions gt
     inner join garage_parking_garage garage on gt.client_id = garage.client_id and gt.garage_id = garage.id
     left join garage_parking_card_type t2 on gt.card_type_id = t2.id
     -- Filter op alle transacties die zijn in en/of uitgereden tijdens het meetmoment
     inner join c on garage.garage_nm = c.garage_nm and gt.start_parking_dt <= c.end_dt and coalesce(end_parking_dt, pay_parking_dt) >= c.start_dt
where gt.client_id = 61
group by 1, 2, 3, 4, 5, 6,7
order by 1, 2, 3, 4, 5, 6,7;

select garage.garage_nm,
       t2.card_type_nm,
       gt.*
from garage_parking_transactions as gt
inner join garage_parking_garage garage on gt.client_id = garage.client_id and gt.garage_id = garage.id
inner join garage_parking_card_type t2 on gt.card_type_id = t2.id
where (t2.card_type_nm = 'Abonnement' or gt.phone_amount !=0)
and gt.client_id = 61
and garage.garage_nm = 'Stadhuis'
and coalesce(gt.start_parking_dt, gt.pay_parking_dt, gt.end_parking_dt)::date = '3-jul-2020'
order by coalesce(gt.start_parking_dt, gt.pay_parking_dt, gt.end_parking_dt)
limit 100;


WITH c (garage_nm, apparatuur, start_dt, end_dt, count_cars) as
         (VALUES ('Citadel'        , 'SenB', '2020-07-03 10:15':: TIMESTAMP, '2020-07-03 10:21':: TIMESTAMP, 207),
                 ('De Nieuwe Kolk' ,   'IP', '2020-07-02 14:34':: TIMESTAMP, '2020-07-02 14:40':: TIMESTAMP, 183),
                 ('Drents Museum'  ,   'IP', '2020-06-30 11:25':: TIMESTAMP, '2020-06-30 11:29':: TIMESTAMP, 128),
                 ('Mercurius'      , 'SenB', '2020-07-02 20:12':: TIMESTAMP, '2020-07-02 20:13':: TIMESTAMP,  86),
                 ('Neptunus'       ,   'IP', '2020-07-02 20:12':: TIMESTAMP, '2020-07-02 20:13':: TIMESTAMP,   9),
                 ('Neptunus Rabo'  ,   'IP', '2020-07-03 20:13':: TIMESTAMP, '2020-07-03 20:14':: TIMESTAMP,  23),
                 ('Stadhuis'       , 'SenB', '2020-07-03 09:19':: TIMESTAMP, '2020-07-03 09:21':: TIMESTAMP,  77),
                 ('Triade'         ,   'IP', '2020-07-03 09:04':: TIMESTAMP, '2020-07-03 09:07':: TIMESTAMP,  53)
         )
select c.apparatuur,
       garage.garage_nm,
       t2.card_type_nm,
       gt.completeness_transaction,
       count(1) as aantal,
       sum(case when phone_amount != 0 then 1 else 0 end) as "Mobiel"
--        sum(case when coalesce(total_eur_incl_vat,0) = 0 then 1 else 0 end) as "nul betalingen"
from garage_parking_transactions as gt
         left join garage_parking_garage garage on gt.client_id = garage.client_id and gt.garage_id = garage.id
         left join garage_parking_card_type t2 on gt.card_type_id = t2.id
         left join c on garage.garage_nm = c.garage_nm
where gt.client_id = 61
--and c.apparatuur = 'SenB'
-- and phone_amount !=0
--   and garage.garage_nm = 'Stadhuis'
  and coalesce(gt.start_parking_dt, gt.pay_parking_dt, gt.end_parking_dt)::date = '3-jul-2020'
group by 1,2,3,4
order by 1,2,3,4;


with nrs as (
    select y
    from (values (1374221),
                 (1374245),
                 (1733876),
                 (1374250),
                 (1374258),
                 (1374262),
                 (1374263),
                 (1374271),
                 (1374272),
                 (1374281),
                 (1374293),
                 (1374297),
                 (1374304),
                 (1374408),
                 (1734218),
                 (1374448),
                 (1374455),
                 (1374558),
                 (1374622),
                 (1374643),
                 (1374688),
                 (1734660),
                 (1374711),
                 (1734704),
                 (1374738),
                 (1734708),
                 (1374739),
                 (1374765),
                 (1734769),
                 (1374768),
                 (1374806),
                 (1734875),
                 (1374814),
                 (1374863),
                 (1374869),
                 (1374897),
                 (1374898),
                 (1735044),
                 (1374908),
                 (1374923),
                 (1735071),
                 (1374929),
                 (1735162),
                 (1374984),
                 (1374996),
                 (1375032),
                 (1735326),
                 (1375089),
                 (1735435),
                 (1375152),
                 (1735507),
                 (1375181),
                 (1735556),
                 (1375201),
                 (1375204),
                 (1375205),
                 (1735771),
                 (1375312),
                 (1375362),
                 (1375392),
                 (1375404),
                 (1375452),
                 (1375583),
                 (1375673),
                 (1375781),
                 (1375798),
                 (1375809)
         ) as x(y)
)

select a.y,
       z.*
from
nrs as a
left join assen_sti_hst.sti_hst_assen_sb_par_parking_trans as z on coalesce(z.parkingnumber, '0')::integer = a.y
order by a.y;