#!/usr/bin/env bash

set -e
source "$(dirname "$(realpath "$0")")/common.sh"

check_triggered_by_make
load_env_vars

if [ "$1" != "dev" ] && [ "$1" != "prod" ]; then
    printf "${RED} ✗ Usage: $0 <dev|prod>${RESET}\n" >&2
    exit 1
fi

platform="linux/$(uname -m)"
if [ "$1" == "prod" ]; then
    platform="linux/x86_64"
fi

for service in apiserver; do
    echo "Building $service..."
    cd ./$service
    docker build -t "$DOCKER_USERNAME/$service:$1" --build-arg BUILDER_VARIANT="$1" \
        --target final -f ./Dockerfile --platform "$platform" .
    cd ..
    echo
done

printf "${GREEN} ✔ All images built${RESET}\n"
