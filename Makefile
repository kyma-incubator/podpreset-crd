APP_NAME=podpreset
IMG=$(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/$(APP_NAME)
TAG=$(DOCKER_TAG)
BINARY=$(APP_NAME)

.PHONY: build-controller
build-controller:
	./before-commit.sh ci

# Run tests
.PHONY: test-controller
test-controller:
	go test ./pkg/... ./cmd/...

# Generate manifests e.g. CRD, RBAC etc.
.PHONY: manifests
manifests:
	go run vendor/sigs.k8s.io/controller-tools/cmd/controller-gen/main.go all

# Generate code
.PHONY: generate
generate:
	go generate ./pkg/... ./cmd/...

# Build the docker image
.PHONY: build-image-controller
build-image-controller:
	docker build --no-cache -t $(APP_NAME)-controller:latest .

.PHONY: push-image-controller
push-image-controller:
	docker tag $(APP_NAME)-controller $(IMG)-controller:$(TAG)
	docker push $(IMG)-controller:$(TAG)

.PHONY: clean
clean:
	rm -f webhook/webhook
	rm -f manager
#
# Controller deployment targets
#

# Run against the configured Kubernetes cluster in ~/.kube/config
.PHONY: run-controller
run-controller: generate fmt vet
	go run ./cmd/manager/main.go

# Install CRDs into a cluster
.PHONY: install
install: manifests
	kubectl apply -f config/crds

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
.PHONY: deploy
deploy: manifests
	kubectl apply -f config/crds
	kustomize build config/default | kubectl apply -f -

.PHONY: undeploy
undeploy:
	kustomize build config/default | kubectl delete -f -
	kubectl delete -f config/crds

#
# Mutating webhook targets
#

.PHONY: deploy-webhook
deploy-webhook:
	kubectl apply -f webhook/rbac/
	kustomize build webhook/kustomize-config | kubectl apply -f -

.PHONY: undeploy-webhook
undeploy-webhook:
	kustomize build webhook/kustomize-config | kubectl delete -f -
	kubectl delete -f webhook/rbac/

.PHONY: build-webhook
build-webhook:
	CGO_ENABLED=0 GOOS=linux go build -o ./webhook/webhook ./webhook/

.PHONY: build-image-webhook
build-image-webhook:
	docker build --no-cache -t $(APP_NAME)-webhook:latest ./webhook/
	rm -rf ./webhook/webhook

.PHONY: push-image-webhook
push-image-webhook:
	docker tag $(APP_NAME)-webhook $(IMG)-webhook:$(TAG)
	docker push $(IMG)-webhook:$(TAG)

#
# CI targets
#

.PHONY: ci-pr
ci-pr: build-controller test-controller build-image-controller push-image-controller build-webhook build-image-webhook push-image-webhook

.PHONY: ci-master
ci-master: build-controller test-controller build-image-controller push-image-controller build-webhook build-image-webhook push-image-webhook

.PHONY: ci-release
ci-release: build-controller test-controller build-image-controller push-image-controller build-webhook build-image-webhook push-image-webhook
