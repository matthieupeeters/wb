insert into "School" ("Naam" , "Hoofd adres" , "Telefoon nummer")
  values ('De Boomtak' , 'Maarten Reuchlinlaan 9, 5626 GP Eindhoven, Nederland' , '+31401234567')
  , ('De Boomstronk' , 'Zuiderkruispad 1, 5632 DE Eindhoven, Nederland' , '+31401234567')
  , ('De Boomslag' , 'Picassohof 33, 5613 JG Eindhoven, Nederland' , '+31401234567')
  , ('De Boom' , 'Bennekelstraat 22, 5654 DG Eindhoven, Nederland' , '+31401234567');

insert into "Eigenschap" ("Naam" , "Beschrijving")
  values ('Vis fileren' , 'Aantal uren vis-fileren per week. ')
  , ('VWO resultaten' , 'Percentage leerlingen naar VWO.')
  , ('Warme lunch' , 'Heeft een warme maaltijd tijdens de grote pauze. ')
  , ('Schoolbus' , 'Kinderen worden thuis opgehaald. ')
  , ('Omvang klas' , 'Maximaal aantal leerlingen per docent. ');

insert into "Score" ("School_id" , "Eigenschap_id" , "Aantal uren per week")
select "School".id
  , "Eigenschap".id
  , (random() * 10)::bigint
from "School"
  , "Eigenschap"
where "Eigenschap"."Naam" = 'Vis fileren';

insert into "Score" ("School_id" , "Eigenschap_id" , "Waarde")
select "School".id
  , "Eigenschap".id
  , (random() * 20)::bigint
from "School"
  , "Eigenschap"
where "Eigenschap"."Naam" = 'VWO resultaten';

insert into "Score" ("School_id" , "Eigenschap_id" , "Beschikbaar")
select "School".id
  , "Eigenschap".id
  , (random() * 2) < 1
from "School"
  , "Eigenschap"
where "Eigenschap"."Naam" in ('Warme lunch' , 'Schoolbus');

insert into "Score" ("School_id" , "Eigenschap_id" , "Waarde")
select "School".id
  , "Eigenschap".id
  , (random() * 50)::bigint
from "School"
  , "Eigenschap"
where "Eigenschap"."Naam" = 'Omvang klas';

