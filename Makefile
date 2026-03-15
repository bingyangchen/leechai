SHELL := /usr/bin/env bash
.SILENT:

.PHONY: build-dev
build-dev:
	$(SHELL) ./scripts/build.sh dev

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
