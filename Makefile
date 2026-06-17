CONTAINER_VERSION := $(shell tr -d '[:space:]' < src/version.txt)
FOUNDRY_VERSION := $(shell echo "$(CONTAINER_VERSION)" | cut -d- -f1 | cut -d+ -f1 | cut -d. -f1-2)

# Container image repository.
IMAGE := ghcr.io/felddy/foundryvtt

.PHONY: guard-version build test version github-output help release

## guard-version: fail loudly if the version source is missing or empty.
guard-version:
	@test -n "$(CONTAINER_VERSION)" || { echo "ERROR: src/version.txt missing or empty" >&2; exit 1; }

## README.md: render the documentation from its template using the version.
README.md: README.md.j2 src/version.txt guard-version
	uv run --group dev render-docs README.md.j2 README.md $(CONTAINER_VERSION)
## build: build the container image tagged with the CONTAINER_VERSION.
build: guard-version
	docker buildx build --build-arg CONTAINER_VERSION=$(CONTAINER_VERSION) --build-arg FOUNDRY_VERSION=$(FOUNDRY_VERSION) --load --tag $(IMAGE):$(CONTAINER_VERSION) .

## test: run the test suite against the built container image.
test: guard-version
	uv run --group dev pytest tests/ --image-tag $(IMAGE):$(CONTAINER_VERSION)

## version: print the derived CONTAINER_VERSION and FOUNDRY_VERSION.
version: guard-version
	@echo "Container : $(CONTAINER_VERSION)"
	@echo "FoundryVTT: $(FOUNDRY_VERSION)"

## github-output: print key=value lines for appending to $GITHUB_OUTPUT.
github-output: guard-version
	@echo "container_version=$(CONTAINER_VERSION)"
	@echo "foundry_version=$(FOUNDRY_VERSION)"

## help: list the developer-invocable targets.
help:
	@echo "Available targets:"
	@echo "  build          Build the container image tagged with the CONTAINER_VERSION."
	@echo "  github-output  Print key=value lines for CI."
	@echo "  help           Show this help message."
	@echo "  README.md      Render README.md from README.md.j2 using the version."
	@echo "  release        Bump VERSION, re-render docs, and commit (make release VERSION=x.y.z)."
	@echo "  test           Run the test suite (uv run pytest tests/)."
	@echo "  version        Print the derived CONTAINER_VERSION and FOUNDRY_VERSION."

## release: bump the version, re-render docs, and commit the result.
release: guard-version
	@test -n "$(VERSION)" || { echo "ERROR: VERSION is required (make release VERSION=x.y.z)" >&2; exit 1; }
	./bump-version set $(VERSION)
	$(MAKE) README.md
	git add README.md
	git commit --message "Render docs for $(VERSION)"
