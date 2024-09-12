WP_DATA = /home/emauduit/data/wordpress # define the path to the wordpress data
DB_DATA = /home/emauduit/data/mariadb # define the path to the mariadb data

# default target
all: up

# start the building process
# create the wordpress and mariadb data directories.
# start the containers in the background and leave them running
up: build
	@sudo mkdir -p $(WP_DATA)
	@sudo mkdir -p $(DB_DATA)
	@sudo chown -R $(USER):$(USER) /home/emauduit/data
	@sudo chmod -R 755 /home/emauduit/data
	docker compose -f ./srcs/docker-compose.yml up -d

down:
	docker compose -f ./srcs/docker-compose.yml down

stop:
	docker compose -f ./srcs/docker-compose.yml stop

start:
	docker compose -f ./srcs/docker-compose.yml start

build:
	clear
	docker compose -f ./srcs/docker-compose.yml build

# clean the containers
# stop all running containers and remove them.
# remove all images, volumes and networks.
# remove the wordpress and mariadb data directories.
# the (|| true) is used to ignore the error if there are no containers running to prevent the make command from stopping.
clean:
	@docker stop $$(docker ps -qa) || true
	@docker rm $$(docker ps -qa) || true
	@docker rmi -f $$(docker images -qa) || true
	@docker volume rm $(shell docker volume ls -q -f "name=mariadb") || true
	@docker volume rm $(shell docker volume ls -q -f "name=wordpress") || true
	@docker volume prune -f || true
	@docker network prune -f || true
	@sudo rm -rf $(WP_DATA) || true
	@sudo rm -rf $(DB_DATA) || true

# clean and start the containers
re: clean up

# prune the containers: execute the clean target and remove all containers, images, volumes and networks from the system.
prune: clean
	@docker system prune -a --volumes -f
