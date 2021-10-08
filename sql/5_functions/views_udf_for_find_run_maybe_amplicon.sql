create view max_direct_num as 
select 
    rt.Collection,
    rt.CollectionDate,
    rt.RunAccession, 
    max(DirectFragmentNum) as max_direct_num
from ReportTaxon rt
group by rt.Collection, rt.CollectionDate, rt.RunAccession;

create view max_direct_num_perc as 
select 
    mdn.Collection,
    mdn.CollectionDate,
    mdn.RunAccession, 
    mdn.max_direct_num,
    trunc((mdn.max_direct_num::decimal / ru.Spot * 100), 4) as max_direct_perc,
    rt.TaxonID as TaxonIDFound
from max_direct_num mdn
join Run ru 
    on ru.RunAccession = mdn.RunAccession
join ReportTaxon rt
    on( rt.Collection = mdn.Collection and
        rt.CollectionDate = mdn.CollectionDate and
        rt.RunAccession = mdn.RunAccession and
        rt.DirectFragmentNum = mdn.max_direct_num )
order by 
    trunc((mdn.max_direct_num::decimal / ru.Spot * 100), 4) desc;

create or replace function run_maybe_amplicon(
    _minimum_percentage_of_fragments_positive integer
)
returns table (
    SampleID            dom_sample_accession,
    ExperimentID        dom_experiment_accession,
    RunID               dom_run_accession,
    Strategy            dom_library_strategy,
    Selection           dom_library_selection,
    MaxDirectPerc       numeric,
    TaxonIDFound        dom_taxon_id,
    TaxonIDSample       dom_taxon_id,
    Title               text
)
language plpgsql as
$$
begin
return query 
select
    s.SampleAccession as SampleID, 
    e.ExperimentAccession as ExperimentID, 
    ru.RunAccession as RunID, 
    e.LibraryStrategy as Strategy, 
    e.LibrarySelection as Selection,
    mdnp.max_direct_perc as MaxDirectPerc,
    mdnp.TaxonIDFound,
    s.TaxonID as TaxonIDSample,
    e.Title as ExperimentTitle
from Report re 
join Run ru 
    on ru.RunAccession = re.RunAccession 
join Experiment e 
    on e.ExperimentAccession = ru.ExperimentAccession 
join Sample s 
    on s.SampleAccession = e.SampleAccession 
join max_direct_num_perc mdnp
    on (re.RunAccession = mdnp.RunAccession and
        re.Collection = mdnp.Collection and
        re.CollectionDate = mdnp.CollectionDate)
where 
    --s.TaxonID = '2697049' and 
    mdnp.max_direct_perc >= _minimum_percentage_of_fragments_positive and
    e.LibraryStrategy <> 'AMPLICON'
order by 
    mdnp.max_direct_perc desc;

end;
$$;

create view run_maybe_amplicon as 
select * from run_maybe_amplicon('50') as rmb
join StudySample SS on SS.SampleAccession = rmb.SampleID
join Taxon TaxFound on TaxFound.TaxonID = rmb.TaxonIDFound
;