-- Database initialization for the workspace
-- Runs automatically on first postgres container start via /docker-entrypoint-initdb.d
-- Values are read from the container environment (set in docker-compose.yml from .env)

\getenv svc_user DB_USER
\getenv svc_password DB_PASSWORD
\getenv db_name DB_NAME

-- Create the shared dev service user (global, not database-scoped).
CREATE USER IF NOT EXISTS :"svc_user" WITH PASSWORD :'svc_password';

-- Create the app database and switch into it for all schema setup and grants.
CREATE DATABASE :"db_name";
\c :"db_name"

-- Source each project's schema definitions.
-- \i /project/source/<repo>/postgres/init.sql
-- <additional-source-repos>

-- Grant the service user access to every non-system schema created above.
-- Automatically covers multiple schemas and multiple \i'd projects.
SELECT format('GRANT ALL ON SCHEMA %I TO %I', nspname, :'svc_user')
FROM pg_namespace
WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'public')
  AND nspname NOT LIKE 'pg_%'
\gexec

SELECT format('ALTER USER %I SET search_path TO %s', :'svc_user',
  string_agg(nspname, ', '))
FROM pg_namespace
WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'public')
  AND nspname NOT LIKE 'pg_%'
\gexec
