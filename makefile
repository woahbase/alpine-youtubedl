# {{{ -- meta

HOSTARCH  := $(shell uname -m | sed "s_armv6l_armhf_")# x86_64# on travis.ci
ARCH      := $(shell uname -m | sed "s_armv6l_armhf_")# armhf/x86_64 auto-detect on build and run
OPSYS     := alpine
SHCOMMAND := /bin/bash
SVCNAME   := youtubedl
USERNAME  := woahbase

PUID       := $(shell id -u)
PGID       := $(shell id -g)# gid 100(users) usually pre exists

DOCKERSRC := $(OPSYS)-python2#
DOCKEREPO := $(OPSYS)-$(SVCNAME)
IMAGETAG  := $(USERNAME)/$(DOCKEREPO):$(ARCH)

CNTNAME   := $(SVCNAME) # name for container name : docker_name, hostname : name

BUILD_NUMBER := 0#assigned in .travis.yml
BRANCH       := master

URL       :=

# -- }}}

# {{{ -- flags

BUILDFLAGS := --rm --force-rm --compress \
	-f $(CURDIR)/Dockerfile_$(ARCH) \
	-t $(IMAGETAG) \
	--build-arg DOCKERSRC=$(USERNAME)/$(DOCKERSRC):$(ARCH) \
	--build-arg http_proxy=$(http_proxy) \
	--build-arg https_proxy=$(https_proxy) \
	--build-arg no_proxy=$(no_proxy) \
	--label online.woahbase.source-image=$(DOCKERSRC) \
	--label online.woahbase.build-number=$(BUILD_NUMBER) \
	--label online.woahbase.branch=$(BRANCH) \
	--label org.label-schema.build-date=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
	--label org.label-schema.name=$(DOCKEREPO) \
	--label org.label-schema.schema-version="1.0" \
	--label org.label-schema.url="https://woahbase.online/" \
	--label org.label-schema.usage="https://woahbase.online/\#/images/$(DOCKEREPO)" \
	--label org.label-schema.vcs-ref=$(shell git rev-parse --short HEAD) \
	--label org.label-schema.vcs-url="https://github.com/$(USERNAME)/$(DOCKEREPO)" \
	--label org.label-schema.vendor=$(USERNAME)

CACHEFLAGS := --no-cache=true --pull
MOUNTFLAGS := -v $(CURDIR)/downloads:/home/alpine/downloads
NAMEFLAGS  := --name docker_$(CNTNAME) --hostname $(CNTNAME)
OTHERFLAGS := -v /etc/hosts:/etc/hosts:ro -v /etc/localtime:/etc/localtime:ro # -e TZ=Asia/Kolkata
PORTFLAGS  :=

RUNFLAGS   := -e PGID=$(PGID) -e PUID=$(PUID) -c 256 -m 256m

VDLFLAGS := -v -i \
	--add-metadata \
	--audio-quality 0 \
	--all-subs \
	--convert-subs 'srt' \
	--download-archive '/home/alpine/downloads/ytdl.v.archive.txt' \
	--embed-subs \
	--format 'bestvideo+bestaudio/best' \
	--geo-bypass \
	--hls-prefer-ffmpeg \
	--merge-output-format 'mkv' \
	--no-cache-dir \
	--no-continue \
	--no-overwrites \
	--output '/home/alpine/downloads/%(title)s_%(id)s_%(resolution)s_%(fps)sfps_%(vcodec)s_%(abr)sKbps_%(acodec)s.%(ext)s' \
	--proxy '$(http_proxy)' \
	--retries 3 \
	--xattrs \
	--yes-playlist

ADLFLAGS := -v -i \
	--add-metadata \
	--audio-quality 0 \
	--audio-format 'mp3' \
	--all-subs \
	--convert-subs 'srt' \
	--download-archive '/home/alpine/downloads/ytdl.a.archive.txt' \
	--embed-subs \
	--embed-thumbnail \
	--extract-audio \
	--format 'bestaudio[abr>=128]/bestaudio/best' \
	--geo-bypass \
	--hls-prefer-ffmpeg \
	--no-cache-dir \
	--no-continue \
	--no-overwrites \
	--output '/home/alpine/downloads/%(title)s_%(id)s_%(abr)sKbps_%(acodec)s.%(ext)s' \
	--proxy '$(http_proxy)' \
	--retries 3 \
	--xattrs \
	--yes-playlist
# 	--write-info-json \
#	--write-annotations \
# 	--write-description \

# -- }}}

# {{{ -- docker targets

all : run

build :
	echo "Building for $(ARCH) from $(HOSTARCH)";
	if [ "$(ARCH)" != "$(HOSTARCH)" ]; then make regbinfmt ; fi;
	docker build $(BUILDFLAGS) $(CACHEFLAGS) .

clean :
	docker images | awk '(NR>1) && ($$2!~/none/) {print $$1":"$$2}' | grep "$(USERNAME)/$(DOCKEREPO)" | xargs -n1 docker rmi

logs :
	docker logs -f docker_$(CNTNAME)

pull :
	docker pull $(IMAGETAG)

push :
	docker push $(IMAGETAG);
	if [ "$(ARCH)" = "$(HOSTARCH)" ]; \
		then \
		LATESTTAG=$$(echo $(IMAGETAG) | sed 's/:$(ARCH)/:latest/'); \
		docker tag $(IMAGETAG) $${LATESTTAG}; \
		docker push $${LATESTTAG}; \
	fi;

restart :
	docker ps -a | grep 'docker_$(CNTNAME)' -q && docker restart docker_$(CNTNAME) || echo "Service not running.";

rm :
	docker rm -f docker_$(CNTNAME)

run : shell
	# docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG)

shell :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) --entrypoint /bin/bash $(IMAGETAG)

rdebug :
	docker exec -u root -it docker_$(CNTNAME) $(SHCOMMAND)

debug :
	docker exec -it docker_$(CNTNAME) $(SHCOMMAND)

stop :
	docker stop -t 2 docker_$(CNTNAME)

test :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) '--version'

help :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) '--help'

# -- }}}

# {{{ -- other targets

regbinfmt :
	docker run --rm --privileged multiarch/qemu-user-static:register --reset

vdl :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) $(VDLFLAGS) $(URL)

adl :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) $(ADLFLAGS) $(URL)

info :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) -F $(URL)

# -- }}}
