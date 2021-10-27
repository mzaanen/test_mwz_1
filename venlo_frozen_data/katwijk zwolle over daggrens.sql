select *
from sti_hst_zwolle_wps_enterprise_tra
where time_of_entry::date != time_of_payment::date
limit 10;

select  max(time_of_entry)
from sti_hst_zwolle_wps_enterprise_tra;


select * --max(time_of_entry)
from sti_hst_katwijk_wps_enterprise_tra
where time_of_entry::date != time_of_payment::date
limit 10;

select max(time_of_entry)
from sti_hst_katwijk_wps_enterprise_tra;

