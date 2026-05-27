-- Schema initialization for {{cookiecutter.project_repository}}
-- Sourced by the workspace devcontainer during database setup.
-- User creation and access grants live in the workspace repository.
{%- for schema in cookiecutter.db_schemas.split(',') if schema.strip() %}

CREATE SCHEMA IF NOT EXISTS {{ schema.strip() }};
{%- endfor %}
