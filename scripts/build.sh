#!/usr/bin/env bash

set -e
source "$(dirname "$(realpath "$0")")/common.sh"

check_triggered_by_make
load_env_vars

if [ "$1" != "dev" ] && [ "$1" != "prod" ]; then
    printf "${RED} ✗ Usage: $0 <dev|prod>${RESET}\n" >&2
    exit 1
fi

if [ "$1" == "prod" ]; then
    for service in apiserver; do
        echo "Building $service..."
        cd ./$service
        docker build -t "$DOCKER_USERNAME/$service:$1" --target "$1"_final \
            -f ./Dockerfile --platform linux/x86_64 .
        cd ..
        echo
    done
else
    arch=$(uname -m)
    for service in apiserver; do
        echo "Building $service..."
        cd ./$service
        docker build -t "$DOCKER_USERNAME/$service:$1" --build-arg BUILDER_VARIANT="$1" --target final \
          -f ./Dockerfile --platform linux/$arch .
        cd ..
        echo
    done
fi

printf "${GREEN} ✔ All images built${RESET}\n"
