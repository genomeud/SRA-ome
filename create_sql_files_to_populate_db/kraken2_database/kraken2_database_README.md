
Use the database version you prefer.
https://benlangmead.github.io/aws-indexes/k2

From the link you can both see the database version you are interest (write the infos manually in the file 0_kdb_KrakenDatabase.sql) and download the inspect.txt.

The inspect.txt file contains the list of all taxons which can be found during a classification.

Execute:
./getKrakenDBInfosFromInspectFile.sh <inspect.txt> <collection_name> <collection_date>

Example: ./getKrakenDBInfosFromInspectFile.sh Kraken2_DB16_inspect.txt Standard-16 2020-02-12

To produce as output the file: Kraken2_DB16_<collection_name>_<collection_date>.sql

After all copy these two sql files to /sql/4_population