# SRA-ome: taxonomy classification of DNA/RNA sequences from SRA
## Analysis of metagenomics or metatranscriptomics samples

In this project has been implemented an almost fully automated system to systematically classify the reads present in SRA database, in order to detect all the taxa present inside it.

To store all the needed data, has been designed and implemented a database (in postgres), which contains: 
 * SRA metadata of runs, experiments, samples ecc. 
 * NCBI Official Taxonomy
 * Kraken Taxonomy
 * Classification results (called also reports)

## Database structure

### SRA Metadata

NB: SRA is maintained by INDSC, which is an association of three indipendent entities:
| Entity   | State | Database | SRA Acronym |
| -------- | ----- | -------- | ----------- |
| NCBI     | US    | GenBank  | S           |
| EMBL-EBI | EU    | ENA      | E           |
| NIG      | JPN   | DDBJ     | D           |

Currently SRA has these main entities:
 * **Run**: contains the associated reads, no other information
 * **Experiment**: contains all the infos about the experiment (design, libraries ecc)
 * **Sample**: contains the taxonID of the sample and some informations about the sample
 * **Study**: contains infos about the study
 * **Submission**: explicits when the data has been uploaded.

Relations among entities (too see it better and complete check the IDEF1X model):
 * **<Run, Experiment>**: one-to-many
 * **<Experiment, Sample>**: one-to-many
 * **<Sample, Study>**: many-to-many 
    * In practice, in most cases, is just one-to-many, but can happen that another study re-analyses some samples
    * A many-to-many relation implies to create a derived relation "StudySample" (you will see it in the IDEF1X schema)
 * **<Study, Submission>**: many-to-many
    * A study with all the infos about samples, experiments, runs ecc can be uploaded in more than one part
    * During a submission is possible to upload many different studies

#### Run (ID regex: [D,E,S]RR[0-9]+ )
SRA's Run definition:
"A Run is simply a manifest of data file(s) that are derived from sequencing a library described by the associated Experiment."

In the run are only few information: PublicationDateTime, SRAFileSize, Spot, Base, Consent.

Moreover we added a column 'RunOutcome' which explicits if the run has already been analysed ('OK'), if has to be analysed ('TODO') or if it not of our interest ('IGNORE').

It also contains the FK to the corresponding Experiment.

#### Experiment (Accession regex: [D,E,S]RX[0-9]+ )
SRA's Experiment definition:
"An experiment is a unique sequencing result for a specific sample."

The experiment is most important entity, it contains all the information about the sequencing procedure:
Design, LibraryName, LibrarySource, LibraryLayout, LibrarySelection, LibraryStrategy, PlatformName, InstrumentName.

Most of these fields are actually stored in a separated table (with all the fields possibilities) and are referred as a FK.

It also contains the FK to the corresponding Sample.

#### Sample (Accession regex: [D,E,S]RS[0-9]+ )
A sample represents what actually has been collected from the environment.
A sample can be splitted in many sequencing experiments and also can be the target of many studies.

The two most important information stored are: the TaxonID of the sample and the corresponding BioSampleID (identifier in the BioSample database).

It does NOT contain the FK to the corresponding Study, because, being a M-M relationship, all the FKs are stored in a separated table, StudySample.

#### Study (Accession regex: [D,E,S]RP[0-9]+ )
A study represents a more abstract concept: a work project.
It does not hold any information about sampling or sequencing, just two main fields: Title, Abstract.

A study can focus in many samples and can be uploaded in many submission.

It does NOT contain the FK to the corresponding Submission, because, being a M-M relationship, all the FKs are stored in a separated table, StudySubmission.

#### Submission (Accession regex: [D,E,S]RA[0-9]+ )
A submission is not a pretty important entity.
It just represents when the studies has been uploaded to SRA.

It could be useful in some (rare) cases when different studies are in practical the same but are stored with different accessions.
Obviously only if they are uploaded together (in the same submission).

See also: https://www.ncbi.nlm.nih.gov/sra/docs/submitmeta/

### NCBI Taxonomy

### Kraken Taxonomy

### Reports


## Workflow
