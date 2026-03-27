# API Server

## Prerequisites

- Operating System: MacOS or Linux
- Git (>=2.34.0)
- GNU Make (>=3.81.0)
- Docker (>=27.4.0)
- Visual Studio Code (or any other editor that supports devcontainer)

## Quick Start

1. From project root, create `.env`:

   ```bash
   cp example.env .env
   ```

   Fill in the values for the environment variables.

2. Build the images for development:

   ```bash
   make build-images-dev
   ```

3. Install Git hooks:

   ```bash
   make install-git-hooks
   ```

4. Generate SSL certificates and keys for development:

   ```bash
   make cert-dev
   ```

5. Run the development server:

   ```bash
   make start
   # To stop: make stop
   ```

## Dependency Management

- Enter the shell of the API server container.
- Install: `uv add {DEPENDENCY} --no-sync` or remove: `uv remove {DEPENDENCY} --no-sync`
  (`--no-sync` only performs version check, no download.)
- Exit, rebuild dev images, then restart the API server container.

## Environment Variables

1. Add the variable (no value) in `example.env`.
2. Add the variable and value in `.env` (at project root).
3. If used by the API server: add it in `apiserver/main/config.py` and `.github/workflows/lint-and-test.yaml`, and in GitHub Settings > Environments > Test > Variables/Secrets.

## How to Migrate the Database Schema

- **Step 1**: Modify the ORM class in `apiserver/main/features/{feature_name}/models.py`

- **Step 2**: Check that the `models.py` are imported in `apiserver/migrations/env.py`

- **Step 3**: Enter the container

    ```bash
    make shell-apiserver
    ```

- **Step 4**: Generate the migration file

    ```bash
    alembic revision --autogenerate -m "{DESCRIPTION}"
    ```

- **Step 5**: Double check the content of the new migration file in `apiserver/migrations/versions/`

- **Step 6**: Apply the migration file

    ```bash
    alembic upgrade head
    ```
