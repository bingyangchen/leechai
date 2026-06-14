#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$(realpath "$0")")/common.sh"

check_triggered_by_make
load_env_vars

target_env="${1:-}"
validate_environment "$target_env"

platform="linux/$(uname -m)"
if [ "$target_env" == "prod" ]; then
    platform="linux/x86_64"
fi

tag="$(resolve_prod_build_image_tag)"
for service in apiserver; do
    echo "Building $service..."
    cd ./$service
    if [ "$target_env" == "prod" ]; then
        docker build -t "$DOCKER_USERNAME/$service:$tag" \
            --build-arg BUILDER_VARIANT="$target_env" --target final -f ./Dockerfile \
            --platform "$platform" .
    else
        docker build -t "$DOCKER_USERNAME/$service:$target_env" --build-arg BUILDER_VARIANT="$target_env" \
            --target final -f ./Dockerfile --platform "$platform" .
    fi
    cd ..
    echo
done

printf "${GREEN} ✔ All images built${RESET}\n"
