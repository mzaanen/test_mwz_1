with onstreet_aggr_datetime as (
    SELECT a.client_id,
           'TA'                                AS payment_method,
           payment_type_id,
           extract(dow from a.start_parking_dt) :: int as dow,
           extract(hour from a.start_parking_dt) :: int as uur,
           c1.sectie_code_group_value          AS sectie_code_group_value_1,
           c2.sectie_code_group_value          AS sectie_code_group_value_2,
           c3.sectie_code_group_value          AS sectie_code_group_value_3,
           coalesce(b.sectie_code, ''),
           a.meter_code :: INT                 AS pos_code,
           sum(coalesce(amount_paid_cents, 0)) AS amount_ct,
           count(*)                            AS transactions,
           sum(coalesce(paid_duration_limited_sec, 0))
               AS duration_sec
    FROM street_parking_transactions a
             LEFT JOIN areaal_meter b ON a.meter_code = b.meter_code AND a.client_id = b.client_id AND
                                         a.start_parking_dt BETWEEN b.start_dt AND b.end_dt
             LEFT JOIN areaal_sectie asec
                       ON b.client_id = asec.client_id AND b.sectie_code :: TEXT = asec.sectie_code :: TEXT
             LEFT JOIN areaal_sectie_group c1
                       ON b.client_id = c1.client_id AND b.sectie_code :: TEXT = c1.sectie_code :: TEXT AND
                          a.start_parking_dt >= c1.start_dt AND
                          a.start_parking_dt <= COALESCE(c1.end_dt :: TIMESTAMP WITH TIME ZONE, now()) AND
                          c1.group_level = 1
             LEFT JOIN areaal_sectie_group c2
                       ON b.client_id = c2.client_id AND b.sectie_code :: TEXT = c2.sectie_code :: TEXT AND
                          a.start_parking_dt >= c2.start_dt AND
                          a.start_parking_dt <= COALESCE(c2.end_dt :: TIMESTAMP WITH TIME ZONE, now()) AND
                          c2.group_level = 2
             LEFT JOIN areaal_sectie_group c3
                       ON b.client_id = c3.client_id AND b.sectie_code :: TEXT = c3.sectie_code :: TEXT AND
                          a.start_parking_dt >= c3.start_dt AND
                          a.start_parking_dt <= COALESCE(c3.end_dt :: TIMESTAMP WITH TIME ZONE, now()) AND
                          c3.group_level = 3
             LEFT JOIN street_parking_payment_types d ON a.payment_type_id = d.id
    WHERE a.client_id = 39
      AND d.payment_type :: TEXT <> 'PayONE reloading' :: TEXT
      AND coalesce(asec.dummy, FALSE) is FALSE -- Dummy locaties: Eventuele (test)transacties niet rapporteren.
      AND a.start_parking_dt::date between '1-jan-2020' and '29-feb-2020'
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
    UNION ALL
    SELECT a.client_id,
           'GSM' :: CHARACTER VARYING AS payment_method,
           gsm_provider_id            AS payment_type_id,
           extract(dow from a.start_parking_dt) :: int as dow,
           extract(hour from a.start_parking_dt) :: int as uur,
           c1.sectie_code_group_value AS sectie_code_group_value_1,
           c2.sectie_code_group_value AS sectie_code_group_value_2,
           c3.sectie_code_group_value AS sectie_code_group_value_3,
           coalesce(b.sectie_code, ''),
           a.zone_code :: INT         AS pos_code,
           sum(coalesce(amount, 0))   AS amount_ct,
           count(*)                   AS transactions,
           sum(least(coalesce(a.duration_in_sec, 0), 6 * 3600))
               AS duration_sec
    FROM street_parking_gsm_transactions2 a
             LEFT JOIN areaal_sectie_gsm b
                       ON a.zone_code :: TEXT = b.gsm_code :: TEXT AND a.start_parking_dt >= b.start_dt AND
                          a.start_parking_dt <= b.end_dt AND a.client_id = b.client_id
             LEFT JOIN areaal_sectie asec
                       ON b.client_id = asec.client_id AND b.sectie_code :: TEXT = asec.sectie_code :: TEXT
             LEFT JOIN areaal_sectie_group c1
                       ON b.sectie_code :: TEXT = c1.sectie_code :: TEXT AND a.start_parking_dt >= c1.start_dt AND
                          a.start_parking_dt <= COALESCE(c1.end_dt :: TIMESTAMP WITH TIME ZONE, now()) AND
                          b.client_id = c1.client_id AND c1.group_level = 1
             LEFT JOIN areaal_sectie_group c2
                       ON b.sectie_code :: TEXT = c2.sectie_code :: TEXT AND a.start_parking_dt >= c2.start_dt AND
                          a.start_parking_dt <= COALESCE(c2.end_dt :: TIMESTAMP WITH TIME ZONE, now()) AND
                          b.client_id = c2.client_id AND c2.group_level = 2
             LEFT JOIN areaal_sectie_group c3
                       ON b.sectie_code :: TEXT = c3.sectie_code :: TEXT AND a.start_parking_dt >= c3.start_dt AND
                          a.start_parking_dt <= COALESCE(c3.end_dt :: TIMESTAMP WITH TIME ZONE, now()) AND
                          b.client_id = c3.client_id AND c3.group_level = 3
             LEFT JOIN street_parking_gsm_provider d ON a.gsm_provider_id = d.id
    WHERE a.client_id = 39
      AND coalesce(asec.dummy, FALSE) is FALSE -- Dummy locaties: Eventuele (test)transacties niet rapporteren.
      AND a.start_parking_dt::date between '1-jan-2020' and '29-feb-2020'
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9,10
),
     dow_count as (select dow, count(1) as no_dow
                   from (select day::date
                              , extract(dow from day) :: int as dow
                         FROM generate_series(timestamp '1-jan-2020', timestamp '29-feb-2020', interval '1 day') day
                         ) as a
                   group by dow
                   order by dow
                   )

SELECT oad.dow
     , uur
     , sectie_code_group_value_1 AS "Gebied"
     , sectie_code_group_value_2 AS "Buurt"
     , SUM(CASE WHEN UPPER(payment_method) = 'GSM'                   THEN amount_ct ELSE 0 END)/100.::FLOAT AS "Mobiel"
     , SUM(CASE WHEN UPPER(payment_type)   in ('CHARTAAL', 'MUNTEN') THEN amount_ct ELSE 0 END)/100.::FLOAT AS "Chartaal"
     , SUM(CASE WHEN UPPER(payment_type)   = 'CHIPKNIP'              THEN amount_ct ELSE 0 END)/100.::FLOAT AS "Chipknip"
     , SUM(CASE WHEN UPPER(payment_type)   in ('GIRAAL', 'PIN')      THEN amount_ct ELSE 0 END)/100.::FLOAT AS "Giraal"
     , SUM(CASE WHEN UPPER(payment_type)   = 'CREDIT CARD'           THEN amount_ct ELSE 0 END)/100.::FLOAT AS "Credit Card"
     , SUM(CASE WHEN UPPER(payment_type)   = 'PAYONE PARKING'        THEN amount_ct ELSE 0 END)/100.::FLOAT AS "PayONE"
     , SUM(CASE WHEN UPPER(payment_type)   not in ('CHARTAAL','MUNTEN', 'CHIPKNIP', 'GIRAAL', 'PIN', 'CREDIT CARD', 'PAYONE PARKING')
    AND UPPER(payment_method) <> 'GSM'
                    THEN amount_ct ELSE 0 END)/100.::FLOAT AS "Overig"
     , SUM(amount_ct)/100.::FLOAT  AS "Totaal"
     , dowc.no_dow as "Aantal dagen in 2020"
FROM onstreet_aggr_datetime oad
         left join street_parking_payment_types sppt
                   on oad.payment_method = 'TA' and oad.payment_type_id = sppt.id
left join dow_count as dowc on oad.dow = dowc.dow
where uur between 8 and 22
GROUP BY 1,2,3,4, dowc.no_dow
ORDER BY 1,2,3,4
;