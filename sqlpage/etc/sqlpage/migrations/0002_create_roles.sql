-- Users needed for the WB application should be defined here.
create or replace function abc_ensure_role (role name , comment text , password text default null , role_attributes text default null)
  returns void
  language plpgsql
  as $$
declare
  dquery text = '';
begin
  if not exists (
    select 1
    from pg_roles
    where rolname = role) then
  dquery := 'create role ' || quote_ident(role) || ';';
  execute dquery;
end if;
  dquery := 'alter role ' || quote_ident(role) || ' nosuperuser nocreatedb nocreaterole noinherit nologin noreplication nobypassrls password ' || coalesce(quote_literal(password) , 'null') || ';';
  execute dquery;
  if role_attributes is not null then
    dquery := 'alter role ' || quote_ident(role) || ' ' || role_attributes || ';';
    execute dquery;
  end if;
  dquery := 'comment on role ' || quote_ident(role) || ' IS TEXTVALUE0;';
  execute dquery;
end
$$;

comment on function abc_ensure_role (name , text , text , text) is 'Function to ensure the existence of a role and to update the comment and password on it. Only used for system roles and dropped after those are created. ';

