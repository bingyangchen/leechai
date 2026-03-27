<div align="center">
  <img src="mobile/assets/icon/app_icon.png" alt="Leechai" width="120" />
  <h1>Leechai</h1>
</div>

![GitHub contributors](https://img.shields.io/github/contributors/bingyangchen/leechai?style=flat-square&logo=github&logoColor=white&label=Contributors&color=2ea44f) ![GitHub commit activity](https://img.shields.io/github/commit-activity/t/bingyangchen/leechai/main?style=flat-square&label=Total%20Commits&color=0969da) ![GitHub commit activity](https://img.shields.io/github/commit-activity/w/bingyangchen/leechai/main?style=flat-square&label=Weekly%20Commits&color=ffd43b) ![GitHub last commit (branch)](https://img.shields.io/github/last-commit/bingyangchen/leechai/main?style=flat-square&label=Last%20Commit&color=cf222e)

## 🔍 Overview

### Architecture

```mermaid
flowchart LR
    subgraph Mobile["📱 Mobile Client"]
        direction TB
        App["Flutter App"]
        LocalDB[("SQLite<br/>(Local DB)")]
        SyncService["Cloud Sync Service"]

        App <-->|Read / Write| LocalDB
        App --> SyncService
        SyncService <-->|Fetch / Update| LocalDB
    end

    Internet(("🌐 Internet"))

    subgraph Backend["☁️ Backend Services"]
        direction TB
        Proxy["Nginx<br/>(Reverse Proxy)"]
        API["FastAPI Server"]
        Cache[("Redis<br/>(In-Memory Cache)")]
        DB[("PostgreSQL<br/>(Relational DB)")]

        Proxy <--> API
        API <--> Cache
        API <--> DB
    end

    SyncService <-->|Sync API| Internet
    Internet <--> Proxy
```

### Branches

```mermaid
%%{init: { 'theme': 'base', 'gitGraph': {'showCommitLabel': false}} }%%
gitGraph
   commit
   commit
   branch feature/xxx
   switch feature/xxx
   commit
   commit
   switch main
   merge feature/xxx
   commit
   branch fix/xxx
   switch fix/xxx
   commit
   commit
   switch main
   merge fix/xxx
   commit
```

### Tech Stack

- Mobile App
  - Programming Language: Dart
  - Framework: Flutter
- API Server
  - Programming Language: Python
  - Framework: FastAPI
- Database: PostgreSQL
- Reverse Proxy: Nginx

## 🧑🏻‍💻 Development

### Quick Start

1. **Backend:** Follow [apiserver/README.md](apiserver/README.md).
2. **Mobile:** Follow [mobile/README.md](mobile/README.md).

### Development Workflow

1. Create a branch from `main` (`feature/xxx` or `fix/xxx`).
2. Commit and push, then open a PR on GitHub.
3. After approval, merge into `main`.

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
