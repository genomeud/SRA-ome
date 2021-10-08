-- very useful in conjunction with get_reports_from_xxx_accession()
-- example (to see only Betacoronavirus or his descendants):
-- select *
-- from get_reports_from_run_accession('SRR12596172', 60)
-- where '694002' in (
--    select TaxonID from get_ancestors(taxidreport)
-- );


create or replace function get_ancestors(
  _taxon_id dom_taxon_id
)
returns table(
  Rank            dom_rank, 
  Level           integer, 
  TaxonID         dom_taxon_id,
  TaxonName       dom_taxon_name
)
language sql as
$$
  WITH RECURSIVE Lineage AS (
      SELECT Rank, 0 as Level, TaxonID, ParentTaxonID, TaxonName
        FROM Taxon
        WHERE TaxonID = _taxon_id
    UNION ALL
      SELECT t.Rank, l.Level + 1 AS Level, t.TaxonID, t.ParentTaxonID, t.TaxonName
        FROM Taxon t
        JOIN Lineage l ON (t.TaxonID = l.ParentTaxonID and t.TaxonName <> 'root')
  )
  SELECT Rank, Level, TaxonID, TaxonName
  FROM Lineage
  ORDER BY Level desc;
$$;
