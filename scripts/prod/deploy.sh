#!/usr/bin/env bash

set -e
source "$(dirname "$(realpath "$0")")/../common.sh"

check_triggered_by_make
check_env prod

if [[ -n "$(git status -s)" ]]; then
    printf "${RED} ✗ Working directory has uncommitted changes.${RESET}\n" >&2
    exit 1
fi

git switch main
git pull origin main

if [[ -n "${1:-}" ]]; then
    export image_tag="$1"
else
    export image_tag="$(git rev-parse HEAD)"
fi

printf "${BLUE}image_tag: ${image_tag}${RESET}\n"

make pull-images-prod
make start-and-recycle

printf "${GREEN} ✔ Deploy completed${RESET}\n"
