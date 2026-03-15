ARG BUILDER_VARIANT=prod
ARG VENV_PATH=/venv
ARG PYTHON_VERSION=3.14.3
ARG UV_IMAGE=ghcr.io/astral-sh/uv:0.10

FROM ${UV_IMAGE} AS uv

FROM python:${PYTHON_VERSION}-slim-bookworm AS base

FROM base AS builder-dev
ARG VENV_PATH
COPY --from=uv /uv /usr/local/bin/uv
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    UV_PROJECT_ENVIRONMENT=${VENV_PATH} uv sync --locked
COPY . .

FROM base AS builder-prod
ARG VENV_PATH
COPY --from=uv /uv /usr/local/bin/uv
WORKDIR /app
RUN --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    UV_PROJECT_ENVIRONMENT=${VENV_PATH} uv sync --locked --no-dev --no-editable
COPY . .

FROM builder-${BUILDER_VARIANT} AS builder

FROM base AS final
ARG BUILDER_VARIANT
ARG VENV_PATH
RUN if [ "$BUILDER_VARIANT" = "dev" ]; then apt-get update && \
    apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*; fi
WORKDIR /app
COPY --from=builder /usr/local/bin/uv /usr/local/bin/uv
COPY --from=builder ${VENV_PATH} ${VENV_PATH}
COPY --from=builder /app /app
ENV PYTHONPATH=/app
ENV PATH="${VENV_PATH}/bin:${PATH}"
CMD ["fastapi", "run", "main/main.py", "--host", "0.0.0.0", "--port", "8000"]
