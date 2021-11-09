# SRA-ome: taxonomy classification of DNA/RNA sequences uploaded on SRA
## Analysis of metagenomics or metatranscriptomics samples

In this project has been implemented an almost fully automated system to systematically classify the reads present in SRA database, in order to detect all the taxa present inside it.

To store all the needed data, has been designed and implemented a database (in postgres), which contains: 
 * SRA metadata of runs, experiments, samples ecc. 
 * NCBI Official Taxonomy
 * Kraken Taxonomy
 * Classification results (called also reports)

## Database structure
NB: SRA is maintained by INDSC, which is an association of three indipendent entities:
| Entity | State | DB Name | SRA Acronym |
| ------ | ----- | ------- | ----------- |
| NCBI   | US    | GenBank | S           |
| EMBL   | EU    | EMBL    | E           |
| NIG    | JPN   | DDBJ    | D           |

### SRA Metadata
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

#### Run (ID regex: ^[D,E,S]RR[0-9]+$ )
SRA's Run definition:
"A Run is simply a manifest of data file(s) that are derived from sequencing a library described by the associated Experiment."

#### Experiment (ID regex: ^[D,E,S]RX[0-9]+$ )
SRA's Experiment definition:
"An experiment is a unique sequencing result for a specific sample."


#### Sample (ID regex: ^[D,E,S]RS[0-9]+$ )
#### Study (ID regex: ^[D,E,S]RP[0-9]+$ )
#### Submission (ID regex: ^[D,E,S]RA[0-9]+$ )

See also: https://www.ncbi.nlm.nih.gov/sra/docs/submitmeta/


### NCBI Taxonomy

### Kraken Taxonomy

### Reports


## Workflow
