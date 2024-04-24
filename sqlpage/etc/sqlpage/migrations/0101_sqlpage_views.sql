create view _wb_visible_table as
select oid as relid
  , relnamespace::regnamespace::text as schema
  , relname::text as name
  , extra_description
from pg_class
join _wb_table_extra_description
on relnamespace::regnamespace::name = _wb_table_extra_description."schema"
and relname::name = _wb_table_extra_description."table"
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


/*
The extra_description properties are:

spellcheck: boolean
title: text (description of the use of the type)
max: text (maximum value, date, time, int, float)
min: text (min...)
maxlength: int (maximum string length)
minlength: int (min...)
pattern: text (regexp pattern for input)
multiple: bool (type can contain multiple values, like an array or such)
required: bool
type: text (html input type)
value: text (html input default value)
disabled: bool (html input should not be used/changed)
sql_type: text
cast: text (cast to this type before showing)
label: text (displayed name of the column)
name: text (name of the input-field)
primary_key: bool (column is PK)
*/


create view sqlpage_files as
select 
    ('table_' || "name" || '.sql')::varchar(255) as path
  , ('
select ''shell'' as component;
select ''crud_table'' as component
    , ''This is an overview of table ' || name || ''' as description
    , true as sort
    , true as search
    , extra_description as extra_description
from _wb_visible_table 
where "schema" = ' || quote_literal(schema) || '
and "name" = ' || quote_literal(name) || ' 
; ' || '

select ' || (select string_agg(quote_ident("column"), ', '
  order by order_nr)
from _wb_visible_column
where attrelid = relid) || 'from ' || quote_ident(schema) || '.' || quote_ident(name))::text::bytea as contents
, now()::timestamptz as last_modified
from _wb_visible_table;
