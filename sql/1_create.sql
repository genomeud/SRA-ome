-- create db
create database sra_analysis;

-- connect to db
\c sra_analysis;

start transaction;

-- START REGION DOMAINS DEFINITION

-- start region taxonomy

-- create domain dom_rank as char(2);
-- create domain dom_rank as varchar(6)
--  constraint valid_dom_rank
--  check (value ~ '^[A-Z]{2,2}(_[a-z]{3,3})?$');
create domain dom_rank as text;

create domain dom_taxon_name as text;

create domain dom_taxon_id as text
  constraint valid_taxon_id
  check (value ~ '^\d+$');

-- end region taxonomy

-- start region SRA metadata

-- DRA[0-9]+, ERA[0-9]+, SRA[0-9]+
create domain dom_submission_accession as text
  constraint valid_dom_submission_accession
  check (value ~ '^[D,E,S]RA\d+$');

-- DRP[0-9]+, ERP[0-9]+, SRP[0-9]+  
create domain dom_study_accession as text
  constraint valid_dom_study_accession
  check (value ~ '^[D,E,S]RP\d+$');

-- PRJD[A,B][0-9]+, PRJE[A,B][0-9]+, PRJN[A,B][0-9]+
create domain dom_bio_project_id as text
  constraint valid_dom_bio_project_id 
  check (value ~ '^PRJ[D,E,N][A,B]\d+$');
  
-- DRP[0-9]+, ERP[0-9]+, SRP[0-9]+
create domain dom_sample_accession as text
  constraint valid_dom_sample_accession
  check (value ~ '^[D,E,S]RS\d+$');
  
-- SAMD[0-9]+, SAMEA[0-9]+, SAMN[0-9]+
create domain dom_bio_sample_id as text
  constraint valid_dom_bio_sample_id
  check (value ~ '^SAM(D|EA|N)\d+$');

-- libraries
create domain dom_library_source    as varchar(50);
create domain dom_library_layout    as char(6);     -- single or paired
create domain dom_library_selection as varchar(50);
create domain dom_library_strategy  as varchar(50);
create domain dom_platform_name     as varchar(50);
create domain dom_instrument_name   as varchar(50);

-- DRX[0-9]+, ERX[0-9]+, SRX[0-9]+
create domain dom_experiment_accession as text
  constraint valid_dom_experiment_accession
  check (value ~ '^[D,E,S]RX\d+$');

create domain dom_run_outcome as varchar(10);

-- DRR[0-9]+, ERR[0-9]+, SRR[0-9]+
create domain dom_run_accession as text
  constraint valid_dom_run_accession
  check (value ~ '^[D,E,S]RR\d+$');
  
-- end region SRA metadata

-- start region kraken database

-- kraken database collection
create domain dom_collection      as varchar(30);
create domain dom_collection_date as date;

-- end region kraken database

-- END REGION DOMAINS DEFINITION

----------------------------------------------------------------------------------------

-- START REGION TABLES DEFINITION

-- start region taxonomy
-- popolamento fatto
create table Rank (
  RankIndex integer,
  Rank      dom_rank not null,

  primary key (Rank)
);

-- popolamento fatto
create table Lineage (
  Rank       dom_rank not null,
  ParentRank dom_rank not null,

  primary key (Rank, ParentRank),
  unique      (ParentRank, Rank)
);

-- popolamento fatto
create table Taxon (
  TaxonID       dom_taxon_id   not null,
  ParentTaxonID dom_taxon_id   not null,
  TaxonName     dom_taxon_name not null,
  Rank          dom_rank       not null,

  primary key (TaxonID)
  -- unique (TaxonName, Rank) -- non vero, vedere la coppia: <'genus','Mallotus'> con taxIDs: 20202, 30959
);
-- end region taxonomy

-- start region SRA metadata
-- popolamento fatto
create table Submission (
  SubmissionAccession dom_submission_accession not null,

  primary key(SubmissionAccession)
);

-- popolamento fatto
create table Study (
  StudyAccession dom_study_accession not null,
  Title          text                not null,
  Abstract       text,
  BioProjectID   dom_bio_project_id,
  Note           text,

  primary key(StudyAccession),
  unique(BioProjectID)
);

-- popolamento fatto
create table StudySubmission (
  StudyAccession      dom_study_accession      not null,
  SubmissionAccession dom_submission_accession not null,

  primary key(StudyAccession, SubmissionAccession)
);

-- popolamento fatto
create table Institution (
  InstitutionName text not null,

  primary key(InstitutionName)
);

-- popolamento fatto
-- todo usare come pk solo studyaccession(?)
create table StudySupervisor (
  StudyAccession  dom_study_accession not null,
  InstitutionName text                not null,

  primary key(StudyAccession, InstitutionName)
);

-- popolamento fatto
create table Sample (
  SampleAccession dom_sample_accession not null,
  Title           text,
  Description     text,
  Alias           text,
  BioSampleID     dom_bio_sample_id    not null,
  TaxonID         dom_taxon_id         not null,

  primary key(SampleAccession),
  unique(BioSampleID)
);

-- popolamento fatto
create table StudySample (
  StudyAccession  dom_study_accession  not null,
  SampleAccession dom_sample_accession not null,

  primary key(StudyAccession, SampleAccession)
);

-- popolamento fatto
create table LibrarySource (
  LibrarySource dom_library_source not null,

  primary key(LibrarySource)
);

-- popolamento fatto
create table LibraryLayout (
  LibraryLayout dom_library_layout not null,

  primary key(LibraryLayout)
);

-- popolamento fatto
create table LibrarySelection (
  LibrarySelection dom_library_selection not null,

  primary key(LibrarySelection)
);

-- popolamento fatto
create table LibraryStrategy (
  LibraryStrategy dom_library_strategy not null,

  primary key(LibraryStrategy)
);

-- popolamento fatto
create table Platform (
  PlatformName dom_platform_name not null,

  primary key(PlatformName)
);

-- popolamento fatto
create table Instrument (
  InstrumentName dom_instrument_name not null,
  PlatformName   dom_platform_name   not null,

  primary key(PlatformName, InstrumentName)
);

-- popolamento fatto
create table Experiment (
  ExperimentAccession dom_experiment_accession  not null,
  Title               text,
  Alias               text,
  Design              text,
  LibraryName         text,
  SampleAccession     dom_sample_accession      not null,
  LibrarySource       dom_library_source        not null,
  LibraryLayout       dom_library_layout        not null,
  LibrarySelection    dom_library_selection     not null,
  LibraryStrategy     dom_library_strategy      not null,
  PlatformName        dom_platform_name         not null,
  InstrumentName      dom_instrument_name       not null,

  primary key(ExperimentAccession)
);

-- popolamento fatto
create table RunOutcome (
  RunOutcome dom_run_outcome not null,

  primary key(RunOutcome)
);

-- popolamento fatto
create table Run (
  RunAccession        dom_run_accession        not null,
  PublicationDateTime timestamp                not null,
  SRAFileSizeMB       bigint,
  Spot                bigint,
  Base                bigint,
  Consent             text                     not null default 'public',
  Note                text,
  RunOutcome          dom_run_outcome          not null default 'TODO',
  ExperimentAccession dom_experiment_accession not null,

  primary key(RunAccession)
);

-- end region SRA metadata

-- start region kraken database

-- popolamento fatto
create table KrakenDatabase (
  Collection      dom_collection      not null,
  CollectionDate  dom_collection_date not null,
  ArchiveSizeGB   real                not null,
  IndexSizeGB     real                not null,
  CappedAtGB      real,

  primary key(Collection, CollectionDate)
);

-- popolamento fatto
create table KrakenRecord (
  Collection        dom_collection      not null,
  CollectionDate    dom_collection_date not null,
  TaxonID           dom_taxon_id        not null,
  RootedFragmentNum bigint              not null,
  DirectFragmentNum bigint              not null,

  primary key(Collection, CollectionDate, TaxonID)
);

-- end region kraken database

-- start region reports

-- popolamento fatto
create table Report (
  RunAccession      dom_run_accession   not null,
  Collection        dom_collection      not null,
  CollectionDate    dom_collection_date not null,
  ReportDate        date                not null,
  Note              text,

  primary key(RunAccession, Collection, CollectionDate)
);

create table ReportTaxon (
  RunAccession      dom_run_accession   not null,
  Collection        dom_collection      not null,
  CollectionDate    dom_collection_date not null,
  TaxonID           dom_taxon_id        not null,
  RootedFragmentNum bigint              not null,
  DirectFragmentNum bigint              not null,

  primary key(RunAccession, Collection, CollectionDate, TaxonID)
);

-- end region reports

-- END REGION TABLES DEFINITION

commit;