SHELL := /usr/bin/env bash
.SILENT:

.PHONY: build-dev
build-dev:
	$(SHELL) ./scripts/build.sh dev

.PHONY: build-prod
build-prod:
	$(SHELL) ./scripts/build.sh prod

.PHONY: push-images-dev
push-images-dev:
	$(SHELL) ./scripts/dev/push-images.sh dev

.PHONY: push-images-prod
push-images-prod:
	$(SHELL) ./scripts/dev/push-images.sh prod

.PHONY: start
start:
	$(SHELL) ./scripts/start.sh

.PHONY: stop
stop:
	$(SHELL) ./scripts/stop.sh

.PHONY: start-and-recycle
start-and-recycle:
	$(SHELL) ./scripts/start.sh --recycle

.PHONY: shell-apiserver
shell-apiserver:
	$(SHELL) ./scripts/enter-shell.sh apiserver

.PHONY: shell-reverseproxy
shell-reverseproxy:
	$(SHELL) ./scripts/enter-shell.sh reverseproxy

.PHONY: shell-db
shell-db:
	$(SHELL) ./scripts/enter-shell.sh db

.PHONY: cert
cert:
	$(SHELL) ./scripts/dev/cert.sh
