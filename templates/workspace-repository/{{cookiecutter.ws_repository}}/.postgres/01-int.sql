-- Schema and service user initialization
-- Runs automatically on first postgres container start via /docker-entrypoint-initdb.d
-- Values are read from the container environment (set in docker-compose.yml from .env)

\getenv schema DB_SCHEMA
\getenv svc_user DB_USER
\getenv svc_password DB_PASSWORD

CREATE SCHEMA IF NOT EXISTS :"schema";
CREATE USER IF NOT EXISTS :"svc_user" WITH PASSWORD :'svc_password';
GRANT ALL ON SCHEMA :"schema" TO :"svc_user";
GRANT CREATE ON SCHEMA :"schema" TO :"svc_user";
ALTER USER :"svc_user" SET search_path TO :"schema";
