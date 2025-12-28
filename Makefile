all : build up

build :
	docker compose -f srcs/docker-compose.yml build --parallel
up : 
	docker compose -f srcs/docker-compose.yml up -d

viewUp : 
	docker compose -f srcs/docker-compose.yml up

restart :
	docker compose -f srcs/docker-compose.yml restart

down :
	docker compose -f srcs/docker-compose.yml down

cleanV :
	docker volume rm $$(docker volume ls -q)

downV :
	docker compose -f srcs/docker-compose.yml down -v
