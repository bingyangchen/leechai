SHELL := /usr/bin/env bash
.SILENT:

.PHONY: build-images-dev
build-images-dev:
	$(SHELL) ./scripts/build-images.sh dev

.PHONY: build-images-prod
build-images-prod:
	$(SHELL) ./scripts/build-images.sh prod

.PHONY: push-images-dev
push-images-dev:
	$(SHELL) ./scripts/dev/push-images.sh dev

.PHONY: push-images-prod
push-images-prod:
	$(SHELL) ./scripts/dev/push-images.sh prod

.PHONY: pull-images-dev
pull-images-dev:
	$(SHELL) ./scripts/pull-images.sh dev

.PHONY: pull-images-prod
pull-images-prod:
	$(SHELL) ./scripts/pull-images.sh prod

.PHONY: start
start:
	$(SHELL) ./scripts/start.sh

.PHONY: stop
stop:
	$(SHELL) ./scripts/stop.sh

.PHONY: migrate-prod
migrate-prod:
	$(SHELL) ./scripts/migrate.sh prod

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

.PHONY: deploy
deploy:
	$(SHELL) ./scripts/prod/deploy.sh

.PHONY: build-mobile-ios-ipa
build-mobile-ios-ipa:
	$(SHELL) ./scripts/mobile/build-ios-ipa.sh
