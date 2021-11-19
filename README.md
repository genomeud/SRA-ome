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

SRA is maintained by INDSC, which is an association of three indipendent entities:
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

#### Run (Accession regex: [D,E,S]RR[0-9]+ )
SRA's Run definition:
"A Run is simply a manifest of data file(s) that are derived from sequencing a library described by the associated Experiment."

In a run there are few relevant information: PublicationDateTime, SRAFileSize, Spot, Base, Consent.

In addition to these, in our schema we are storing a column 'RunOutcome' which explicits the state of the run in respect to the analysis process:
 * **OK**: already been analysed 
 * **TODO**: not yet analysed (but we want to)
 * **IGNORE** we are not interest on analysing it

It also contains the FK to the corresponding Experiment.

#### Experiment (Accession regex: [D,E,S]RX[0-9]+ )
SRA's Experiment definition:
"An experiment is a unique sequencing result for a specific sample."

The experiment is the most important entity, it contains all the information about the sequencing procedure:
Design, LibraryName, LibrarySource, LibraryLayout, LibrarySelection, LibraryStrategy, PlatformName, InstrumentName.

Most of these fields are actually stored in a separated table (with all the fields possibilities) and are referred as a FK.

It also contains the FK to the corresponding Sample.

#### Sample (Accession regex: [D,E,S]RS[0-9]+ )
A sample represents what actually has been collected from the environment.
A sample can be splitted in many sequencing experiments and also can be the target of many studies.

The two most important information stored are: TaxonID, the TaxonID of the sample, BioSampleID, the identifier of the sample in the BioSample database.

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
In this particular cases, some euristics can be used to discover it: same Title, same Abstract, same SubmissionAccession ecc.

The only field which is stored is the accession code.

#### SRA Structure links

Some more information on how SRA is structured can be found: 
 * https://www.ncbi.nlm.nih.gov/sra/docs/submitmeta/
 * https://github.com/enasequence/schema/tree/master/src/main/resources/uk/ac/ebi/ena/sra/schema
 * https://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?view=xml_schemas

### NCBI Taxonomy
The NCBI Taxonomy contains all the taxonomy known and accepted by NCBI.<br>
It is useful to know all the ancestors and the descendants of a taxon, his rank ecc.

It is structured with three entities:
 * **Taxon**: the most important, contains all the data about all taxa
   * **TaxonID**: NCBI's taxonomy index (PK)
   * **Rank**: rank of the taxon (FK)
   * **TaxonName**: scientific name of the taxon
   * **ParentTaxonID**: NCBI's taxonomy index of the parent of the taxon (FK)
 * **Rank**: container for all existing rank, is used as FK in Taxon
 * **Lineage**: container for all existing couples <rank, parent_rank>, is used as FK from Rank
   * it is useful for mantain some integrity constraints: if the couple is not present here than can't exist such couple in Taxon table 
      * which means that foreach Taxon T: <T.Rank, T.ParentTaxonID.Rank> in Taxon &rarr; <L.Rank, L.ParentRank> in Lineage

NB1: In the first version of the database each taxon was identified only by his TaxonID.
This is always true.
But problems raised trying to update the taxonomy to new versions (tipically there is an update per month).
This is due to how NCBI handles old taxa: it does not just rename them but sometimes changes the tree (parent/sons) but most important can happen that some taxa may be merged, moved, deleted.
This fact cause errors with the FK in the Kraken Taxonomy: if a taxon was found in a classification using an older version and then it is removed from the NCBI Taxonomy then there would be a FK missing in the Kraken Taxonomy.

For this reason we had to identify each taxa with the tuple <Date, TaxonID>.
This obviously causes a massive increase in the size: each taxonomy version contains all the taxa associated, altough most of them is always the same.

NB2: (Obviously) we do not store all the taxonomy versions but only the ones associated to a KrakenDatabase used during classification.<br>
As for now, we are storing just one version: 2020-12-01.<br>
It is available here: https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump_archive/new_taxdump_2020-12-01.zip<br>
All possible database versions are here: https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump_archive

NB3: SRA when edits the Taxonomy also updates the reference of the taxa in the old samples.
This implies that downloading the same metadata in different time can lead to a different result, in the specific in the TaxonID of the sample which can have changed in the meanwhile.
In respect to this, our politic is different: we mantain old data as it is without updating it (remember, as said before, that our Taxon PK is composed by both TaxonID and database date version and so the FK too).

The analysis we did where based on the metadata downloaded the 13/03/2021 (three months later the Taxonomy version used).
Luckily, just one sample had a taxon not inside the Taxonomy, which has been inserted manually.

So, from the Taxonomy version of 2020-12-01 we had to add manually two taxa:
| TaxonID   | ParentTaxonID | Rank    | TaxonName                 | Reason                                                   |
| --------- | ------------- | ------- | ------------------------- | -------------------------------------------------------- |
| 2801061   | 205167        | species | Andrena sp. MF-2021       | present in Sample.TaxonID but not in NCBI Taxonomy       |
| 2792603   | 1765964       | species | Acidihalobacter aeolianus | present in KrakenRecord.TaxonID but not in NCBI Taxonomy |

### Kraken Taxonomy
The Kraken Taxonomy is a subtree of the NCBI Taxonomy.
If the NCBI T. contains all taxa known, the Kraken T. just lists the taxa that can be found.
The Kraken T. maps foreach taxon the corresponding k-mers, fundamental in the classification process.<br>
NB: The k-mers are not stored in our database.

It is structured with two entities:
 * **KrakenDatabase**: contains the metadata about the database version
 * **KrakenRecord**: contains the list of all taxa present forall the database version related.
   * it is a sublist of all taxa present in Taxon
   * if a taxon is not present here then Kraken can't find it in the classification
   * foreach taxon is written the total number of fragments present in the database, both directly and rooted in the taxon

Foreach Kraken Taxonomy version used we save the information about the version and all the taxa.<br>
As for now, we are storing just one version: Standard-16 of 2020-12-02.<br>
It is available here: https://genome-idx.s3.amazonaws.com/kraken/k2_standard_16gb_20201202.tar.gz<br>
All possible database versions are here: https://benlangmead.github.io/aws-indexes/k2

### Reports
The reports are the core of our project.
A report is the result of the classification of a run.

In the reports are we have two entities:
 * **Report**: stores which specific runs has been classified with a specific kraken database in a certain date
 * **ReportTaxon**: contains the output of the classification of each report:
  * **TaxonID**: the ID of the Taxon found
  * **RootedFragmentNum**: the number of fragments found in the taxon and in all his descedants (the sub-tree with it as root)
  * **DirectFragmentNum**: the number of fragments found in the specific taxon

NB1: For a complete view of the classification can be useful to compare the fragment nums in percentage of the total number of fragments in the run, the Run.Spot value.

NB2: Note that there is a possibility of getting some false-positive.



## Workflow
