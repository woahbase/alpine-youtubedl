[![build status][251]][232] [![commit][255]][231] [![version:x86_64][256]][235] [![size:x86_64][257]][235] [![version:armhf][258]][236] [![size:armhf][259]][236]

## [Alpine-YoutubeDL][234]
#### Container for Alpine Linux + Youtube-dl
---

This [image][233] containerizes the [command line client][136] for
[Youtube-dl][137] along with its [Python2][135] and [ffmpeg][138]
dependencies.  Useful to download, extract and/or convert media
urls from a number of sites.

Based on [Alpine Linux][131] from my [alpine-python2][132] image with
the [s6][133] init system [overlayed][134] in it.

The image is tagged respectively for the following architectures,
* **armhf**
* **x86_64** (retagged as the `latest` )

**armhf** builds have embedded binfmt_misc support and contain the
[qemu-user-static][105] binary that allows for running it also inside
an x64 environment that has it.

---
#### Get the Image
---

Pull the image for your architecture it's already available from
Docker Hub.

```
# make pull
docker pull woahbase/alpine-youtubedl:x86_64
```

---
#### Run
---

If you want to run images for other architectures, you will need
to have binfmt support configured for your machine. [**multiarch**][104],
has made it easy for us containing that into a docker container.

```
# make regbinfmt
docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

Without the above, you can still run the image that is made for your
architecture, e.g for an x86_64 machine..

This images already has a user `alpine` configured to drop
privileges to the passed `PUID`/`PGID` which is ideal if its used
to run in non-root mode. That way you only need to specify the
values at runtime and pass the `-u alpine` if need be. (run `id`
in your terminal to see your own `PUID`/`PGID` values.)

Before you run..

* Mount the downloads directory (where the audio/video files and
  archive.txt will be) at `/home/alpine/downloads`. Mounts
  `PWD/downloads` by default.

* Youtube-dl runs under the user `alpine`.

* A default for downloading video and audio are provided as
  `VDLFLAGS` and `ADLFLAGS`. Modify as needed, the default does
  quite a few things e.g add subs if available, add metadata,
  embed thumbs and attributes, keep track of previously downloaded
  media etc.

* Pass the url to download with the parameter `URL`

Running `make` gets a shell.

```
# make
docker run --rm -it \
  --name docker_youtubedl --hostname youtubedl \
  -e PGID=1000 -e PUID=1000 \
  -c 256 -m 256m \
  -v $PWD:/home/alpine/project \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/hosts:/etc/hosts:ro \
  --entrypoint /bin/bash \
  woahbase/alpine-youtubedl:x86_64
```

The usual stuff. e.g list available formats with

```
# make info URL=<youtube link>
docker run --rm -it \
  --name docker_youtubedl --hostname youtubedl \
  -e PGID=1000 -e PUID=1000 \
  -c 256 -m 256m \
  -v $PWD/downloads:/home/alpine/downloads \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/hosts:/etc/hosts:ro \
  woahbase/alpine-youtubedl:x86_64 \
  -F <youtube link>
```

download a video at the best a/v quality available

```
# make vdl URL=<youtube link>
docker run --rm -it \
  --name docker_youtubedl --hostname youtubedl\
  -e PGID=1000 -e PUID=1000 \
  -c 256 -m 256m \
  -v $PWD/downloads:/home/alpine/downloads \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/hosts:/etc/hosts:ro \
  woahbase/alpine-youtubedl:x86_64 \
  -v -i \
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
  --proxy '' \
  --retries 3 \
  --xattrs \
  --yes-playlist \
  <youtube link>
```

extract just the audio file from the video at the best quality available

```
# make adl URL=<youtube link>
docker run --rm -it \
  --name docker_youtubedl --hostname youtubedl\
  -e PGID=1000 -e PUID=1000 \
  -c 256 -m 256m \
  -v $PWD/downloads:/home/alpine/downloads \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/hosts:/etc/hosts:ro \
  woahbase/alpine-youtubedl:x86_64 \
   -v -i \
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
   --proxy '' \
   --retries 3 \
   --xattrs \
   --yes-playlist \
   <youtube link>
```

checkout all available options with

```
# make help
docker run --rm -it \
  --name docker_youtubedl --hostname youtubedl \
  -e PGID=1000 -e PUID=1000 \
  -c 256 -m 256m \
  -v $PWD/downloads:/home/alpine/downloads \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/hosts:/etc/hosts:ro \
  woahbase/alpine-youtubedl:x86_64 \
  --help
```

Stop the container with a timeout, (defaults to 2 seconds)

```
# make stop
docker stop -t 2 docker_youtubedl
```

Removes the container, (always better to stop it first and `-f`
only when needed most)

```
# make rm
docker rm -f docker_youtubedl
```

Restart the container with

```
# make restart
docker restart docker_youtubedl
```

---
#### Shell access
---

Get a shell inside a already running container,

```
# make shell
docker exec -it docker_youtubedl /bin/bash
```

set user or login as root,

```
# make rshell
docker exec -u root -it docker_youtubedl /bin/bash
```

To check logs of a running container in real time

```
# make logs
docker logs -f docker_youtubedl
```

---
### Development
---

If you have the repository access, you can clone and
build the image yourself for your own system, and can push after.

---
#### Setup
---

Before you clone the [repo][231], you must have [Git][101], [GNU make][102],
and [Docker][103] setup on the machine.

```
git clone https://github.com/woahbase/alpine-youtubedl
cd alpine-youtubedl
```
You can always skip installing **make** but you will have to
type the whole docker commands then instead of using the sweet
make targets.

---
#### Build
---

You need to have binfmt_misc configured in your system to be able
to build images for other architectures.

Otherwise to locally build the image for your system.
[`ARCH` defaults to `x86_64`, need to be explicit when building
for other architectures.]

```
# make ARCH=x86_64 build
# sets up binfmt if not x86_64
docker build --rm --compress --force-rm \
  --no-cache=true --pull \
  -f ./Dockerfile_x86_64 \
  --build-arg ARCH=x86_64 \
  --build-arg DOCKERSRC=alpine-python2 \
  --build-arg PGID=1000 \
  --build-arg PUID=1000 \
  --build-arg USERNAME=woahbase \
  -t woahbase/alpine-youtubedl:x86_64 \
  .
```

To check if its working..

```
# make ARCH=x86_64 test
docker run --rm -it \
  --name docker_youtubedl --hostname youtubedl \
  -e PGID=1000 -e PUID=1000 \
  woahbase/alpine-youtubedl:x86_64 \
  --version
```

And finally, if you have push access,

```
# make ARCH=x86_64 push
docker push woahbase/alpine-youtubedl:x86_64
```

---
### Maintenance
---

Sources at [Github][106]. Built at [Travis-CI.org][107] (armhf / x64 builds). Images at [Docker hub][108]. Metadata at [Microbadger][109].

Maintained by [WOAHBase][204].

[101]: https://git-scm.com
[102]: https://www.gnu.org/software/make/
[103]: https://www.docker.com
[104]: https://hub.docker.com/r/multiarch/qemu-user-static/
[105]: https://github.com/multiarch/qemu-user-static/releases/
[106]: https://github.com/
[107]: https://travis-ci.org/
[108]: https://hub.docker.com/
[109]: https://microbadger.com/

[131]: https://alpinelinux.org/
[132]: https://hub.docker.com/r/woahbase/alpine-python2
[133]: https://skarnet.org/software/s6/
[134]: https://github.com/just-containers/s6-overlay
[135]: https://www.python.org
[136]: https://github.com/rg3/youtube-dl/
[137]: https://rg3.github.io/youtube-dl/
[138]: https://www.ffmpeg.org/

[201]: https://github.com/woahbase
[202]: https://travis-ci.org/woahbase/
[203]: https://hub.docker.com/u/woahbase
[204]: https://woahbase.online/

[231]: https://github.com/woahbase/alpine-youtubedl
[232]: https://travis-ci.org/woahbase/alpine-youtubedl
[233]: https://hub.docker.com/r/woahbase/alpine-youtubedl
[234]: https://woahbase.online/#/images/alpine-youtubedl
[235]: https://microbadger.com/images/woahbase/alpine-youtubedl:x86_64
[236]: https://microbadger.com/images/woahbase/alpine-youtubedl:armhf

[251]: https://travis-ci.org/woahbase/alpine-youtubedl.svg?branch=master

[255]: https://images.microbadger.com/badges/commit/woahbase/alpine-youtubedl.svg

[256]: https://images.microbadger.com/badges/version/woahbase/alpine-youtubedl:x86_64.svg
[257]: https://images.microbadger.com/badges/image/woahbase/alpine-youtubedl:x86_64.svg

[258]: https://images.microbadger.com/badges/version/woahbase/alpine-youtubedl:armhf.svg
[259]: https://images.microbadger.com/badges/image/woahbase/alpine-youtubedl:armhf.svg
