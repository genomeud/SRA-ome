
-- JUST THE EXAMPLE OF THE FILE

start transaction;

insert into KrakenRecord
(Collection, CollectionDate, RootedFragmentNum, DirectFragmentNum, TaxonID)
values
('Standard-16','2020-12-02',2800088473,1126541,1),
('Standard-16','2020-12-02',2773176487,354392,131567),
('Standard-16','2020-12-02',2448467995,3920764,2),
('Standard-16','2020-12-02',1221804898,3755066,1224),
('Standard-16','2020-12-02',588067452,2197960,1236),
('Standard-16','2020-12-02',161722785,12292,72274),
('Standard-16','2020-12-02',132844049,107521,135621),
('Standard-16','2020-12-02',130208987,23715146,286),
('Standard-16','2020-12-02',30139413,5389434,196821),
('Standard-16','2020-12-02',530906,530906,1028989),
('Standard-16','2020-12-02',527804,527804,2599595),
('Standard-16','2020-12-02',3,3,77644);

commit;
