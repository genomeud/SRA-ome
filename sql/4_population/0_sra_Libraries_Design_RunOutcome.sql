
start transaction;

-- libraries
insert into LibrarySource
(LibrarySource)
values
('GENOMIC'),
('GENOMIC SINGLE CELL'),
('METAGENOMIC'),
('METATRANSCRIPTOMIC'),
('OTHER'),
('SYNTHETIC'),
('TRANSCRIPTOMIC'),
('TRANSCRIPTOMIC SINGLE CELL'),
('VIRAL RNA');

insert into LibraryLayout
(LibraryLayout)
values
('SINGLE'),
('PAIRED');

insert into LibrarySelection
(LibrarySelection)
values
('5-methylcytidine antibody'),
('CAGE'),
('cDNA'),
('ChIP'),
('ChIP-Seq'),
('DNase'),
('HMPR'),
('Hybrid Selection'),
('Inverse rRNA'),
('MBD2 protein methyl-CpG binding domain'),
('MDA'),
('MF'),
('MNase'),
('MSLL'),
('Oligo-dT'),
('other'),
('padlock probes capture method'),
('PCR'),
('PolyA'),
('RACE'),
('RANDOM'),
('RANDOM PCR'),
('Reduced Representation'),
('repeat fractionation'),
('Restriction Digest'),
('RT-PCR'),
('size fractionation'),
('unspecified');

insert into LibraryStrategy
(LibraryStrategy)
values
('AMPLICON'),
('ATAC-seq'),
('Bisulfite-Seq'),
('ChIA-PET'),
('ChIP'),
('ChIP-Seq'),
('CLONE'),
('CLONEEND'),
('CTS'),
('DNase-Hypersensitivity'),
('EST'),
('FAIRE-seq'),
('FINISHING'),
('FL-cDNA'),
('GBS'),
('Hi-C'),
('MBD-Seq'),
('MeDIP-Seq'),
('miRNA-Seq'),
('MNase-Seq'),
('MRE-Seq'),
('ncRNA-Seq'),
('OTHER'),
('POOLCLONE'),
('RAD-Seq'),
('RIP-Seq'),
('RNA-Seq'),
('SELEX'),
('Synthetic-Long-Read'),
('Targeted-Capture'),
('Tethered Chromatin Conformation Capture'),
('Tn-Seq'),
('VALIDATION'),
('WCS'),
('WES'),
('WGA'),
('WGS'),
('WXS');

-- design
insert into Platform
(PlatformName)
values
('ABI_SOLID'),
('BGISEQ'),
('CAPILLARY'),
('COMPLETE_GENOMICS'),
('HELICOS'),
('ILLUMINA'),
('ION_TORRENT'),
('LS454'),
('OXFORD_NANOPORE'),
('PACBIO_SMRT');

insert into Instrument
(PlatformName, InstrumentName)
values
('ABI_SOLID',         'AB 310 Genetic Analyzer'),
('ABI_SOLID',         'AB 3130 Genetic Analyzer'),
('ABI_SOLID',         'AB 3130xl Genetic Analyzer'),
('ABI_SOLID',         'AB 3500 Genetic Analyzer'),
('ABI_SOLID',         'AB 3500xl Genetic Analyzer'),
('ABI_SOLID',         'AB 3730 Genetic Analyzer'),
('ABI_SOLID',         'AB 3730xl Genetic Analyzer'),
('ABI_SOLID',         'AB 5500 Genetic Analyzer'),
('ABI_SOLID',         'AB 5500xl Genetic Analyzer'),
('ABI_SOLID',         'AB 5500xl w genetic analysis system'),
('ABI_SOLID',         'AB SOLiD 3 Plus System'),
('ABI_SOLID',         'AB SOLiD 4 System'),
('ABI_SOLID',         'AB SOLiD 4hq System'),
('ABI_SOLID',         'AB SOLiD PI System'),
('ABI_SOLID',         'AB SOLiD System 2.0'),
('ABI_SOLID',         'AB SOLiD System 3.0'),
('ABI_SOLID',         'AB SOLiD System'),
('ABI_SOLID',         'unspecified'),
('BGISEQ',            'BGISEQ-50'),
('BGISEQ',            'BGISEQ-500'),
('BGISEQ',            'DNBSEQ-G400'),
('BGISEQ',            'DNBSEQ-G50'),
('BGISEQ',            'DNBSEQ-T7'),
('BGISEQ',            'unspecified'),
('CAPILLARY',         'unspecified'),
('COMPLETE_GENOMICS', 'Complete Genomics'),
('COMPLETE_GENOMICS', 'unspecified'),
('HELICOS',           'Helicos HeliScope'),
('HELICOS',           'unspecified'),
('ILLUMINA',          'HiSeq X Five'),
('ILLUMINA',          'HiSeq X Ten'),
('ILLUMINA',          'Illumina Genome Analyzer II'),
('ILLUMINA',          'Illumina Genome Analyzer IIx'),
('ILLUMINA',          'Illumina Genome Analyzer'),
('ILLUMINA',          'Illumina HiScanSQ'),
('ILLUMINA',          'Illumina HiSeq 1000'),
('ILLUMINA',          'Illumina HiSeq 1500'),
('ILLUMINA',          'Illumina HiSeq 2000'),
('ILLUMINA',          'Illumina HiSeq 2500'),
('ILLUMINA',          'Illumina HiSeq 3000'),
('ILLUMINA',          'Illumina HiSeq 4000'),
('ILLUMINA',          'Illumina HiSeq X Five'),
('ILLUMINA',          'Illumina HiSeq X Ten'),
('ILLUMINA',          'Illumina iSeq 100'),
('ILLUMINA',          'Illumina MiniSeq'),
('ILLUMINA',          'Illumina MiSeq'),
('ILLUMINA',          'Illumina NovaSeq 6000'),
('ILLUMINA',          'NextSeq 1000'),
('ILLUMINA',          'NextSeq 2000'),
('ILLUMINA',          'NextSeq 500'),
('ILLUMINA',          'NextSeq 550'),
('ILLUMINA',          'unspecified'),
('ION_TORRENT',       'Ion S5 XL'),
('ION_TORRENT',       'Ion S5'),
('ION_TORRENT',       'Ion Torrent PGM'),
('ION_TORRENT',       'Ion Torrent Proton'),
('ION_TORRENT',       'Ion Torrent S5 XL'),
('ION_TORRENT',       'Ion Torrent S5'),
('ION_TORRENT',       'unspecified'),
('LS454',             '454 GS 20'),
('LS454',             '454 GS FLX Titanium'),
('LS454',             '454 GS FLX'),
('LS454',             '454 GS FLX+'),
('LS454',             '454 GS Junior'),
('LS454',             '454 GS'),
('LS454',             'unspecified'),
('OXFORD_NANOPORE',   'GridION'),
('OXFORD_NANOPORE',   'MinION'),
('OXFORD_NANOPORE',   'PromethION'),
('OXFORD_NANOPORE',   'unspecified'),
('PACBIO_SMRT',       'PacBio RS II'),
('PACBIO_SMRT',       'PacBio RS'),
('PACBIO_SMRT',       'Sequel II'),
('PACBIO_SMRT',       'Sequel'),
('PACBIO_SMRT',       'unspecified');

-- run outcome
insert into RunOutcome
(RunOutcome)
values
('OK'),
('ERR'),
('IGNORE'),
('TODO');

commit;
