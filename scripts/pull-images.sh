#! /usr/bin/env bash

set -e
source "$(dirname "$(realpath "$0")")/common.sh"

check_triggered_by_make
load_env_vars

if [ "$1" != "dev" ] && [ "$1" != "prod" ]; then
    printf "${RED} ✗ Usage: $0 <dev|prod>${RESET}\n" >&2
    exit 1
fi

echo "$DOCKER_ACCESS_TOKEN" | docker login --username "$DOCKER_USERNAME" --password-stdin

if [ "$1" == "prod" ]; then
    if [[ -z "${image_tag:-}" ]]; then
        git fetch origin main --quiet 2>/dev/null || true
        if git rev-parse --verify refs/remotes/origin/main >/dev/null 2>&1; then
            image_tag=$(git rev-parse refs/remotes/origin/main)
        elif git rev-parse --verify main >/dev/null 2>&1; then
            image_tag=$(git rev-parse main)
        else
            printf "${RED} ✗ Cannot resolve main for image tag (no origin/main or local main).${RESET}\n" >&2
            exit 1
        fi
    fi
    remote_images=("$DOCKER_USERNAME/apiserver:$image_tag")
else
    remote_images=("$DOCKER_USERNAME/apiserver:$1")
fi

for image in "${remote_images[@]}"; do
    docker pull "$image"
done

printf "${GREEN} ✔ All images pulled from the registry${RESET}\n"
