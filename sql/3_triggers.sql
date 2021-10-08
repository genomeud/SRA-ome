start transaction;

create or replace function trigger_run_default_runoutcome()
  returns trigger
  language plpgsql as
$$
begin
     
    if (new.Consent <> 'public' and new.RunOutcome = 'TODO')
    then
        new.RunOutcome = 'IGNORE';
    end if;

    return new;

end
$$;

create or replace function trigger_run_default_consent()
  returns trigger
  language plpgsql as
$$
begin
    if new.Consent is null then
        new.Consent = 'public';
    end if;

    return new;
end
$$;

create trigger run_default_consent
before insert on Run
for each row
execute procedure trigger_run_default_consent();

create trigger run_default_runoutcome
before insert on Run
for each row
execute procedure trigger_run_default_runoutcome();

-- todo add trigger on insert taxon
-- if <rank, parentrank> not in lineage
-- then add to lineage if
--    (rank.rankindex > parentrank.rankindex) or
--    (rank = clade) or (parentrank = clade) or 
--    (rank = no rank) or (parentrank = no rank)
-- else kill

commit;
