
create or replace function get_percentage(
    numerator    bigint,
    denominator  bigint
)
returns decimal
language plpgsql as
$$
begin
    return trunc((numerator::decimal / denominator), 4) * 100;
end;
$$;
