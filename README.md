# SRA-ome
## Data analysis of DNA/RNA sequences uploaded on SRA
### Samples comes from metagenomics or metatranscriptomics experiments

Code for systematically classify the reads present in SRA database, in order to detect all the taxa present inside it.

To store all the data has been designed and implemented a database (in postgres), which contains: 
 * SRA metadata of runs, experiments, samples ecc. 
 * NCBI Official Taxonomy
 * Kraken Taxonomy
 * Classification results (called also reports)

## Database structure

### SRA Metadata
Currently SRA has these main entities:
 * **Run**: contains the associated reads, no other information
 * **Experiment**: contains all the infos about the experiment (design, libraries ecc)
 * **Sample**: contains the taxonID of the sample and some informations about the sample
 * **Study**: contains infos about the study
 * **Submission**: explicits when the datas has been uploaded.

Relations among entities (too see it better and complete check the IDEF1X model):
 * **<Run, Experiment>**: one-to-many
 * **<Experiment, Sample>**: one-to-many
 * **<Sample, Study>**: many-to-many 
    * In practice, in most cases, is just one-to-many, but can happen that another study re-analyses some samples
    * A many-to-many relation implies to create a derived relation "StudySample" (you will see it in the IDEF1X schema)
 * **<Study, Submission>**: many-to-many
    * A study with all the infos about samples, experiments, runs ecc can be uploaded in more than one part
    * During a submission is possible to upload many different studies

#### Run
#### Experiment
#### Sample
#### Study
#### Submission


### NCBI Taxonomy

### Kraken Taxonomy

### Reports


## Workflow
