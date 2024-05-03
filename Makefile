# Disable all the default make stuff
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

## Display a list of the documented make targets
.PHONY: help
help:
	@echo Documented Make targets:
	@perl -e 'undef $$/; while (<>) { while ($$_ =~ /## (.*?)(?:\n# .*)*\n.PHONY:\s+(\S+).*/mg) { printf "\033[36m%-30s\033[0m %s\n", $$2, $$1 } }' $(MAKEFILE_LIST) | sort

.PHONY: .FORCE
.FORCE:

compose.yaml: apps/ad/score.yaml apps/cart/score.yaml apps/checkout/score.yaml apps/currency/score.yaml apps/email/score.yaml apps/frontend/score.yaml apps/payment/score.yaml apps/productcatalog/score.yaml apps/recommendation/score.yaml apps/shipping/score.yaml
	score-compose init \
		--no-sample
	score-compose generate \
		apps/ad/score.yaml \
		apps/cart/score.yaml \
		apps/checkout/score.yaml \
		apps/currency/score.yaml \
		apps/email/score.yaml \
		apps/frontend/score.yaml \
		apps/payment/score.yaml \
		apps/productcatalog/score.yaml \
		apps/recommendation/score.yaml \
		apps/shipping/score.yaml

## Generate a compose.yaml file from the score specs and launch it.
.PHONY: compose-up
compose-up: compose.yaml
	docker compose up --build -d --remove-orphans

## Generate a compose.yaml file from the score spec, launch it and test (curl) the exposed container.
.PHONY: compose-test
compose-test: compose-up
	sleep 5
	curl $$(score-compose resources get-outputs dns.default#frontend.dns --format '{{ .host }}:8080')

## Delete the containers running via compose down.
.PHONY: compose-down
compose-down:
	docker compose down -v --remove-orphans || true

## Deploy the workloads to Humanitec.
.PHONY: humanitec-deploy
humanitec-deploy:
	humctl score deploy \
		--deploy-config apps/score.deploy.yaml \
		--env ${HUMANITEC_ENVIRONMENT} \
		--app ${HUMANITEC_APPLICATION} \
		--wait
