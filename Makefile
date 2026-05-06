SHELL := /usr/bin/env bash

IMAGE ?= statuspulse:local
COMPOSE ?= docker compose
APP_PORT ?= 8000
PYTHON ?= python3

.PHONY: build up down logs test clean shell ensure-env

ensure-env:
	@test -f .env || cp .env.example .env

build: ensure-env
	docker build -t $(IMAGE) .

up: ensure-env
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f --tail=100

test:
	curl -fsS "http://localhost:$(APP_PORT)/health" | $(PYTHON) -m json.tool

clean:
	$(COMPOSE) down -v --rmi local --remove-orphans
	docker image rm -f $(IMAGE) 2>/dev/null || true

shell:
	$(COMPOSE) exec app bash
