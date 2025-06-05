# Makefile for comp-env using Podman, supports serverless root
# to make compatible with docker, substitute `podman` with `docker`, remove "--format docker" and "--remove-signatures" flags.

include .env

IMAGES = base fmri_env
TARGETS = base fmri_env

GHCR_PREFIX = ghcr.io/$(USERNAME)

all: $(IMAGES)

$(IMAGES):
	podman build --arch amd64 --format docker -t $@ -f $@.cf ./containerfile

push-github:
	@echo "Logging into GitHub Container Registry..."
	@echo $(PAT) | podman login ghcr.io -u $(USERNAME) --password-stdin
	@echo "Pushing images..."
	@for target in $(TARGETS); do \
		podman tag $$target $(GHCR_PREFIX)/$$target; \
		podman push --remove-signatures $(GHCR_PREFIX)/$$target; \
	done

prune:
	podman image prune -f
