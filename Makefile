-include .env

SRC_DIR=src
MIGRATIONS_DIR=migrations

DOCKER_COMPOSE_VERSION_CHECKER := $(shell docker compose > /dev/null 2>&1 ; echo $$?)
ifeq ($(DOCKER_COMPOSE_VERSION_CHECKER), 0)
DOCKER_COMPOSE_IMPL=docker compose
else
DOCKER_COMPOSE_IMPL=docker-compose
endif

.PHONY: cat
cat:
	cat Makefile

.PHONY: help
help:
	${MAKE} cat

.PHONY: cp/env
cp/env:
	cp .env.dev .env

.PHONY: init
init:
	@if [ ! -f .env ]; then \
		echo ".envファイルが存在しません。.envファイルを作成します。"; \
		${MAKE} cp/env; \
		echo "新しい.envファイルが作成されました。必要な環境変数を設定してください。"; \
	fi
	@if [ -f .env ]; then \
		grep -q '^[^#]*=' .env || { echo ".envファイルに未設定の環境変数があります。すべての値を埋めてください。" ; exit 1; }; \
	fi
	${MAKE} build
	${MAKE} up

.PHONY: build
build:
	${DOCKER_COMPOSE_IMPL} build

.PHONY: up
up:
	${DOCKER_COMPOSE_IMPL} up -d

.PHONY: run
run:
	${DOCKER_COMPOSE_IMPL} exec app /bin/sh -c 'go mod tidy && go run .'

.PHONY: down/d
down/d:
	${DOCKER_COMPOSE_IMPL} down

.PHONY: app/login
app/login:
	${DOCKER_COMPOSE_IMPL} exec app /bin/sh

.PHONY: db/login
db/login:
	${DOCKER_COMPOSE_IMPL} exec db /bin/bash

.PHONY: db/client
db/client:
	${DOCKER_COMPOSE_IMPL} exec db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

.PHONY: app/logs
app/logs:
	${DOCKER_COMPOSE_IMPL} logs app

.PHONY: db/logs
db/logs:
	${DOCKER_COMPOSE_IMPL} logs db

# DBのデータを削除しないようにappのみ再起動する
.PHONY: rebuild
rebuild:
	${MAKE} rebuild/app

.PHONY: rebuild/app
rebuild/app:
	${DOCKER_COMPOSE_IMPL} build app
	${DOCKER_COMPOSE_IMPL} up -d app

.PHONY: rebuild/db
rebuild/db:
	${DOCKER_COMPOSE_IMPL} build db
	${DOCKER_COMPOSE_IMPL} up -d db

.PHONY: rebuild/all
rebuild/all:
	${MAKE} rebuild/app
	${MAKE} rebuild/db

.PHONY: fmt
fmt:
	@${DOCKER_COMPOSE_IMPL} exec app /bin/sh -c 'goimports -l -w .'
	@${DOCKER_COMPOSE_IMPL} exec app /bin/sh -c 'gci write -s standard -s default -s "prefix(github.com/daixiang0/gci)" .'
	@${DOCKER_COMPOSE_IMPL} exec app /bin/sh -c 'gofumpt -l -w .'

.PHONY: lint
lint:
	@${DOCKER_COMPOSE_IMPL} exec app /bin/sh -c 'golangci-lint run --config .golangci.yaml'
