
create or replace function get_lineage(
  _taxon_id dom_taxon_id
)
returns text
language sql as
$$
  select case
         when (_taxon_id) = (ParentTaxonID)
         then TaxonName
         else get_lineage(ParentTaxonID) || ', ' || TaxonName
         end
    from Taxon
   where (TaxonID) = (_taxon_id);
$$;
