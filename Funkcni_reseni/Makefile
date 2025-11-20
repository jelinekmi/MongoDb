# Makefile pro MongoDB

KEYFILE=mongo-keyfile
ENV=.env

.PHONY: all setup-keyfile start-no-auth init-auth start-auth clean restart-auth

all: setup-keyfile start-no-auth init-auth start-auth

setup-keyfile:
	sudo sh -c "openssl rand -base64 756 > $(KEYFILE)"
	sudo chmod 400 $(KEYFILE)
	sudo chown 999:999 $(KEYFILE)

start-no-auth:
	@echo "Spouštím cluster bez autentizace..."
	sed -i 's/^AUTH=.*/AUTH=disabled/' $(ENV)
	docker compose down -v
	docker compose up -d
	sleep 40

init-auth:
	@sed -i 's/^AUTH=.*/AUTH=enabled/' $(ENV)


start-auth:
	docker compose up -d

clean:
	docker compose down -v
	sudo rm -f $(KEYFILE)

restart-auth:
	@echo "Restartuji cluster s autentizací..."
	sudo sed -i 's/^AUTH=.*/AUTH=enabled/' $(ENV)
	docker compose down -v
	docker compose up -d

stop-node:
	docker stop shard1a

start-node:
	docker start shard1a

restart-node:
	docker restart shard1a

