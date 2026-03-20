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
    remote_images=("$DOCKER_USERNAME/apiserver:$1")
else
    remote_images=("$DOCKER_USERNAME/apiserver:$1")
fi

for image in "${remote_images[@]}"; do
    docker pull "$image"
done

printf "${GREEN} ✔ All images pulled from the registry${RESET}\n"
