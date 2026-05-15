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
   cp .env.example .env
   ```

   Fill in the values for the environment variables.

2. Build the images for development:

   ```bash
   make build-images-dev
   ```

3. Generate SSL certificates and keys for development:

   ```bash
   make cert-dev
   ```

4. Run the development server:

   ```bash
   make start
   # To stop, run `make stop`
   ```

## How to Manage Dependencies

- Enter the shell of the API server container (run `make shell-apiserver`).
- Install: `uv add {DEPENDENCY} --no-sync` or remove: `uv remove {DEPENDENCY} --no-sync`
  (`--no-sync` only performs version check, no download.)
- Exit the shell, rebuild dev images, then restart the API server container (run `make start`).

## How to Add Environment Variables

1. Add the variable and value in `.env` (at project root).
2. Add the variable to the `Settings` class in `apiserver/main/config.py`.
3. GitHub repository: Settings > Secrets and variables > Actions > Secrets/Variables.
4. Add the variable name (no value) in `.env.example` for future reference.

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

## 🚀 Production Deployment

On the production host, configure `.env` with `ENVIRONMENT=prod`, `DOCKER_USERNAME`, and `DOCKER_ACCESS_TOKEN` (do not put `image_tag` in `.env`). The working tree must be clean; the script switches to `main` and runs `git pull origin main` before deploying.

Images built from `main` are pushed with a tag equal to the **full Git commit hash** (40 hex characters). CI builds on every push to `main`.

- **Deploy latest `main`:** after `git pull`, the deploy uses the current `HEAD` commit as the image tag.

  ```bash
  make deploy
  ```

- **Deploy a specific commit** (pin or rollback): pass the same full hash the registry uses for that image.

  ```bash
  make deploy image_tag={FULL_GIT_COMMIT_HASH}
  ```

**Rollback:** If the version you just deployed is bad, deploy again with the **previous known-good commit’s full hash** (the image must already exist in the registry from an earlier CI run). Example: `make deploy image_tag=abcdef0123456789abcdef0123456789abcdef01`.
