create or replace function get_reports_from_study_accession(
    _study_accession dom_study_accession
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
        SA.SampleAccession                                       as SampleID,
        --S.BioSampleID                                           as BioSampleID,
        --TaxOfSample.TaxonID                                     as TaxIDSample,
        TaxOfSample.TaxonName                                   as TaxNameSample,
        E.ExperimentAccession                                   as ExpID,
        RU.RunAccession                                         as RunID,
        --RU.PublicationDateTime                                  as Publicated,
        --RT.Collection                                           as DB_Collection,
        --RT.CollectionDate                                       as DB_CollectionDate,
        TaxOfReport.TaxonID                                     as TaxIDReport,
        left(TaxOfReport.TaxonName,20)                                   as TaxNameReport,
        RT.RootedFragmentNum                                    as RootedFragsNum,
        get_percentage(RT.RootedFragmentNum, RU.Spot)           as RootedFragsPerc,
        RT.DirectFragmentNum                                    as DirectFragsNum,
        get_percentage(RT.DirectFragmentNum, RU.Spot)           as DirectFragsPerc

    from 
        Study as ST

    join StudySample as SS          on SS.StudyAccession        = ST.StudyAccession
    join Sample      as SA          on SA.SampleAccession       = SS.SampleAccession
    join Taxon       as TaxOfSample on TaxOfSample.TaxonID      = SA.TaxonID
    join Experiment  as E           on E.SampleAccession        = SA.SampleAccession
    join Run         as RU          on RU.ExperimentAccession   = E.ExperimentAccession
    join Report      as RE          on RE.RunAccession          = RU.RunAccession
    join ReportTaxon as RT          on RT.RunAccession          = RU.RunAccession
    join Taxon       as TaxOfReport on TaxOfReport.TaxonID      = RT.TaxonID

    where
        ST.StudyAccession = _study_accession

    order by 
        E.ExperimentAccession   asc,
        RU.RunAccession         asc,
        RT.RootedFragmentNum    desc,
        RT.DirectFragmentNum    desc
    ;

end;
$$;
