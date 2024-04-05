create domain email as text constraint nullable null constraint pattern check (value ~ '^[\u0080-\U0010ffffa-zA-Z0-9.!#$%&''*+\/=?^_`{|}~-]{1,64}@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$')
-- Taken from
-- https://html.spec.whatwg.org/multipage/input.html#e-mail-state-(type=email)
-- so not according to RFC 5322. See justification there.
-- also, don't allow crazy long addresses.
constraint maxlength check (length(value) <= 320) constraint minlength check (length(value) >= 3);

comment on domain email is 'Used to contain valid email addresses. ';

create domain ident as uuid;

comment on domain ident is 'Used for primary keys and references to them. ';

create domain tel as text constraint pattern check (value ~ '^\+((?:9[679]|8[035789]|6[789]|5[90]|42|3[578]|2[1-689])|9[0-58]|8[1246]|6[0-6]|5[1-8]|4[013-9]|3[0-469]|2[70]|7|1)(?:\W*\d){0,13}\d$')
-- don't allow crazy long or useless short numbers
constraint maxlength check (length(value) <= 50) constraint minlength check (length(value) >= 5);

comment on domain tel is 'Valid international telephone number, must start with +country code, e.g. "+316..". ';

create table _record (
  id ident primary key default gen_random_uuid ()
  , _created_by name default current_role
  , _created timestamptz default now()
  , _updated_by name default current_role
  , _updated timestamptz default now()
);

create table "School" (
  "Naam" text
  , "Hoofd adres" text
  , "Telefoon nummer" tel
  , primary key (id)
)
inherits (
  _record
);

comment on table "School" is 'Scholen ';

create table "Eigenschap" (
  "Naam" text
  , "Beschrijving" text
  , primary key (id)
)
inherits (
  _record
);

comment on table "Eigenschap" is 'De eigenschap van een school waar ouders in geïnteresseerd zijn. ';

create table "Score" (
  "School_id" uuid
  , constraint "Score van school" foreign key ("School_id") references "School" (id)
  , "Eigenschap_id" uuid
  , constraint "Score in eigenschap" foreign key ("Eigenschap_id") references "Eigenschap" (id)
  , "Aantal uren per week" bigint default null
  , "Waarde" double precision default null
  , "Beschikbaar" bool default null
  , constraint "Slechts een waarde ingevuld" check (1 = (
  case when "Aantal uren per week" is null then
    0
  else
    1
  end + case when "Waarde" is null then
    0
  else
    1
  end + case when "Beschikbaar" is null then
    0
  else
    1
  end))
  , primary key (id)
)
inherits (
  _record
);

