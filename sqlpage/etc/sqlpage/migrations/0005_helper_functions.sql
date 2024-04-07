create or replace function decode_percent_hex (text)
  returns text
  language sql
  strict immutable leakproof parallel safe
begin
  atomic
  select convert_from(string_agg(
        case when ordinality = 1 then
          replace(a , '+' , ' ')::bytea
        else
          decode(substr(a , 1 , 2) , 'hex')::bytea || replace(substr(a , 3) , '+' , ' ')::bytea
        end::bytea , '') , 'UTF8')
  from string_to_table ($1 , '%')
  with ordinality a;

end;

grant execute on function decode_percent_hex (text) to public;

create or replace function encode_percent_hex_char (char)
  returns text
  language sql
  strict immutable leakproof parallel safe
begin
  atomic
  select string_agg('%' || substring(encode($1::bytea , 'hex')
        from n for 2) , '')
  from generate_series(1 , length($1::bytea) * 2 , 2) n;

end;

grant execute on function encode_percent_hex_char (char) to public;

create or replace function encode_percent_hex (text)
  returns text
  language sql
  strict immutable leakproof parallel safe
begin
  atomic
  select string_agg(
      case when c = ' ' then
        '+'
      when a between ascii('0')
      and ascii('9')
        or a between ascii('A')
        and ascii('Z')
        or a between ascii('a')
        and ascii('z')
        or a in (ascii('-') , ascii('_') , ascii('.') , ascii('~')) then
        c
      else
        encode_percent_hex_char (c)
      end , '')
  from (
    select ascii(c) a
      , c
    from string_to_table ($1 , null) c) as split_string;

end;

grant execute on function encode_percent_hex (text) to public;

create or replace function parse_querystring (text)
  returns jsonb
  language sql
  parallel safe
begin
  atomic with split as (
    select split_part(s , '=' , 1) k
      , substr(s , strpos(s , '=') + 1) v
    from unnest(string_to_array(ltrim($1 , '?') , '&')) s
)
, arrayed as (
  select
    left (k
      , -2)
    key
    , jsonb_agg(decode_percent_hex (v)) val
  from split
  where
    right (k , 2) = '[]'
  group by k
  union
  select k key
    , to_jsonb (decode_percent_hex (v)) val
  from split
  where
    right (k , 2) <> '[]'
)
select coalesce(jsonb_object_agg(key , val) , '{}'::jsonb)
from arrayed;

end;

grant execute on function parse_querystring (text) to public;

