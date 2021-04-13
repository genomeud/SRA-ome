#library_strategy LIKE 'RNA-seq' AND 
#library_source LIKE 'METATRANSCRIPTOMIC'"
onlyq <- dbGetQuery(
    con, paste(
        "SELECT * 
        FROM experiment"
    , sep=""));