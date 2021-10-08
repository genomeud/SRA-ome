create or replace function get_reports_from_sample_accession(
    _sample_accession dom_sample_accession
)
returns table(
    SampleID            dom_sample_accession,
    --BioSampleID       dom_bio_sample_id,
    --TaxIDSample       dom_taxon_id,
    TaxNameSample       dom_taxon_name,
    ExpID               dom_experiment_accession,
    RunID               dom_run_accession,
    --Publicated        timestamp,
    --DB_Collection     dom_collection,
    --DB_CollectionDate dom_collection_date,
    TaxIDReport         dom_taxon_id,
    TaxNameReport       dom_taxon_name,
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
        S.SampleAccession                                       as SampleID,
        --S.BioSampleID                                           as BioSampleID,
        --TaxOfSample.TaxonID                                     as TaxIDSample,
        TaxOfSample.TaxonName                                   as TaxNameSample,
        E.ExperimentAccession                                   as ExpID,
        RU.RunAccession                                         as RunID,
        --RU.PublicationDateTime                                  as Publicated,
        --RT.Collection                                           as DB_Collection,
        --RT.CollectionDate                                       as DB_CollectionDate,
        TaxOfReport.TaxonID                                     as TaxIDReport,
        TaxOfReport.TaxonName                                   as TaxNameReport,
        RT.RootedFragmentNum                                    as RootedFragsNum,
        get_percentage(RT.RootedFragmentNum, RU.Spot)           as RootedFragsPerc,
        RT.DirectFragmentNum                                    as DirectFragsNum,
        get_percentage(RT.DirectFragmentNum, RU.Spot)           as DirectFragsPerc

    from 
        Sample as S

    join Taxon       as TaxOfSample on TaxOfSample.TaxonID      = S.TaxonID
    join Experiment  as E           on E.SampleAccession        = S.SampleAccession
    join Run         as RU          on RU.ExperimentAccession   = E.ExperimentAccession
    join Report      as RE          on RE.RunAccession          = RU.RunAccession
    join ReportTaxon as RT          on RT.RunAccession          = RU.RunAccession
    join Taxon       as TaxOfReport on TaxOfReport.TaxonID      = RT.TaxonID

    where
        S.SampleAccession = _sample_accession

--    order by 
--        E.ExperimentAccession   asc,
--        RU.RunAccession         asc,
--        RT.RootedFragmentNum    desc,
--        RT.DirectFragmentNum    desc
    ;

end;
$$;
