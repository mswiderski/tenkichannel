QUAY_NAMESPACE = ricardozanini
VERSION = 1.0.0
JAVA_VERSION = ${VERSION}-SNAPSHOT

.PHONY: build-images
build-images:
	- make build-weather-image
	- make build-rain-image

.PHONY: build-weather-image
build-weather-image:
	@echo .......... Building Weather API Gateway JAR .........................
	cd weather-api-gateway
	mvn clean package
	@echo .......... Building Weather API Gateway Image .......................
	docker build --tag quay.io/${QUAY_NAMESPACE}/weather-api-gateway:${VERSION}
	make push app="weather-api-gateway"

build-rain-image:
	@echo .......... Building Rain Forecast Process JAR .........................
	cd rain-forecast-process
	mvn clean package
	@echo .......... Building Rain Forecast Process Image .....................
	docker build . --tag quay.io/${QUAY_NAMESPACE}/rain-forecast-process:${VERSION}
	make push app="rain-forecast-process"

# Image Reference docs:
# https://access.redhat.com/documentation/en-us/red_hat_jboss_middleware_for_openshift/3/html-single/red_hat_java_s2i_for_openshift/index#configuration_environment_variables
.PHONY: build-s2i-images
build-s2i-images:
	- make build-s2i-weather-image
	- make build-s2i-rain-image
	- make build-s2i-rain-ui-image

.PHONY: build-s2i-weather-image
build-s2i-weather-image:
	@echo .......... Building S2I Weather API Gateway Image .................
	s2i build weather-api-gateway docker.io/fabric8/s2i-java:latest-java11 quay.io/${QUAY_NAMESPACE}/weather-api-gateway:${VERSION}
	make push app="weather-api-gateway"

.PHONY: build-s2i-rain-image
build-s2i-rain-image:
	@echo .......... Building S2I Rain Forecast Process Image ...............
	s2i build rain-forecast-process/ quay.io/kiegroup/kogito-quarkus-ubi8-s2i:0.4.0 quay.io/${QUAY_NAMESPACE}/rain-forecast-process:${VERSION}  -e NATIVE=true --runtime-image quay.io/kiegroup/kogito-quarkus-ubi8:0.4.0
	make push app="rain-forecast-process"

.PHONY: build-s2i-rain-ui-image
build-s2i-rain-ui-image:
	@echo .......... Building Rain Forecast UI Image .....................
	s2i build rain-forecast-ui/ docker.io/nodeshift/centos7-s2i-web-app:latest quay.io/${QUAY_NAMESPACE}/rain-forecast-ui:${VERSION} --runtime-image docker.io/centos/nginx-114-centos7:latest --runtime-artifact /opt/app-root/output

.PHONY: push
app = ""
push:
	@echo .......... Pushing ${app} to quay.io .....................................
	docker tag quay.io/${QUAY_NAMESPACE}/${app}:${VERSION} quay.io/${QUAY_NAMESPACE}/${app}:latest
	docker push quay.io/${QUAY_NAMESPACE}/${app}:${VERSION}
	docker push quay.io/${QUAY_NAMESPACE}/${app}:latest
	@echo .......... Image ${app} successfully pushed to quay.io ........, .........


