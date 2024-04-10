select 'title' as component
  , 'Available tables' as contents;

select 
'text' as component,
name as title
  , (
    select string_agg(quote_ident(c."column") || '::' || type || '--' || coalesce(extra_description::text, 'NULL') || '--' || coalesce(conkey::text, 'NULL'), E',\n' order by c.order_nr asc)
    from _wb_visible_column c
    where attrelid = relid) as contents
    , table_link
  from _wb_visible_table
