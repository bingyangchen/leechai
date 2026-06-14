#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$(realpath "$0")")/common.sh"

check_triggered_by_make

cd mobile

printf "${BLUE}Running flutter pub get...${RESET}\n"
flutter pub get

printf "\n${BLUE}Checking code formatting...${RESET}\n"
if dart format --output=none --set-exit-if-changed .; then
    printf "${GREEN}✓ Code formatting is correct.${RESET}\n"
else
    printf "${RED}✗ Code formatting issues found. Run 'dart format .' to fix them.${RESET}\n"
    exit 1
fi

printf "\n${BLUE}Running static analysis...${RESET}\n"
if flutter analyze; then
    printf "${GREEN}✓ Static analysis passed successfully.${RESET}\n"
else
    printf "${RED}✗ Static analysis failed.${RESET}\n"
    exit 1
fi

if [ -d test ]; then
    printf "\n${BLUE}Running tests...${RESET}\n"
    if flutter test; then
        printf "${GREEN}✓ All tests passed successfully.${RESET}\n"
    else
        printf "${RED}✗ Some tests failed.${RESET}\n"
        exit 1
    fi
else
    printf "\n${YELLOW}No 'test' directory found. Skipping flutter test.${RESET}\n"
fi

printf "\n${GREEN}✓ All Flutter checks and analysis passed successfully!${RESET}\n"
