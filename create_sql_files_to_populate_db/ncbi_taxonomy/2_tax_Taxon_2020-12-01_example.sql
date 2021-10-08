
-- JUST THE EXAMPLE OF THE FILE

start transaction;

insert into Taxon
(TaxonID, ParentTaxonID, Rank, TaxonName)
values
('1','1','no rank',E'root'),
('2','131567','superkingdom',E'Bacteria'),
('6','335928','genus',E'Azorhizobium'),
('7','6','species',E'Azorhizobium caulinodans'),
('9','32199','species',E'Buchnera aphidicola'),
('10','1706371','genus',E'Cellvibrio'),
('11','1707','species',E'Cellulomonas gilvus'),
('13','203488','genus',E'Dictyoglomus'),
('14','13','species',E'Dictyoglomus thermophilum'),
('16','32011','genus',E'Methylophilus'),
('17','16','species',E'Methylophilus methylotrophus'),
('18','213421','genus',E'Pelobacter'),
('19','18','species',E'Pelobacter carbinolicus'),
('2793152','2793151','species',E'Asbjornsenia pygmaea');

commit;
