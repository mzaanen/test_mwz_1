        SELECT
    ordering_nr,
    bank_bron,
    groepering,
    journaalpost,
    extract(YEAR from start_parking_d)::int as yr,
    extract(MONTH from start_parking_d)::int as mnth,
    round((SUM(amount_ct) / 100.) :: NUMERIC, 2) as amount
fROM (
         select 10                               as ordering_nr,
                'Mobiel parkeren' :: TEXT        as groepering,
                'SPHV'                           as bank_bron,
                'Mobiel parkeren excl commissie' as journaalpost,
                start_parking_d,
                amount_ct * (1 - 0.0175)         as amount_ct
         from onstreet_aggr_date sa
         WHERE client_id = 49
           AND to_char(start_parking_d, 'YYYY') <= '2020'
           AND sectie_code_group_value_1 in ('Rosarium', 'Schil', 'Centrum')
           AND payment_method = 'GSM' -- Mobiel

         UNION ALL
         select 11                          as ordering_nr,
                'Mobiel parkeren' :: TEXT   as groepering,
                'SPHV'                      as bank_bron,
                'Mobiel parkeren commissie' as journaalpost,
                start_parking_d,
                amount_ct * 0.0175          as amount_ct
         from onstreet_aggr_date sa
        WHERE client_id = 49
           AND to_char(start_parking_d, 'YYYY') <= '2020'
           AND sectie_code_group_value_1 in ('Rosarium', 'Schil', 'Centrum')
           AND payment_method = 'GSM' -- Mobiel

         UNION ALL
         select 15                                         as ordering_nr,
                'Mobiel parkeren Grenswerk' :: TEXT        as groepering,
                'SPHV'                                     as bank_bron,
                'Grenswerk Mobiel parkeren excl commissie' as journaalpost,
                start_parking_d,
                amount_ct * (1 - 0.0175)                   as amount_ct
         from onstreet_aggr_date sa
        WHERE client_id = 49
           AND to_char(start_parking_d, 'YYYY') <= '2020'
           AND sectie_code_group_value_1 in ('Grenswerk parkeren')
           AND payment_method = 'GSM' -- Mobiel

         UNION ALL
         select 16                                    as ordering_nr,
                'Mobiel parkeren Grenswerk' :: TEXT   as groepering,
                'SPHV'                                as bank_bron,
                'Grenswerk Mobiel parkeren commissie' as journaalpost,
                start_parking_d,
                amount_ct * 0.0175                    as amount_ct
         from onstreet_aggr_date sa
         WHERE client_id = 49
           AND to_char(start_parking_d, 'YYYY') <= '2020'
           AND sectie_code_group_value_1 in ('Grenswerk parkeren')
           AND payment_method = 'GSM' -- Mobiel
     ) aa
--where extract(YEAR from start_parking_d)::int  = 2020 and extract(MONTH from start_parking_d)::int = 2
GROUP BY 1, 2, 3, 4, 5, 6
order by 1, 2, 3, 4, 5;