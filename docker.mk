include .env

.PHONY: install up down stop prune ps shell wp logs mutagen wp-download wp-config

default: up

WP_ROOT ?= /var/www/html

## help	:	Print commands help.
help : docker.mk
	@sed -n 's/^##//p' $<

wp-download:
	@echo "Starting install wordpress via composer..."
	docker run --rm --interactive --tty --volume $(PWD):/app --volume $(HOME)/.composer:/tmp composer install

wp-config:
	docker-compose exec php cp $(WP_ROOT)/wp-config-sample.php $(WP_ROOT)/wp-config.php
	docker-compose exec php sed -i "s/database_name_here/$(DB_NAME)/" "$(WP_ROOT)/wp-config.php"
	docker-compose exec php sed -i "s/username_here/$(DB_USER)/" "$(WP_ROOT)/wp-config.php"
	docker-compose exec php sed -i "s/password_here/$(DB_PASSWORD)/" "$(WP_ROOT)/wp-config.php"
	docker-compose exec php sed -i "s/'DB_HOST', 'localhost'/'DB_HOST', '$(DB_HOST)'/" "$(WP_ROOT)/wp-config.php"
	docker-compose exec php sed -i "s/'DB_CHARSET', 'utf8'/'DB_CHARSET', '$(DB_CHARSET)'/" "$(WP_ROOT)/wp-config.php"
	docker-compose exec php wp --path=$(WP_ROOT) config shuffle-salts

install: wp-download up wp-config

## up	:	Start up containers.
up:
	@echo "Starting up containers for $(PROJECT_NAME)..."
	docker-compose pull
	docker-compose up -d --remove-orphans

mutagen:
	mutagen-compose up

## down	:	Stop containers.
down: stop

## start	:	Start containers without updating.
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	@docker-compose start

## stop	:	Stop containers.
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker-compose stop

## prune	:	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		prune mariadb	: Prune `mariadb` container and remove its volumes.
##		prune mariadb solr	: Prune `mariadb` and `solr` containers and remove their volumes.
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v $(filter-out $@,$(MAKECMDGOALS))

## ps	:	List running containers.
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell	:	Access `php` container via shell.
##		You can optionally pass an argument with a service name to open a shell on the specified container
shell:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_$(or $(filter-out $@,$(MAKECMDGOALS)), 'php')' --format "{{ .ID }}") sh

## wp	:	Executes `wp cli` command in a specified `WP_ROOT` directory (default is `/var/www/html/`).
## 		Doesn't support --flag arguments.
wp:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") wp --path=$(WP_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs php	: View `php` container logs.
##		logs nginx php	: View `nginx` and `php` containers logs.
logs:
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

# https://stackoverflow.com/a/6273809/1826109
%:
	@:
