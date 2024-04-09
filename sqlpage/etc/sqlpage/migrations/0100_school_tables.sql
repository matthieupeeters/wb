
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

