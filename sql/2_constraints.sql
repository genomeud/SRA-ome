
start transaction;

-- foreign keys constraints

-- start region taxonomy

-- fk Lineage
alter table Lineage add
  constraint rank_is_subrank_of_rank_fk
  foreign key (Rank) 
    references Rank(Rank)
      on update cascade
      on delete cascade;

alter table Lineage add
  constraint rank_is_superrank_of_rank_fk
  foreign key (ParentRank) 
    references Rank(Rank)
      on update cascade
      on delete cascade;

-- fk Taxon
alter table Taxon add
  constraint taxon_comprises_taxa_fk
  foreign key (ParentTaxonID) 
    references Taxon(TaxonID)
      on update cascade
      on delete cascade;

-- using ID as PK this constraint must be a trigger
--alter table Taxon add
--  constraint rank_hierarchy_frames_taxa_fk
--  foreign key (Rank, ParentRank) 
--    references Lineage(Rank, ParentRank)
--      on update cascade
--      on delete cascade;

-- end region taxonomy

-- start region SRA metadata

-- fk StudySubmission
alter table StudySubmission add
  constraint study_part_of_studysubmission_fk
  foreign key (StudyAccession) 
    references Study(StudyAccession)
      on update cascade
      on delete cascade;

alter table StudySubmission add
  constraint submission_comprises_studysubmission_fk
  foreign key (SubmissionAccession) 
    references Submission(SubmissionAccession)
      on update cascade
      on delete cascade;

-- fk StudySupervisor
alter table StudySupervisor add
  constraint study_done_by_studysupervisor_fk
  foreign key (StudyAccession) 
    references Study(StudyAccession)
      on update cascade
      on delete cascade;
    
alter table StudySupervisor add
  constraint institution_supervises_studysupervisor_fk
  foreign key (InstitutionName) 
    references Institution(InstitutionName)
      on update cascade
      on delete cascade;

-- fk Sample
alter table Sample add
  constraint taxon_is_target_of_sample_fk
  foreign key (TaxonID) 
    references Taxon(TaxonID)
      on update cascade
      on delete cascade;

-- fk StudySample
alter table StudySample add
  constraint sample_is_discussed_in_study_fk
  foreign key (SampleAccession) 
    references Sample(SampleAccession)
      on update cascade
      on delete cascade;

alter table StudySample add
  constraint study_discusses_the_analysis_of_sample_fk
  foreign key (StudyAccession) 
    references Study(StudyAccession)
      on update cascade
      on delete cascade;

-- fk Instrument
alter table Instrument add
  constraint platform_qualifies_instrument_fk
  foreign key (PlatformName) 
    references Platform(PlatformName)
      on update cascade
      on delete cascade;

-- fk Experiment
alter table Experiment add
  constraint sample_is_analysed_in_experiment_fk
  foreign key (SampleAccession) 
    references Sample(SampleAccession)
      on update cascade
      on delete cascade;

alter table Experiment add
  constraint library_source_classifies_experiment_fk
  foreign key (LibrarySource) 
    references LibrarySource(LibrarySource)
      on update cascade
      on delete cascade;
    
alter table Experiment add
  constraint library_layout_classifies_experiment_fk
  foreign key (LibraryLayout) 
    references LibraryLayout(LibraryLayout)
      on update cascade
      on delete cascade;
    
alter table Experiment add
  constraint library_selection_classifies_experiment_fk
  foreign key (LibrarySelection) 
    references LibrarySelection(LibrarySelection)
      on update cascade
      on delete cascade;
    
alter table Experiment add
  constraint library_strategy_classifies_experiment_fk
  foreign key (LibraryStrategy) 
    references LibraryStrategy(LibraryStrategy)
      on update cascade
      on delete cascade;
        
alter table Experiment add
  constraint instrument_used_in_experiment_fk
  foreign key (PlatformName, InstrumentName) 
    references Instrument(PlatformName, InstrumentName)
      on update cascade
      on delete cascade;

-- fk Run
alter table Run add
  constraint experiment_consists_of_run_fk
  foreign key (ExperimentAccession) 
    references Experiment(ExperimentAccession)
      on update cascade
      on delete cascade;
    
alter table Run add
  constraint outcome_results_in_run_fk
  foreign key (RunOutcome) 
    references RunOutcome(RunOutcome)
      on update cascade
      on delete cascade;

-- end region SRA metadata

-- start region kraken database

-- fk KrakenRecord
alter table KrakenRecord add
  constraint krakendatabase_contains_krakenrecord_fk
  foreign key (Collection, CollectionDate) 
    references KrakenDatabase(Collection, CollectionDate)
      on update cascade
      on delete cascade;
    
alter table KrakenRecord add
  constraint taxon_is_stored_as_krakenrecord_fk
  foreign key (TaxonID) 
    references Taxon(TaxonID)
      on update cascade
      on delete cascade;

-- end region kraken database

-- start region reports

-- fk Report
alter table Report add
  constraint krakendatabase_is_used_by_report_fk
  foreign key (Collection, CollectionDate) 
    references KrakenDatabase(Collection, CollectionDate)
      on update cascade
      on delete cascade;
    
alter table Report add
  constraint run_is_used_in_report_fk
  foreign key (RunAccession) 
    references Run(RunAccession)
      on update cascade
      on delete cascade;

-- fk ReportTaxon
alter table ReportTaxon add
  constraint krakenrecord_appears_as_reporttaxon_fk
  foreign key (Collection, CollectionDate, TaxonID) 
    references KrakenRecord(Collection, CollectionDate, TaxonID)
      on update cascade
      on delete cascade;
    
alter table ReportTaxon add
  constraint run_identifies_reporttaxon_fk
  foreign key (RunAccession) 
    references Run(RunAccession)
      on update cascade
      on delete cascade;

-- end region reports


commit;