-- Schema initialization for {{cookiecutter.project_repository}}
-- Sourced by the workspace devcontainer during database setup.
-- User creation and access grants live in the workspace repository.
--
-- Add additional CREATE SCHEMA lines if this project spans multiple schemas.

CREATE SCHEMA IF NOT EXISTS {{cookiecutter.db_schema}};
