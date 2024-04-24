.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Welcome to Test-Deploy app. Please use \`make <target>\` where <target> is one of"
	@echo " "
	@echo "  Next commands are only for dev environment with nextcloud-docker-dev!"
	@echo "  "
	@echo "  build-push        build and push release version of image"
	@echo "  build-push-latest build and push dev version of image"
	@echo "  "
	@echo "  run               deploy release of 'Test-Deploy' for Nextcloud Last"
	@echo "  run-debug         deploy dev version of 'Test-Deploy' for Nextcloud Last"

.PHONY: build-push
build-push:
	docker login ghcr.io
	docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag ghcr.io/cloud-py-api/test-deploy-cpu:release --build-arg BUILD_TYPE=cpu .
	docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag ghcr.io/cloud-py-api/test-deploy-cuda:release --build-arg BUILD_TYPE=cuda .
	docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag ghcr.io/cloud-py-api/test-deploy-rocm:release --build-arg BUILD_TYPE=rocm .


.PHONY: build-push-latest
build-push-latest:
	docker login ghcr.io
	docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag ghcr.io/cloud-py-api/test-deploy-cpu:latest --build-arg BUILD_TYPE=cpu .
	docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag ghcr.io/cloud-py-api/test-deploy-cuda:latest --build-arg BUILD_TYPE=cuda .
	docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag ghcr.io/cloud-py-api/test-deploy-rocm:latest --build-arg BUILD_TYPE=rocm .

.PHONY: run
run:
	docker exec master-nextcloud-1 sudo -u www-data php occ app_api:app:unregister test-deploy --silent --force || true
	docker exec master-nextcloud-1 sudo -u www-data php occ app_api:app:register test-deploy --force-scopes \
		--info-xml https://raw.githubusercontent.com/cloud-py-api/test-deploy/main/appinfo/info.xml

.PHONY: run-debug
run-debug:
	docker exec master-nextcloud-1 sudo -u www-data php occ app_api:app:register test-deploy --force-scopes \
		--info-xml https://raw.githubusercontent.com/cloud-py-api/test-deploy/main/appinfo/info.xml
