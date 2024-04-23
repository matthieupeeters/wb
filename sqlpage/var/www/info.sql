select 'shell' as component
  , 'DB info' as title;

select 'hero' as component
  , 'https://www.postgresql.org/docs/16/functions-info.html' as link
  , 'Description of postgresql functions' as link_text;

select 'list' as component
  , 'Database description' as title;

select 'version ()' as title
  , version() as description;

select 'current_database () ' as title
  , current_database() as description;

select 'current_query () ' as title
  , current_query() as description;

select 'current_role' as title
  , current_role as description;

select 'current_schema ()' as title
  , current_schema() as description;

select 'current_schemas (true)' as title
  , cast(current_schemas(true) as text) as description;

select 'inet_client_addr ()' as title
  , inet_client_addr() as description;

select 'inet_client_port ()' as title
  , inet_client_port() as description;

select 'inet_server_addr () ' as title
  , inet_server_addr() as description;

select 'inet_server_port ()' as title
  , inet_server_port() as description;

select 'pg_backend_pid ()' as title
  , pg_backend_pid() as description;

select 'pg_conf_load_time () ' as title
  , pg_conf_load_time() as description;

select 'pg_current_logfile ()' as title
  , pg_current_logfile () as description;

select 'pg_jit_available () ' as title
  , pg_jit_available () as description;

select 'pg_listening_channels () ' as title
  , pg_listening_channels()::text as description;

select 'pg_notification_queue_usage ()' as title
  , pg_notification_queue_usage () as description;

select 'pg_postmaster_start_time ()' as title
  , pg_postmaster_start_time() as description;

select 'session_user' as title
  , session_user as description;

select 'system_user' as title
  , system_user as description;

select 'hero' as component
  , 'https://sql.ophir.dev/functions.sql?function=version#function' as link
  , 'Description of sqlpage functions' as link_text;

select 'list' as component
  , 'sqlpage description' as title;

select 'sqlpage.version()' as title
 , sqlpage.version() as description;

