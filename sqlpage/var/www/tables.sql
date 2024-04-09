select 'list' as component
  , 'Available tables' as title;

select name as title
  , (
    select string_agg(quote_ident(c."column") || '::' || type || '--' || extra_description::text || '--' || conkey::text, E',\n' order by c.order_nr asc)
    from _wb_visible_column c
    where attrelid = relid) as description
    , table_link
  from _wb_visible_table
