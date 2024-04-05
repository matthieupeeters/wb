select 'list' as component
  , 'Available tables' as title;

select name as title
  , (
    select string_agg(quote_ident(c.name) || ' ' || type , ', ' order by c.order_nr asc)
    from _wb_visible_column c
    where attrelid = relid) as description
    , link
  from _wb_visible_table
