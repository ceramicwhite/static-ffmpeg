## static-ffmpeg

Docker image with
[ffmpeg](https://ffmpeg.org/ffmpeg.html) and
[ffprobe](https://ffmpeg.org/ffprobe.html)
built as hardened static PIE binaries with no external dependencies that can be
used with any base image.

See [Dockerfile](Dockerfile) for versions used. In general, master **should** have the
latest stable version of ffmpeg and below libraries.
Versions are kept up to date automatically using [bump](https://github.com/wader/bump).

### Usage

Use `mwader/static-ffmpeg` from [Docker Hub](https://hub.docker.com/r/mwader/static-ffmpeg) or build the image yourself.

In Dockerfile
```Dockerfile
COPY --from=mwader/static-ffmpeg:7.0.1 /ffmpeg /usr/local/bin/
COPY --from=mwader/static-ffmpeg:7.0.1 /ffprobe /usr/local/bin/
```

Run directly
```sh
docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:7.0.1 -i file.wav file.mp3
docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:7.0.1 -i file.wav
```

As shell alias
```sh
alias ffmpeg='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:7.0.1'
alias ffprobe='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:7.0.1'
```

### Libraries

- [fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/)
- gray
- iconv
- [lcms2](https://www.littlecms.com/)
- [libaom](https://aomedia.googlesource.com/aom/)
- [libaribb24](https://github.com/nkoriyama/aribb24)
- [libass](https://github.com/libass/libass)
- [libbluray](https://www.videolan.org/developers/libbluray.html)
- [libdav1d](https://code.videolan.org/videolan/dav1d)
- [libdavs2](https://github.com/pkuvcl/davs2)
- [libfdk-aac](https://github.com/mstorsjo/fdk-aac) (only if explicitly enabled during build, [see below](#libfdk-aac))
- [libfreetype](https://freetype.org/)
- [libfribidi](https://github.com/fribidi/fribidi)
- [libgme](https://github.com/mcfiredrill/libgme)
- [libgsm](https://github.com/timothytylee/libgsm)
- [libharfbuzz](https://github.com/harfbuzz/harfbuzz)
- [libjxl](https://github.com/libjxl/libjxl)
- [libkvazaar](https://github.com/ultravideo/kvazaar)
- [libmodplug](https://github.com/Konstanty/libmodplug)
- [libmp3lame](https://lame.sourceforge.io/)
- [libmysofa](https://github.com/hoene/libmysofa)
- [libopencore](https://sourceforge.net/projects/opencore-amr/)
- [libopenjpeg](https://www.openjpeg.org)
- [libopus](https://opus-codec.org)
- [librabbitmq](https://github.com/alanxz/rabbitmq-c)
- [librav1e](https://github.com/xiph/rav1e)
- [librsvg](https://gitlab.gnome.org/GNOME/librsvg)
- [librtmp](https://rtmpdump.mplayerhq.hu/)
- [librubberband](https://breakfastquay.com/rubberband/)
- [libshine](https://github.com/toots/shine)
- [libsnappy](https://google.github.io/snappy/)
- [libsoxr](https://sourceforge.net/projects/soxr/)
- [libspeex](https://github.com/xiph/speex)
- [libsrt](https://github.com/Haivision/srt)
- [libssh](https://gitlab.com/libssh/libssh-mirror)
- [libsvtav1](https://gitlab.com/AOMediaCodec/SVT-AV1)
- [libtheora](https://github.com/xiph/theora)
- [libtwolame](https://github.com/njh/twolame)
- [libuavs3d](https://github.com/uavs3/uavs3d)
- [libvidstab](https://github.com/georgmartius/vid.stab)
- [libvmaf](https://github.com/Netflix/vmaf)
- [libvo-amrwbenc](https://github.com/mstorsjo/vo-amrwbenc)
- [libvorbis](https://github.com/xiph/vorbis)
- [libvpx](https://github.com/webmproject/libvpx)
- [libwebp](https://chromium.googlesource.com/webm/libwebp)
- [libx264](https://www.videolan.org/developers/x264.html)
- [libx265](https://www.videolan.org/developers/x265.html) (multilib with support for 10 and 12 bits)
- [libxavs2](https://github.com/pkuvcl/xavs2)
- [libxevd](https://github.com/mpeg5/xevd)
- [libxeve](https://github.com/mpeg5/xeve)
- [libxml2](https://gitlab.gnome.org/GNOME/libxml2)
- [libxvid](https://labs.xvid.com)
- [libzimg](https://github.com/sekrit-twc/zimg)
- [openssl](https://openssl.org)
- and all native ffmpeg codecs, formats, filters etc.

### Files in the image

- `/ffmpeg` ffmpeg binary
- `/ffprobe` ffprobe binary
- `/doc` Documentation
- `/versions.json` JSON file with build versions of ffmpeg and libraries.
- `/etc/ssl/cert.pem` CA certs to make `-tls_verify 1 -ca_file /etc/ssl/cert.pem` work if running image directly
- Fonts, fontconfig config and pre-populated cache:
  - `/etc/fonts`
  - `/usr/share/fonts`
  - `/usr/share/consolefonts`
  - `/var/cache/fontconfig`

### Tags

`latest` Latest master build.

`MAJOR.MINOR.PATCH[-BUILD]` Specific version of FFmpeg with the features that was in master at the time of tagging.
`-BUILD` means that was an additional build with that version to add of fix something.

### Security

Binaries are built with various hardening features but it's *still a good idea to run them
as non-root even when used inside a container*, especially so if running on input files that
you don't control.

### libfdk-aac
Due to license issues the docker image does not include libfdk-aac by default. A docker image including libfdk-aac can be built by passing a non empty value to the build-arg `ENABLE_FDKAAC`, example below.
```
docker build --build-arg ENABLE_FDKAAC=1 . -t my-ffmpeg-static:latest
```

### Fonts usage with SVG or draw text filters etc

The image ships with some basic fonts (`font-terminus font-inconsolata font-dejavu font-awesome`) that can be used when running the image directly. If your copying the binaries into some image you have to install fonts somehow. How to do this depends a bit on distributions but in general look for font packages and how to make [fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/) know about them.

- Alpine Linux see https://wiki.alpinelinux.org/wiki/Fonts
- Debian/Ubuntu see https://wiki.debian.org/Fonts

### TLS

Binaries are built with TLS support but, by default, ffmpeg currently do
not do certificate verification. To enable verification you need to run
ffmpeg with `-tls_verify 1` and `-ca_file /path/to/cert.pem`.

- Alpine Linux at `/etc/ssl/cert.pem`
- Debian/Ubuntu install the `ca-certificates` package at it will be available at `/etc/ssl/certs/ca-certificates.crt`.

### Known issues and tricks

#### Multi-arch and arm64

Since version 5.0.1-3 dockerhub images are multi-arch amd64 and arm64 images.

#### Copy out binaries from image

This will copy `ffmpeg` and `ffprobe` to the current directory:
```
docker run --rm -v "$PWD:/out" $(echo -e 'FROM alpine\nCOPY --from=mwader/static-ffmpeg:7.0.1 /ff* /\nENTRYPOINT cp /ff* /out' | docker build -q -)
```

#### Quickly see what versions an image was built with

```
docker run --rm mwader/static-ffmpeg -v quiet -f data -i versions.json -map 0 -c copy -f data -
```

#### I see `Name does not resolve` errors for hosts that should resolve

This could happen if the hostname resolve to more IP-addresses than can fit in [DNS UDP packet](https://www.rfc-editor.org/rfc/rfc791) (probably 512 bytes) causing the response to be truncated. Usually clients should then switch to TCP and redo the query.
This should only be a problem with version 6.0-1 or earlier of this image that uses [musl libc](https://www.musl-libc.org) 1.2.3 or older.

#### I see `[tls @ 0x7f80c8ec3800] error:030000A9:digital envelope routines::unknown option` errors

This could be because the statically linked openssl version in the static-ffmpeg binaries are not compatible with the (possibly distro modified openssl) configuration files found in the filesystem. The error is about openssl encountering an option that it does not know about.

Possible workarounds:
- Add `config_diagnostics = 0` to the openssl config to ignore unknown options with the risk of ignoring real problems.
- Use ffmpeg option `-reconnect_on_network_error true` to ignore the error but will still warn.

See these references for further discussion and workarounds:
- [First call to SSL_CTX_new is failing on AL2023 (3.0.12)
](https://github.com/openssl/openssl/discussions/23016)
- [OpenSSL issue with binary outside container (RedHat/Fedora specific)](https://github.com/wader/static-ffmpeg/issues/462)

### Docker Hub images

Multi-arch dockerhub images are built using [pyldin601/build-multiarch-on-aws-spots](https://github.com/pyldin601/build-multiarch-on-aws-spots). See [build-multiarch.yml](.github/workflows/build-multiarch.yml) for config. Thanks to [@pyldin601](https://github.com/pyldin601) for making this possible.

### Contribute

Feel free to create issues or PRs if you have any improvements or encounter any problems.
Please also consider making a [donation to the FFmpeg project](https://ffmpeg.org/donations.html)
or to other projects used by this image if you find it useful.

Please also be mindful of the license limitations used by libraries this project uses and your own
usage and potential distribution of such.

### TODOs and possible things to add

- Add libplacebo, chromaprint, etc. ...
- Add vvenc/vvdec support once in stable
- Add acceleration support (GPU, CUDA, ...)
- Add *.a *.so libraries, headers and pkg-config somehow
