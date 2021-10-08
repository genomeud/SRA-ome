
create or replace function get_reports_from_taxon_id_report(
    _taxon_id dom_taxon_id
)
returns table(
    StudyID             dom_study_accession,
    StudyTitle          text,
    --SampleID            dom_sample_accession,
    TaxNameSample       text,
    --ExpID               dom_experiment_accession,
    RunID               dom_run_accession,
    Publicated          timestamp,
    --DB_Collection       dom_collection,
    --DB_CollectionDate   dom_collection_date,
    --TaxIDReport         dom_taxon_id,
    --TaxNameReport       text,
    RootedNum      bigint,
    RootedPerc     decimal,
    DirectNum      bigint,
    DirectPerc     decimal
)
language plpgsql as
$$
begin
    return query
    select
        ST.StudyAccession                                       as StudyID,
        left(ST.Title,30)                                       as StudyTitle,
        --SA.SampleAccession                                      as SampleID,
        left(TaxNameSample.TaxonName,20)                        as TaxNameSample,
        --E.ExperimentAccession                                   as ExpID,
        RU.RunAccession                                         as RunID,
        RU.PublicationDateTime                                  as Publicated,
        --RT.Collection                                           as DB_Collection,
        --RT.CollectionDate                                       as DB_CollectionDate,
        --TaxOfReport.TaxonID                                     as TaxIDReport,
        --TaxOfReport.TaxonName                                   as TaxNameReport,
        RT.RootedFragmentNum                                    as RootedNum,
        get_percentage(RT.RootedFragmentNum, RU.Spot)           as RootedPerc,
        RT.DirectFragmentNum                                    as DirectNum,
        get_percentage(RT.DirectFragmentNum, RU.Spot)           as DirectPerc

    from 
        Taxon as TaxOfReport

    join ReportTaxon as RT              on RT.TaxonID               = TaxOfReport.TaxonID
    join Report      as RE              on RE.RunAccession          = RT.RunAccession
    join Run         as RU              on RU.RunAccession          = RE.RunAccession
    join Experiment  as E               on E.ExperimentAccession    = RU.ExperimentAccession
    join Sample      as SA              on SA.SampleAccession       = E.SampleAccession
    join StudySample as SS              on SS.SampleAccession       = SA.SampleAccession
    join Study       as ST              on ST.StudyAccession        = SS.StudyAccession
    join Taxon       as TaxNameSample   on SA.TaxonID               = TaxNameSample.TaxonID

    where
        TaxOfReport.TaxonID = _taxon_id

    order by 
        RU.PublicationDateTime  desc,
        ST.StudyAccession       asc,
        SA.SampleAccession      asc,
        E.ExperimentAccession   asc,
        RU.RunAccession         asc
    ;

end;
$$;