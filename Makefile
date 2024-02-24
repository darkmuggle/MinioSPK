GOPATH = $(shell pwd -P)/go
GOARCH = arm
GOARM = 7
my_d = $(shell pwd -P)
minio_src := go/src/github.com/minio/minio

.PHONY: build i386 arm7
build:
	@echo "Usage: make init; make arm7|i386|arm64"

arm7: minio_arm7 pkg_arm7
arm64: minio_arm64 pkg_arm64
i386: minio_i386 pkg_i386

.PHONY: clean
clean:
	@rm -rf .git/modules .gitmodules
	@find . -type f -iname "*.tgz" -exec rm -rvf {} \;
	@find . -type f -iname "*.spk" -exec rm -rvf {} \;
	@find . -type f -iname "*.png" -exec rm -rvf {} \;
	@rm -rf go minio*linux*

.PHONY: init
init: artwork
	git clone https://github.com/minio/minio $(minio_src)
	cd $(minio_src) && \
		last_release=$$(git tag | sort -r | gawk '/RELEASE/{print$$1; exit;}') && \
		git checkout --force -b working $${last_release}

.PHONY: artwork
artzip = https://dl.minio.io/logo/Minio_Logo_Black.zip
artwork:
	docker run --rm -it -v $(my_d):/src alpine \
		sh -c 'set -x; apk add --update imagemagick wget unzip; \
			wget $(artzip); \
			unzip $(shell basename $(artzip)); \
			for size in 16 24 32 48 64 72 90 120 256; do \
		       		convert Minio_Logo_Black/Minio_Logo_Black.png -resize $${size}x$${size} \
				/src/1_create_package/ui/minio-$${size}.png;  \
			done; \
			cp /src/1_create_package/ui/minio-120.png /src/2_create_project/PACKAGE_ICON_120.PNG; \
			cp /src/1_create_package/ui/minio-256.png /src/2_create_project/PACKAGE_ICON_256.PNG; \
			cp /src/1_create_package/ui/minio-256.png /src/2_create_project/PACKAGE_ICON.PNG; '


last_release := $(shell cd $(minio_src) && git tag | sort -r | gawk '/RELEASE/{print$$1; exit;}' || echo unknown)
date_release := $(shell echo $(last_release) | awk -F'T' '{gsub("RELEASE-", "", $$1); gsub("-",".", $$1); print$$1}')
pkg_version := $(subst RELEASE.,,$(date_release))

.PHONY: info
info:
	@echo "$(last_release) $(pkg_version)"

.PHONY: minio minio_%
_docker_cmd = docker run --rm -it -v $(my_d)/$(minio_src):/$(minio_src) -v $(my_d):/out --workdir=/$(minio_src)
_docker_ctr = golang:1.21
minio_arm7: go_env=--env GOARCH=arm --env GOARM=7
minio_arm7: pkg_arch=arm-7
minio_arm7: minio
minio_arm64: go_env=--env GOARCH=arm64 
minio_arm64: pkg_arch=arm64
minio_arm64: minio
minio_i386: go_env=--env GOARCH=386
minio_i386: pkg_arch=i386
minio_i386: minio

minio: LDFLAGS=$(shell $(_docker_cmd) $(_docker_ctr) bash -c "go run buildscripts/gen-ldflags.go")
minio:
	@echo "Working on $(last_release)"
	@echo "Cross-compiling in Docker, this will take a few minutes"
	$(_docker_cmd) \
		--env CGO_ENABLED=0 \
		--env GOOS="linux" \
		--env GO111MODULE=on \
		$(go_env) \
		$(_docker_ctr) \
		sh -c "go get ./... && go build -tags kqeue --ldflags '$(LDFLAGS)' -o /out/minio-$(pkg_version)-linux-$(pkg_arch)"

.PHONY: pkg pkg_%
pkg_arm7: pkg_arch=arm-7
pkg_arm7: syno_arch=armada370 armada375 armada38x armadaxp alpine\/alpine4k comcerto2k monaco
pkg_arm7: pkg
pkg_arm64: pkg_arch=arm64
pkg_arm64: syno_arch=rtd1296
pkg_arm64: pkg
pkg_i386: pkg_arch=i386
pkg_i386: syno_arch="evansport"
pkg_i386: pkg
pkg:
	sed -e "s/version=.*/version=\"$(pkg_version)\"/g;s/arch=.*/arch=\"$(syno_arch)\"/g" \
		2_create_project/INFO-e > 2_create_project/INFO
	mkdir -p 1_create_package/minio
	cp minio-$(pkg_version)-linux-$(pkg_arch) 1_create_package/minio/minio
	cd 1_create_package && \
		tar cvfhz ../2_create_project/package.tgz *
	cd 2_create_project && \
		tar cvfz ../minio-$(pkg_version)-$(pkg_arch).spk --exclude=INFO.in *
	rm -f package.tgz
