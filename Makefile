NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_DIR = /home/sleeper/data

all: init build up

init:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

build:
	$(COMPOSE) build --parallel

up:
	$(COMPOSE) up -d

viewUp:
	$(COMPOSE) up

restart:
	$(COMPOSE) restart

down:
	$(COMPOSE) down

downV:
	$(COMPOSE) down -v

cleanV:
	docker volume rm $$(docker volume ls -q)