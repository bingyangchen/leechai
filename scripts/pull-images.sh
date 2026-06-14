#! /usr/bin/env bash

set -euo pipefail
source "$(dirname "$(realpath "$0")")/common.sh"

check_triggered_by_make
load_env_vars
check_env prod
target_env="${1:-}"
validate_environment "$target_env"

echo "$DOCKER_ACCESS_TOKEN" | docker login --username "$DOCKER_USERNAME" --password-stdin

if [ "$1" == "prod" ]; then
    tag="$(resolve_prod_pull_image_tag)"
    remote_images=("$DOCKER_USERNAME/apiserver:$tag")
else
    remote_images=("$DOCKER_USERNAME/apiserver:$1")
fi

for image in "${remote_images[@]}"; do
    docker pull "$image"
done

printf "${GREEN} ✔ All images pulled from the registry${RESET}\n"
