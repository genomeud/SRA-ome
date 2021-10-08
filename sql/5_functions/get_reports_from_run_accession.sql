create or replace function get_reports_from_run_accession(
    _run_accession dom_run_accession,
    _tax_name_size integer
)
returns table(
    --Publicated        timestamp,
    --DB_Collection     dom_collection,
    --DB_CollectionDate dom_collection_date,
    Rank                dom_rank,
    TaxIDReport         dom_taxon_id,
    TaxNameReport       text,
    RootedFragsNum      bigint,
    RootedFragsPerc     decimal,
    DirectFragsNum      bigint,
    DirectFragsPerc     decimal
)
language plpgsql as
$$
begin
    return query 
    select
        --RU.PublicationDateTime                                  as Publicated,
        --RT.Collection                                           as DB_Collection,
        --RT.CollectionDate                                       as DB_CollectionDate,
        TaxOfReport.Rank                                        as Rank,
        TaxOfReport.TaxonID                                     as TaxIDReport,
        left(TaxOfReport.TaxonName,_tax_name_size)              as TaxNameReport,
        RT.RootedFragmentNum                                    as RootedFragsNum,
        get_percentage(RT.RootedFragmentNum, RU.Spot)           as RootedFragsPerc,
        RT.DirectFragmentNum                                    as DirectFragsNum,
        get_percentage(RT.DirectFragmentNum, RU.Spot)           as DirectFragsPerc

    from 
        Run as RU

    join Report      as RE          on RE.RunAccession          = RU.RunAccession
    join ReportTaxon as RT          on RT.RunAccession          = RU.RunAccession
    join Taxon       as TaxOfReport on TaxOfReport.TaxonID      = RT.TaxonID

    where
        RU.RunAccession = _run_accession

--    order by 
--        E.ExperimentAccession   asc,
--        RU.RunAccession         asc,
--        RT.RootedFragmentNum    desc,
--        RT.DirectFragmentNum    desc
    ;

end;
$$;
