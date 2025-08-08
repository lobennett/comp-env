# Makefile to create and push containers to GitHub Container Registry

# Load environment variables from .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

IMAGES = base poldrack_fmri poldrack_fmri_tedana-0.0.12

USERNAME = lobennett
GHCR_PREFIX = ghcr.io/$(USERNAME)

all: $(IMAGES)

$(IMAGES):
	podman build --platform linux/amd64 --format docker -t $@ -f $@.cf ./containerfile
	@if [ "$@" = "poldrack_fmri_tedana-0.0.12" ]; then \
		podman tag $@ poldrack_fmri:tedana-0.0.12; \
	elif [ "$@" = "poldrack_fmri" ]; then \
		podman tag $@ poldrack_fmri:latest; \
	fi

push-github: $(IMAGES)
	@echo "Logging into GitHub Container Registry..."
	@echo $(PAT) | podman login ghcr.io -u $(USERNAME) --password-stdin
	@echo "Pushing images..."
	@for target in $(IMAGES); do \
		if [ "$$target" = "poldrack_fmri_tedana-0.0.12" ]; then \
			podman tag poldrack_fmri:tedana-0.0.12 $(GHCR_PREFIX)/poldrack_fmri:tedana-0.0.12; \
			podman push --remove-signatures $(GHCR_PREFIX)/poldrack_fmri:tedana-0.0.12; \
		elif [ "$$target" = "poldrack_fmri" ]; then \
			podman tag $$target $(GHCR_PREFIX)/$$target; \
			podman push --remove-signatures $(GHCR_PREFIX)/$$target; \
			podman tag poldrack_fmri:latest $(GHCR_PREFIX)/poldrack_fmri:latest; \
			podman push --remove-signatures $(GHCR_PREFIX)/poldrack_fmri:latest; \
		else \
			podman tag $$target $(GHCR_PREFIX)/$$target; \
			podman push --remove-signatures $(GHCR_PREFIX)/$$target; \
		fi \
	done

prune:
	podman image prune -f