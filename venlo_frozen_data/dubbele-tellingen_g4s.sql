select count(1),
       count(distinct(lokatiecode || case when totaal_munt_bedr is not null then 'M'
                                          when totaal_biljet_bedr is not null then 'B'
                                          else 'Vreemd'
           end )) as dist_code,
       insert_dt,
       registratiedatum,
       task_detail_log_id
from venlo_sti_hst.sti_hst_venlo_str_collecties_g4s
where registratiedatum > '30-apr-2020'
group by insert_dt,
         registratiedatum,
         task_detail_log_id
order by insert_dt desc,
         registratiedatum desc;