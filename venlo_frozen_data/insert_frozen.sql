insert into venlo_dw.journaalposten_frozen
select *
from venlo_dw.journaalposten_freshly_calculated
where yr=2020 and mnth = 8;

select * from venlo_dw.journaalposten_frozen
where yr=2020 and mnth = 8;

-- delete from venlo_dw.journaalposten_frozen
-- where journaalpost = 'Correctie';


-- insert
-- into venlo_dw.journaalposten_frozen
-- (yr, mnth, journaalpost, amount)
-- values(2019, 7, 'Correctie ex BTW', 385.84);
--
-- insert
-- into venlo_dw.journaalposten_frozen
-- (yr, mnth, journaalpost, amount)
-- values(2019, 8, 'Correctie ex BTW', 454.95);
--
-- insert
-- into venlo_dw.journaalposten_frozen
-- (yr, mnth, journaalpost, amount)
-- values(2019, 6, 'Correctie ex BTW', 2000);
--
