-- uuid functions
create extension if not exists "uuid-ossp";

-- standard cryptography
create extension if not exists pgcrypto;

-- case insensitive text type
create extension if not exists citext;

-- unit testing for postgresql
--  create extension if not exists pgtap;

