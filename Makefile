DOCKER := $(shell { command -v podman || command -v docker; })
TIMESTAMP := $(shell date -u +"%Y%m%d%H%M%S")
detected_OS := $(shell uname)  # Classify UNIX OS
ifeq ($(strip $(detected_OS)),Darwin) #We only care if it's OS X
SELINUX1 :=
SELINUX2 :=
else
SELINUX1 := :z
SELINUX2 := ,z
endif

.PHONY: all setup clean

all: setup build

build: firmware/$$(TIMESTAMP)-left.uf2 firmware/$$(TIMESTAMP)-right.uf2
	cp firmware/$(TIMESTAMP)-left.uf2 firmware/left.uf2
	cp firmware/$(TIMESTAMP)-right.uf2 firmware/right.uf2

clean:
	rm -f firmware/*.uf2

firmware/%-left.uf2 firmware/%-right.uf2: config/adv360.keymap
	$(DOCKER) run --rm -it --name zmk \
		-v $(PWD)/firmware:/app/firmware$(SELINUX1) \
		-v $(PWD)/config:/app/config:ro$(SELINUX2) \
		-e TIMESTAMP=$(TIMESTAMP) \
		zmk

clean:
	rm -f firmware/*.uf2
	$(DOCKER) image rm zmk docker.io/zmkfirmware/zmk-build-arm:stable

setup: Dockerfile bin/build.sh config/west.yml
	$(DOCKER) build --tag zmk --file Dockerfile .
