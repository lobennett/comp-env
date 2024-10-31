# Makefile for comp-env using Podman, supports serverless root
# to make compatible with docker, substitute `podman` with `docker`, remove "--format docker" and "--remove-signatures" flags.

IMAGES = base beh_env fmri_env
TARGETS = beh_env fmri_env

GHCR_PREFIX = ghcr.io/$(USERNAME)

all: $(IMAGES)

$(IMAGES):
	podman build --arch amd64 --format docker -t $@ -f $@.cf ./containerfile

push-github:
	echo $(PAT) | podman login ghcr.io -u $(USERNAME) --password-stdin
	for target in $(TARGETS); do \
		podman tag $$target $(GHCR_PREFIX)/$$target; \
		podman push --remove-signatures $(GHCR_PREFIX)/$$target; \
	done


prune:
	podman image prune -f
