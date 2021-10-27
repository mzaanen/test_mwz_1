with offending as (
    SELECT t.id, t.transportdatum, t.lokatiecode, t.lokatie, b.name_short, t.process_flow_account_id, t.totaal_automaat
    FROM brinks_sti_hst.sti_hst_brinks_report_raw t
    left join public.client_info as b on t.process_flow_account_id = b.id
    WHERE zegelnummer like '%e+%'
    order by 1,2)

SELECT t.id, t.zegelnummer, t.transportdatum, t.lokatiecode, t.totaal_automaat, t.lokatie, b.name_short, t.process_flow_account_id, t.*
FROM brinks_sti_hst.sti_hst_brinks_report_raw t
inner join offending as o on t.transportdatum = o.transportdatum and t.lokatiecode = o.lokatiecode and t.process_flow_account_id = o.process_flow_account_id and t.totaal_automaat = o.totaal_automaat
left join public.client_info as b on t.process_flow_account_id = b.id
order by t.transportdatum, t.lokatiecode, t.totaal_automaat, t.zegelnummer;


delete FROM brinks_sti_hst.sti_hst_brinks_report_raw
WHERE zegelnummer like '%e+%';
