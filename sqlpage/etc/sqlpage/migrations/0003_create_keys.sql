-- 32 hex chars (16 * 8 bytes)
-- alter database "$database" set "app.pepper" to md5(random()::text || random()::text || random()::text);
-- alter database "$database" set "app.token_hash" to md5(random()::text || random()::text || random()::text);
-- alter database "$database" set "app.jwt_secret" to md5(random()::text || random()::text || random()::text);
