create view _wb_visible_table as
select oid as relid
  , relnamespace::regnamespace::text as schema
  , relname::text as name
  , 'table_' || relname || '.sql'::text as table_link
from pg_class
where (relnamespace::regnamespace)::text = current_schema()
  and substr(relname , 1 , 1) <> '_'
  and substr(relname , 1 , 8) <> 'sqlpage_'
  and relkind in ('r' , 'v' , 'm');

create view _wb_visible_column as
select pg_attribute.attrelid
  , pg_attribute.atttypid::regtype::text type
  , pg_attribute.attnum order_nr
  , extra_description
  , "schema", "table", "column"
  , conkey
from pg_attribute
left join _wb_column_extra_description
on pg_attribute.attrelid = _wb_column_extra_description.attrelid
and pg_attribute.attnum = _wb_column_extra_description.attnum
where not (attisdropped)
  and pg_attribute.attnum > 0
  and substr(pg_attribute.attname , 1 , 1) <> '_'
  and substr(pg_attribute.attname , 1 , 8) <> 'sqlpage_';


create view sqlpage_files as
select table_link::varchar(255) as path
  , ('select ''table'' as component
    , ''This is an overview of table ' || name || ''' as description
    , true as sort
    , true as search;

' || '
select ' || (select string_agg(quote_ident("column"), ', '
  order by order_nr)
from _wb_visible_column
where attrelid = relid) || 'from ' || quote_ident(schema) || '.' || quote_ident(name))::text::bytea as contents
, now()::timestamptz as last_modified
from _wb_visible_table;

