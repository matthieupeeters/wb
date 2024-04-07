-- The comments can contain a normal string, or a JSON object that has the property "sqlpage". That property should be a JSON object as described in extra_description
-- Maybe not used for WB
drop domain if exists "text/html" cascade;

create domain "text/html" as text constraint balanced_single_quotes check (regexp_count (value , '''') & 1 = 0) constraint balanced_angle_brackets check (regexp_count (value , '<') = regexp_count (value , '>'));

comment on domain "text/html" is 'Used to instruct PostgREST that the results of requests are of the correct type. ';

-- Maybe not used for WB
-- There are two levels of dynamism.
-- 1. When the schemata are changed
-- 2. When the query is executed.
drop domain if exists dhtml cascade;

create domain dhtml as text constraint balanced_single_quotes check (regexp_count (value , '''') & 1 = 0) constraint balanced_angle_brackets check (regexp_count (value , '<') = regexp_count (value , '>'));

comment on domain "dhtml" is 'Used to contain a string that has concatenation for column names inlined with ...'' || abc_html.escape(schema.table.column) || ''...  ';

-- Maybe not used for WB
drop domain if exists hashed_token cascade;

create domain hashed_token as bytea constraint long_enough_hashed_token check (length(value) >= 48);

comment on domain hashed_token is 'Used to store the raw_tokens in a safer manner. ';

drop domain if exists raw_token cascade;

create domain raw_token as text not null default encode(gen_random_bytes(32) , 'base64') constraint minlength check (length(value) >= 44);

-- base64 encoded 32 bytes.
comment on domain raw_token is 'Used to contain random tokens. Use the default value to generate. ';

-- Used for WB as well.
drop domain if exists ident cascade;

create domain ident as uuid;

comment on domain ident is 'Used for primary keys and references to them. ';

drop domain if exists email cascade;

create domain email as citext constraint nullable null constraint pattern check (value ~ '^[\u0080-\U0010ffffa-zA-Z0-9.!#$%&''*+\/=?^_`{|}~-]{1,64}@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$')
-- Taken from
-- https://html.spec.whatwg.org/multipage/input.html#e-mail-state-(type=email)
-- so not according to RFC 5322. See justification there.
constraint maxlength check (length(value) <= 320) constraint minlength check (length(value) >= 3);

-- also, don't allow crazy long addresses.
comment on domain email is 'Used to contain valid email addresses. ';

drop domain if exists tel cascade;

create domain tel as text constraint pattern check (value ~ '^\+((?:9[679]|8[035789]|6[789]|5[90]|42|3[578]|2[1-689])|9[0-58]|8[1246]|6[0-6]|5[1-8]|4[013-9]|3[0-469]|2[70]|7|1)(?:\W*\d){0,13}\d$') constraint maxlength check (length(value) <= 50) constraint minlength check (length(value) >= 5);

-- don't allow crazy long or useless short numbers
comment on domain tel is 'Valid international telephone number, must start with +country code, e.g. "+316..". ';

drop domain if exists password cascade;

create domain password as text constraint minlength check (length(value) >= 8);

comment on domain password is '{"comment": "Used to store the raw password or the encrypted password. ", sqlpage: {"autocomplete": "new-password"}}';

drop domain if exists url cascade;

create domain url as text constraint minlength check (length(value) >= 7) constraint maxlength check (length(value) <= 2083) constraint pattern check (value ~ '^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&''\(\)\*\+,;=.]+$');

comment on domain url is 'Used to store a url. ';

