-- Store extra_description in the comment string as a JSON object. Of this object only the property "sqlpage" is used. Anything else is ignored, although suggested is to use a property "comment" for the normal comments for the user.
-- The "sqlpage" property is an object containing:
/*
{

 "label": "text",  // Better readable name for the column, to be presented to the user. Not useful for type/domain but useful for table/view. Defaults to column name.
 "inputmode": "text", // Used in rare cases, hint for the browser for the kind of keyboard (numeric? text?) to display. See the HTML standard.  
 "lang": "text", // [fn:override]Goes into the "lang" attribute, reserved for the [[i18n system]] .
 "spellcheck": true/false, // Directly into the "spellcheck" attribute. Defaults to true for "text" fields, false otherwise.
 "title": "text", // Mouse hoover over to describe what is allowed. Used in the "title" attribute of the input element. Defaults to "type", typname, pattern
 "autocomplete": "text", // filled with a suitable hints for the browser. Use for registration and login. See [[https://html.spec.whatwg.org/#attr-fe-autocomplete]]. Default unused. 
 "disabled": true/false, // [fn:override:Should be overwritten by the processor] Indicates that the input-element cannot be changed and will not be committed. 
 "max": "text", // The maximum value of the input. Defaults to analysis of the domain, then of the type. 
 "min": "text", // idem for minimum
 "maxlength": int, // The maximum length of the input. Defaults to analysis of the domain, then of the type.
 "minlength":int, // idem for minimum
 "multiple": true/false, // Allow multiple values to be selected or input. Defaults to true if the type is an array.
 "name": "text", // Always the column name. 
 "pattern": "text", // Defaults to the check of the domain. 
 "placeholder": "text", // Some suggestion of what to fill into the input-box, but not an example or pre-fill.
 "required": true/false, // Defaults to whether the table-column or the type is nullable. 
 "size": int, // Length of the input box. Defaults to the average of maxlength and minlength. 
 "step": int, // Allow only input values that are a multiple of "step" distanced from each other. Especially useful for time/date etc. 
 "type": "text", // Refers to the value that goes into the "type" attribute of the input element. See [[html-input-types]]. Defaults to the typname if it is a html-input-type, otherwise "text".
 "value": "", // [fn:override]The default value of the field. Defaults to the default of the table, then the default of the domain. Note that this has to be evaluated at runtime! Because of random strings and such. 
 "filter value": "", // The default value of the field when used in a filter. This is to support the "eq." etc. prefixes that PostgREST requires. 
 "cast": "text", // The type to which this value should be cast to be shown in HTML via SQLPage. Defaults to "text". 
 "sql_type": "text", // The type to which an input from the frontend should be cast before it is inserted or updated in the database. Just the type of the variable
}'
 */
-- A domain comment is merge-overridden by a table-column comment, a table-column comment is merge-overridden by a view-column comment. An explicit NULL value turns of the setting. Every property is optional.
create or replace function simplified_compare_hash (text)
  returns text
  language sql
  immutable strict leakproof parallel safe
begin
  atomic
  select regexp_replace(lower($1) , '[^a-z0-9]' , '');

end;

comment on function simplified_compare_hash (text) is 'Creates a string that is usable to compare two column-names, for matching view-columns to table-columns. Used in column_extra_description. ';

create or replace function get_constraint_parameter (constraintoid oid , type text)
  returns text
  language sql
  strict parallel safe
begin
  atomic
  select regexp_replace(pg_get_constraintdef(constraintoid) , case when type = 'pattern' then
        '^.*\~ *\'' (^.* $) \''.*$'
      when type = 'max' then
        '^.*\<\= *([^\)]*)\).*$'
      when type = 'min' then
        '^.*\>\= *([^\)]*)\).*$'
      when type = 'maxlength' then
        '^.*\<\= *([^\)]*)\).*$'
      when type = 'minlength' then
        '^.*\>\= *([0-9]*).*$'
      end , '\1');

end;

comment on function get_constraint_parameter (oid , text) is 'Gets the comparison value of a pattern, max, min, maxlength, or minlenght check constraint. ';

create or replace function extract_sqlpage_jsonb (text)
  returns jsonb
  language sql
  immutable leakproof parallel safe
begin
  atomic
  select 
   case when $1 is null
      or trim($1 , E' \n\r\t') = '' 
      or $1 is not json object 
      or not($1::jsonb ? 'sqlpage') then
      jsonb_build_object()
   else
      $1::jsonb -> 'sqlpage'
   end;
end;

comment on function extract_sqlpage_jsonb (text) is 'Convert postgresql comment string into a jsonb and extract the sqlpage property. ';

create or replace function comment_to_title_jsonb (text)
  returns jsonb
  language sql
  immutable leakproof parallel safe
begin
  atomic
  select case when $1 is null
      or trim($1 , E'  \n\r\t') = ''
      or $1 is json then
      jsonb_build_object()
    else
      jsonb_build_object('title' , $1)
    end;

end;

comment on function comment_to_title_jsonb (text) is 'Use the comment as mouse hoover over text if it is not a json object. ';

create or replace function make_null_jsonb (key text , value anyelement , condition bool = true)
  returns jsonb
  language sql
  immutable leakproof parallel safe
  as $$
  -- not atomic since this function has an anyelement parameter.
  select case when key is null
      or value is null
      or key = ''
      or not (condition) then
      jsonb_build_object()
    else
      jsonb_build_object(key , value)
    end;
$$;

comment on function make_null_jsonb (text , anyelement , bool) is 'Make a key=>value jsonb object or an empty object if either value is NULL or condition is false. ';

create or replace function combine_patterns (a text , b text)
  returns text
  language sql
  immutable leakproof parallel safe
begin
  atomic
  select case when a is null
      or a = '' then
      b
    when b is null
      or b = '' then
      a
    else
      '(?=' || a || ')(?=' || b || ')'
    end;

end;


/*
 Gets the extra_description of a column in a table or view. This is used to generate the html structures, in particular the input element, that describe the field.
 */


  drop view if exists _wb_column_extra_description cascade;
  create or replace view _wb_column_extra_description as
  with recursive html_input_types as materialized (
     values ('button') , ('checkbox') , ('color') , ('date') , ('datetime-local') , ('email') , ('file') , ('hidden')
          , ('image') , ('month') , ('number') , ('password') , ('radio') , ('range') , ('reset') , ('search') 
          , ('submit') , ('tel') , ('text') , ('time') , ('url') , ('week')) 
  , disabled_sql_types as materialized (
    values ('timestamp'), ('timestamp with time zone'), ('timestamp without time zone'))
  , domain_check_constraints as not materialized (
    select pg_type.oid as typid 
      , pattern_constraint.oid as pattern_constraint_oid
      , max_constraint.oid as max_constraint_oid 
      , min_constraint.oid as min_constraint_oid
      , maxlength_constraint.oid as maxlength_constraint_oid 
      , minlength_constraint.oid as minlength_constraint_oid
    from pg_catalog.pg_type
    left join pg_catalog.pg_constraint pattern_constraint on pg_type.oid = pattern_constraint.contypid
      and pattern_constraint.contype = 'c'
      and pattern_constraint.conname = 'pattern'
    left join pg_catalog.pg_constraint max_constraint on pg_type.oid = max_constraint.contypid
      and max_constraint.contype = 'c'
      and max_constraint.conname = 'max'
    left join pg_catalog.pg_constraint min_constraint on pg_type.oid = min_constraint.contypid
      and min_constraint.contype = 'c'
      and min_constraint.conname = 'min'
    left join pg_catalog.pg_constraint maxlength_constraint on pg_type.oid = maxlength_constraint.contypid
      and maxlength_constraint.contype = 'c'
      and maxlength_constraint.conname = 'maxlength'
    left join pg_catalog.pg_constraint minlength_constraint on pg_type.oid = minlength_constraint.contypid
      and minlength_constraint.contype = 'c'
      and minlength_constraint.conname = 'minlength') 
  , column_check_constraints as not materialized (
    select attrelid, attnum
      , pattern_constraint.oid as pattern_constraint_oid , max_constraint.oid as max_constraint_oid
      , min_constraint.oid as min_constraint_oid , maxlength_constraint.oid as maxlength_constraint_oid
      , minlength_constraint.oid as minlength_constraint_oid
    from pg_catalog.pg_attribute
    left join pg_catalog.pg_constraint pattern_constraint on pg_attribute.attrelid = pattern_constraint.conrelid
      and pattern_constraint.contype = 'c'
      and pattern_constraint.conname = attname || '_pattern'
    left join pg_catalog.pg_constraint max_constraint on pg_attribute.attrelid = max_constraint.conrelid
      and max_constraint.contype = 'c'
      and max_constraint.conname = attname || '_max'
    left join pg_catalog.pg_constraint min_constraint on pg_attribute.attrelid = min_constraint.conrelid
      and min_constraint.contype = 'c'
      and min_constraint.conname = attname || '_min'
    left join pg_catalog.pg_constraint maxlength_constraint on pg_attribute.attrelid = maxlength_constraint.conrelid
      and maxlength_constraint.contype = 'c'
      and maxlength_constraint.conname = attname || '_maxlength'
    left join pg_catalog.pg_constraint minlength_constraint on pg_attribute.attrelid = minlength_constraint.conrelid
      and minlength_constraint.contype = 'c'
      and minlength_constraint.conname = attname || '_minlength'
    where not (attisdropped)) 
  , domain_extra_description as not materialized (
    select pg_type.oid as typid
      , make_null_jsonb('spellcheck', typname = 'text')
     || make_null_jsonb('title', typname)
     || make_null_jsonb('title', html_input_types.column1)
     || comment_to_title_jsonb(description)
     || make_null_jsonb('max', get_constraint_parameter(max_constraint_oid, 'max'))
     || make_null_jsonb('min', get_constraint_parameter(min_constraint_oid, 'min'))
     || make_null_jsonb('maxlength', get_constraint_parameter(maxlength_constraint_oid, 'maxlength')::bigint)
     || make_null_jsonb('minlength', get_constraint_parameter(minlength_constraint_oid, 'minlength')::bigint)
     || make_null_jsonb('pattern', get_constraint_parameter(pattern_constraint_oid, 'pattern'))
     || make_null_jsonb('multiple', typndims <> 0, typndims <> 0)
     || make_null_jsonb('required', typnotnull, typnotnull)
     || make_null_jsonb('type', coalesce(html_input_types.column1, 'text'))
     || make_null_jsonb('value', typdefault)
     || make_null_jsonb('filter value', case when typname = 'text' then 'ilike.' else 'eq.' end)
     || make_null_jsonb('disabled', true, disabled_sql_types.column1 is not null)
     || make_null_jsonb('sql_type', pg_type.typname)
     || make_null_jsonb('cast', 'text'::text)
     || extract_sqlpage_jsonb(description) as extra_description
    from pg_catalog.pg_type
    left join pg_catalog.pg_description on pg_type.oid = pg_description.objoid
    left join domain_check_constraints on pg_type.oid = domain_check_constraints.typid
    left join html_input_types on html_input_types.column1 = typname
    left join disabled_sql_types on disabled_sql_types.column1 = typname) 
  , column_dependency as not materialized (
    select dependent_attribute.attrelid as dep_attrelid
         , dependent_attribute.attnum as dep_attnum
         , referred_attribute.attrelid as ref_attrelid
         , referred_attribute.attnum as ref_attnum
    from pg_depend 
    join pg_rewrite on pg_depend.objid = pg_rewrite.oid 
    join pg_attribute referred_attribute on pg_depend.refobjid = referred_attribute.attrelid 
    and pg_depend.refobjsubid = referred_attribute.attnum 
    cross join lateral (
      select * from pg_attribute 
      where pg_rewrite.ev_class = pg_attribute.attrelid
      and pg_attribute.atttypid = referred_attribute.atttypid
      and simplified_compare_hash(pg_attribute.attname) = simplified_compare_hash(pg_attribute.attname)
      order by pg_attribute.attname = referred_attribute.attname desc
             , lower(pg_attribute.attname) = lower(referred_attribute.attname) desc
             , pg_attribute.attnum = referred_attribute.attnum desc
      limit 1) as dependent_attribute)
  , cte_column_extra_description as (
    select pg_attribute.attrelid
         , pg_attribute.attnum 
         , coalesce(domain_extra_description.extra_description, '{}'::jsonb)
        || make_null_jsonb('label', pg_attribute.attname) 
        || make_null_jsonb('disabled', true, attgenerated <> '')
        || make_null_jsonb('max', least(get_constraint_parameter(max_constraint_oid, 'max'), extra_description->>'max'))
        || make_null_jsonb('min', greatest(get_constraint_parameter(min_constraint_oid, 'min'), extra_description->>'min'))
        || make_null_jsonb('maxlength', least(get_constraint_parameter(maxlength_constraint_oid, 'maxlength')::bigint, (extra_description->>'maxlength')::bigint))
        || make_null_jsonb('minlength', greatest(get_constraint_parameter(minlength_constraint_oid, 'minlength')::bigint, (extra_description->>'minlength')::bigint))
        || make_null_jsonb('pattern', combine_patterns(get_constraint_parameter(pattern_constraint_oid, 'pattern'), extra_description->>'pattern'))
        || make_null_jsonb('multiple', attndims <> 0, attndims <> 0)
        || make_null_jsonb('name', attname)
        || make_null_jsonb('required', attnotnull, attnotnull)
        || make_null_jsonb('value', pg_get_expr(adbin, adrelid), atthasdef)
        || make_null_jsonb('primary_key', pkconstraint.contype = 'p')
        || extract_sqlpage_jsonb(description) as extra_description
        , pkconstraint.conkey
    from pg_catalog.pg_attribute
    join domain_extra_description
    on pg_attribute.atttypid = domain_extra_description.typid
    left join column_check_constraints
    on pg_attribute.attrelid = column_check_constraints.attrelid
    and pg_attribute.attnum = column_check_constraints.attnum
    left join pg_catalog.pg_attrdef on pg_attribute.attrelid = adrelid and pg_attribute.attnum = adnum
    left join pg_catalog.pg_description on pg_attribute.attrelid = classoid and pg_attribute.attnum = objsubid
    left join pg_catalog.pg_constraint pkconstraint 
    on pkconstraint.contype = 'p' 
    and pg_attribute.attrelid = pkconstraint.conrelid 
    and pkconstraint.conindid is not null
    and pg_attribute.attnum = any (pkconstraint.conkey)
    where pg_attribute.attnum >= 0) 
  , recursive_cte_column_extra_description (extra_description, attrelid, attnum, conkey) 
    as (select extra_description, attrelid, attnum, conkey
        from cte_column_extra_description
        left join column_dependency on column_dependency.dep_attrelid = cte_column_extra_description.attrelid
        and column_dependency.dep_attnum = cte_column_extra_description.attnum
        where column_dependency.dep_attrelid is null
        union all
        select r.extra_description || d.extra_description extra_description, d.attrelid, d.attnum, d.conkey
        from cte_column_extra_description d
        join column_dependency on column_dependency.dep_attrelid = d.attrelid 
        and column_dependency.dep_attnum = d.attnum
        join recursive_cte_column_extra_description r on column_dependency.ref_attrelid = r.attrelid
        and column_dependency.ref_attnum = r.attnum ) 
  select extra_description, pg_attribute.attrelid, pg_attribute.attnum, pg_namespace.nspname schema, pg_class.relname table, attname column, conkey
  from recursive_cte_column_extra_description 
  join pg_catalog.pg_attribute on recursive_cte_column_extra_description.attrelid = pg_attribute.attrelid 
  and recursive_cte_column_extra_description.attnum = pg_attribute.attnum
  join pg_catalog.pg_class on pg_attribute.attrelid = pg_class.oid
  join pg_catalog.pg_namespace on pg_class.relnamespace = pg_namespace.oid;


  create or replace view _wb_table_extra_description as
    select schema, "table", 
      jsonb_build_object('caption', "table",
        'columns', jsonb_agg(extra_description order by attnum),
        'caption', "table",  -- Equivalent of column-label
        'name' , "table")
     || comment_to_title_jsonb((select description from pg_description where objoid = attrelid and objsubid = 0))
      as extra_description
    from _wb_column_extra_description
    group by schema, "table", attrelid;



