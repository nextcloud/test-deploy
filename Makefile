.DEFAULT_GOAL := help

APP_ID := test-deploy
APP_NAME := TestDeploy
APP_VERSION := $$(xmlstarlet sel -t -v "//version" appinfo/info.xml)


.PHONY: help
help:
	@echo "  Welcome to $(APP_NAME) $(APP_VERSION)!"
	@echo " "
	@echo "  Please use \`make <target>\` where <target> is one of"
	@echo " "
	@echo "  build-push          builds app docker images with 'release' tags and uploads them to ghcr.io"
	@echo "  build-push-latest   builds app docker images with 'latest' tags and uploads them to ghcr.io"
	@echo " "
	@echo "  > Next commands are only for the dev environment with nextcloud-docker-dev!"
	@echo "  > They should run from the host you are developing on and not in the container with Nextcloud!"
	@echo " "
	@echo "  run30               installs $(APP_NAME) for Nextcloud 30"
	@echo "  run                 installs $(APP_NAME) for Nextcloud Latest"
	@echo " "
	@echo "  run30-latest        installs $(APP_NAME) with 'latest' tag for Nextcloud 30"
	@echo "  run-latest          installs $(APP_NAME) with 'latest' tag for Nextcloud Latest"

.PHONY: build-push
build-push:
	docker login ghcr.io
	docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag ghcr.io/nextcloud/$(APP_ID):release --build-arg BUILD_TYPE=cpu .
	docker buildx build --push --platform linux/amd64 --tag ghcr.io/nextcloud/$(APP_ID):release-cuda --build-arg BUILD_TYPE=cuda .
	docker buildx build --push --platform linux/amd64 --tag ghcr.io/nextcloud/$(APP_ID):release-rocm --build-arg BUILD_TYPE=rocm .

.PHONY: build-push-latest
build-push-latest:
	docker login ghcr.io
	docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag ghcr.io/nextcloud/$(APP_ID):latest --build-arg BUILD_TYPE=cpu .
	docker buildx build --push --platform linux/amd64 --tag ghcr.io/nextcloud/$(APP_ID):latest-cuda --build-arg BUILD_TYPE=cuda .
	docker buildx build --push --platform linux/amd64 --tag ghcr.io/nextcloud/$(APP_ID):latest-rocm --build-arg BUILD_TYPE=rocm .

.PHONY: run30
run30:
	docker exec master-stable30-1 sudo -u www-data php occ app_api:app:register $(APP_ID) --test-deploy-mode \
		--info-xml https://raw.githubusercontent.com/nextcloud/$(APP_ID)/main/appinfo/info.xml

.PHONY: run
run:
	docker exec master-nextcloud-1 sudo -u www-data php occ app_api:app:register $(APP_ID) --test-deploy-mode \
		--info-xml https://raw.githubusercontent.com/nextcloud/$(APP_ID)/main/appinfo/info.xml

.PHONY: run30-latest
run30-latest:
	docker exec master-stable30-1 sudo -u www-data php occ app_api:app:register $(APP_ID) --test-deploy-mode \
		--info-xml https://raw.githubusercontent.com/nextcloud/$(APP_ID)/main/appinfo/info-latest.xml

.PHONY: run-latest
run-latest:
	docker exec master-nextcloud-1 sudo -u www-data php occ app_api:app:register $(APP_ID) --test-deploy-mode \
		--info-xml https://raw.githubusercontent.com/nextcloud/$(APP_ID)/main/appinfo/info-latest.xml
