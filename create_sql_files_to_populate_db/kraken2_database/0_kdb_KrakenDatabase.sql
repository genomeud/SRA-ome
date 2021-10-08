start transaction;

insert into KrakenDatabase
(Collection, CollectionDate, ArchiveSizeGB, IndexSizeGB, CappedAtGB)
values
('Standard-16','2020-12-02','11.2','14.9','16');

commit;
