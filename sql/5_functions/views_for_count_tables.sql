
create view count_all_library_strategy_from_report
as 
select librarystrategy, count(*) as n 
from report re 
join run ru on ru.runaccession = re.runaccession 
join experiment e on e.experimentaccession = ru.experimentaccession 
group by librarystrategy 
order by n desc;

create view count_all_library_selection_from_report
as 
select libraryselection, count(*) as n from report re 
join run ru on ru.runaccession = re.runaccession 
join experiment e on e.experimentaccession = ru.experimentaccession 
group by libraryselection
order by n desc;

create view count_all_library_selection_and_strategy_from_report
as 
select libraryselection, librarystrategy, count(*) as n from report re 
join run ru on ru.runaccession = re.runaccession 
join experiment e on e.experimentaccession = ru.experimentaccession 
group by libraryselection, librarystrategy
order by n desc;

create view count_all_taxon_from_sample
as
select t.taxonid, count(*) as n, t.taxonname from sample s 
join taxon t on t.taxonid = s.taxonid 
group by t.taxonid, t.taxonname 
order by n desc;

create view count_all_taxon_never_classified
as
select t.taxonid, count(*) as n, t.taxonname 
from sample s 
join taxon t on t.taxonid = s.taxonid
where t.taxonid not in(
	select distinct taxonid
	from report re
	join run ru on ru.runaccession = re.runaccession 
	join experiment e on e.experimentaccession = ru.experimentaccession 
	join sample s on s.sampleaccession = e.sampleaccession
)
group by t.taxonid, t.taxonname 
order by n desc;

create view count_all_taxon_already_classified
as
select t.taxonid, count(*) as n, t.taxonname
from report re 
join run ru on ru.runaccession = re.runaccession 
join experiment e on e.experimentaccession = ru.experimentaccession 
join sample s on s.sampleaccession = e.sampleaccession
join taxon t on s.taxonid = t.taxonid
group by t.taxonid, t.taxonname
order by n desc;

create view count_all_taxon_to_ignore
as
select t.taxonid, count(*) as n, t.taxonname 
from run ru
join experiment e on e.experimentaccession = ru.experimentaccession
join sample s on s.sampleaccession = e.sampleaccession
join taxon t on t.taxonid = s.taxonid
where ru.runoutcome = 'IGNORE'
group by t.taxonid, t.taxonname;