#!make
export USER_NAME=mnsoldotus
export APP_CRAWLER_VERSION=latest
export APP_UI_VERSION=latest

all : docker-build-crawler docker-push-crawler docker-build-ui docker-push-ui

.PHONY : all

######################################
# CRAWLER
docker-build-crawler:
	cd crawler && ./docker_build.sh

docker-push-crawler:
	docker login && docker push $(USER_NAME)/crawler:$(APP_CRAWLER_VERSION)

######################################
# SEARCH-UI
docker-build-ui:
	cd search-ui/ && ./docker_build.sh

docker-push-ui:
	docker login && docker push $(USER_NAME)/search-ui:$(APP_UI_VERSION)
