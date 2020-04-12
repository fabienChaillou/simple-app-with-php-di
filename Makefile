.PHONY: help

UID = $(shell id -u)
GID = $(shell id -g)
ID = $(UID):$(GID)
env?=dev


default: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?##.*$$' $(MAKEFILE_LIST) | sort | awk '{split($$0, a, ":"); printf "\033[36m%-30s\033[0m %-30s %s\n", a[1], a[2], a[3]}'

#
# Make sure to run the given command in a container identified by the given service.
#
# $(1) the user with which run the command
# $(2) the Docker Compose service
# $(3) the command to run
#
define run-in-container
	@if [ $$(env|grep -c "^CI=") -eq 1 ]; then \
		docker-compose exec --user $(1) -T $(2) /bin/sh -c "$(3)"; \
	elif [ ! -f /.dockerenv ]; then \
		docker-compose exec --user $(1) $(2) /bin/sh -c "$(3)"; \
	else \
		$(3); \
	fi
endef

#
# Executes a command in a running container, mainly useful to fix the terminal size on opening a shell session
#
# $(1) the options
#
define infra-shell
	docker-compose exec -e COLUMNS=`tput cols` -e LINES=`tput lines` $(1)
endef


########################################
#                APP                   #
########################################
.PHONY: app-install app-install-back app-install-front

app-install: ## to install the app
	@make app-install-back app-install-front

app-install-back: ## to install backend dependencies
	$(call run-in-container,$(ID),php_fpm,composer install)


app-install-front: ## to install backend dependencies
	$(call run-in-container,npm i)

########################################
#              INFRA                   #
########################################
.PHONY: infra-shell-php infra-shell-node infra-up

infra-shell-php: ## to open a shell session in the php-fpm container
	@$(call infra-shell,-u www-data php_fpm sh)

infra-shell-node: ## to open a shell session in the node container
	@$(call infra-shell,node sh)

infra-up: ## to start all the containers
	@if [ ! -f .env -a -f .env.dist ]; then sed "s,#UID#,$(UID),g;s,#GID#,$(GID),g" .env.dist > .env; fi
	@docker-compose up --build -d


#doc:
#	cd docs && sphinx-build -nW -b html -d _build/doctrees . _build/html

# build-encore:
# 	docker-compose exec node yarn run encore dev --watch

#clean:
#	rm -rf var/cache/*
#	php app/console cache:warmup --env=prod --no-debug
#	php app/console cache:warmup --env=dev
#
#assets:
#	if [ ! -f bin/yuicompressor.jar ]; then curl -L https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar > bin/yuicompressor.jar; fi;
#	app/console assets:install --symlink web
#	app/console assetic:dump
#
#assets-watch:
#	app/console assetic:dump --watch
