VERSION?=test

ifeq ($(SSH_AUTH_SOCK),)
$(error SSH_AUTH_SOCK is empty. SSH agent forwarding is required. Please ensure your SSH agent is running and has the necessary keys added.)
endif


pygems-base:
	docker buildx build  -t pycrtm-base:${VERSION} --target pygems-base --ssh default --platform linux/amd64 --progress=plain  .

crtm-builder:
	docker buildx build  -t crtm-builder:${VERSION} --target crtm-builder --ssh default --platform linux/amd64 --progress=plain .


.PHONY: pygems-base crtm-builder