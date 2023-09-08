# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM amd64/alpine:latest AS builder

RUN apk --update --upgrade add \
  coreutils \
  wget \
  rust cargo cargo-c \
  openssl-dev openssl-libs-static \
  ca-certificates \
  bash \
  tar \
  build-base \
  autoconf automake \
  libtool \
  diffutils \
  cmake meson ninja \
  git \
  yasm nasm \
  texinfo \
  jq \
  zlib-dev zlib-static \
  bzip2-dev bzip2-static \
  libxml2-dev libxml2-static \
  expat-dev expat-static \
  fontconfig-dev fontconfig-static \
  freetype freetype-dev freetype-static \
  graphite2-static \
  glib-static \
  tiff tiff-dev \
  libjpeg-turbo libjpeg-turbo-dev \
  libpng-dev libpng-static \
  giflib giflib-dev \
  harfbuzz-dev harfbuzz-static \
  fribidi-dev fribidi-static \
  brotli-dev brotli-static \
  soxr-dev soxr-static \
  tcl \
  numactl-dev \
  cunit cunit-dev \
  fftw-dev \
  libsamplerate-dev libsamplerate-static \
  vo-amrwbenc-dev vo-amrwbenc-static \
  snappy snappy-dev snappy-static \
  xxd \
  xz-dev xz-static

# -O3 makes sure we compile with optimization. setting CFLAGS/CXXFLAGS seems to override
# default automake cflags.
# -static-libgcc is needed to make gcc not include gcc_s as "as-needed" shared library which
# cmake will include as a implicit library.
# other options to get hardened build (same as ffmpeg hardened)
ARG CFLAGS="-O3 -s -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIC"
ARG CXXFLAGS="-O3 -s -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIC"
ARG LDFLAGS="-Wl,-z,relro,-z,now"

# retry dns and some http codes that might be transient errors
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503"

# bump: fdk-aac /FDK_AAC_VERSION=([\d.]+)/ https://github.com/mstorsjo/fdk-aac.git|*
# bump: fdk-aac after ./hashupdate Dockerfile FDK_AAC $LATEST
# bump: fdk-aac link "ChangeLog" https://github.com/mstorsjo/fdk-aac/blob/master/ChangeLog
# bump: fdk-aac link "Source diff $CURRENT..$LATEST" https://github.com/mstorsjo/fdk-aac/compare/v$CURRENT..v$LATEST
ARG FDK_AAC_VERSION=2.0.2
ARG FDK_AAC_URL="https://github.com/mstorsjo/fdk-aac/archive/v$FDK_AAC_VERSION.tar.gz"
ARG FDK_AAC_SHA256=7812b4f0cf66acda0d0fe4302545339517e702af7674dd04e5fe22a5ade16a90
RUN \
  wget $WGET_OPTS -O fdk-aac.tar.gz "$FDK_AAC_URL" && \
  echo "$FDK_AAC_SHA256  fdk-aac.tar.gz" | sha256sum --status -c - && \
  tar xf fdk-aac.tar.gz && \
  cd fdk-aac-* && ./autogen.sh && ./configure --disable-shared --enable-static && \
  make -j$(nproc) install

# bump: libgsm /LIBGSM_COMMIT=([[:xdigit:]]+)/ gitrefs:https://github.com/timothytylee/libgsm.git|re:#^refs/heads/master$#|@commit
# bump: libgsm after ./hashupdate Dockerfile LIBGSM $LATEST
# bump: libgsm link "Changelog" https://github.com/timothytylee/libgsm/blob/master/ChangeLog
ARG LIBGSM_URL="https://github.com/timothytylee/libgsm.git"
ARG LIBGSM_COMMIT=98f1708fb5e06a0dfebd58a3b40d610823db9715
RUN \
  git clone "$LIBGSM_URL" && \
  cd libgsm && git checkout $LIBGSM_COMMIT && \
  # Makefile is garbage, hence use specific compile arguments and flags
  # no need to build toast cli tool \
  rm src/toast* && \
  SRC=$(echo src/*.c) && \
  gcc ${CFLAGS} -c -ansi -pedantic -s -DNeedFunctionPrototypes=1 -Wall -Wno-comment -DSASR -DWAV49 -DNDEBUG -I./inc ${SRC} && \
  ar cr libgsm.a *.o && ranlib libgsm.a && \
  mkdir -p /usr/local/include/gsm && \
  cp inc/*.h /usr/local/include/gsm && \
  cp libgsm.a /usr/local/lib

# bump: mp3lame /MP3LAME_VERSION=([\d.]+)/ svn:http://svn.code.sf.net/p/lame/svn|/^RELEASE__(.*)$/|/_/./|*
# bump: mp3lame after ./hashupdate Dockerfile MP3LAME $LATEST
# bump: mp3lame link "ChangeLog" http://svn.code.sf.net/p/lame/svn/trunk/lame/ChangeLog
ARG MP3LAME_VERSION=3.100
ARG MP3LAME_URL="https://sourceforge.net/projects/lame/files/lame/$MP3LAME_VERSION/lame-$MP3LAME_VERSION.tar.gz/download"
ARG MP3LAME_SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
RUN \
  wget $WGET_OPTS -O lame.tar.gz "$MP3LAME_URL" && \
  echo "$MP3LAME_SHA256  lame.tar.gz" | sha256sum --status -c - && \
  tar xf lame.tar.gz && \
  cd lame-* && ./configure --disable-shared --enable-static --enable-nasm --disable-gtktest --disable-cpml --disable-frontend && \
  make -j$(nproc) install

# bump: opencoreamr /OPENCOREAMR_VERSION=([\d.]+)/ fetch:https://sourceforge.net/projects/opencore-amr/files/opencore-amr/|/opencore-amr-([\d.]+).tar.gz/
# bump: opencoreamr after ./hashupdate Dockerfile OPENCOREAMR $LATEST
# bump: opencoreamr link "ChangeLog" https://sourceforge.net/p/opencore-amr/code/ci/master/tree/ChangeLog
ARG OPENCOREAMR_VERSION=0.1.6
ARG OPENCOREAMR_URL="https://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-$OPENCOREAMR_VERSION.tar.gz"
ARG OPENCOREAMR_SHA256=483eb4061088e2b34b358e47540b5d495a96cd468e361050fae615b1809dc4a1
RUN \
  wget $WGET_OPTS -O opencoreamr.tar.gz "$OPENCOREAMR_URL" && \
  echo "$OPENCOREAMR_SHA256  opencoreamr.tar.gz" | sha256sum --status -c - && \
  tar xf opencoreamr.tar.gz && \
  cd opencore-amr-* && ./configure --enable-static --disable-shared && \
  make -j$(nproc) install

# bump: openjpeg /OPENJPEG_VERSION=([\d.]+)/ https://github.com/uclouvain/openjpeg.git|*
# bump: openjpeg after ./hashupdate Dockerfile OPENJPEG $LATEST
# bump: openjpeg link "CHANGELOG" https://github.com/uclouvain/openjpeg/blob/master/CHANGELOG.md
ARG OPENJPEG_VERSION=2.5.0
ARG OPENJPEG_URL="https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz"
ARG OPENJPEG_SHA256=0333806d6adecc6f7a91243b2b839ff4d2053823634d4f6ed7a59bc87409122a
RUN \
  wget $WGET_OPTS -O openjpeg.tar.gz "$OPENJPEG_URL" && \
  echo "$OPENJPEG_SHA256  openjpeg.tar.gz" | sha256sum --status -c - && \
  tar xf openjpeg.tar.gz && \
  cd openjpeg-* && mkdir build && cd build && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_PKGCONFIG_FILES=ON \
    -DBUILD_CODEC=OFF \
    -DWITH_ASTYLE=OFF \
    -DBUILD_TESTING=OFF \
    .. && \
  make -j$(nproc) install

# bump: opus /OPUS_VERSION=([\d.]+)/ https://github.com/xiph/opus.git|^1
# bump: opus after ./hashupdate Dockerfile OPUS $LATEST
# bump: opus link "Release notes" https://github.com/xiph/opus/releases/tag/v$LATEST
# bump: opus link "Source diff $CURRENT..$LATEST" https://github.com/xiph/opus/compare/v$CURRENT..v$LATEST
ARG OPUS_VERSION=1.4
ARG OPUS_URL="https://github.com/xiph/opus/releases/download/v$OPUS_VERSION/opus-$OPUS_VERSION.tar.gz"
ARG OPUS_SHA256=c9b32b4253be5ae63d1ff16eea06b94b5f0f2951b7a02aceef58e3a3ce49c51f
RUN \
  wget $WGET_OPTS -O opus.tar.gz "$OPUS_URL" && \
  echo "$OPUS_SHA256  opus.tar.gz" | sha256sum --status -c - && \
  tar xf opus.tar.gz && \
  cd opus-* && ./configure --disable-shared --enable-static --disable-extra-programs --disable-doc && \
  make -j$(nproc) install

# bump: rubberband /RUBBERBAND_VERSION=([\d.]+)/ https://github.com/breakfastquay/rubberband.git|^2
# bump: rubberband after ./hashupdate Dockerfile RUBBERBAND $LATEST
# bump: rubberband link "CHANGELOG" https://github.com/breakfastquay/rubberband/blob/default/CHANGELOG
# bump: rubberband link "Source diff $CURRENT..$LATEST" https://github.com/breakfastquay/rubberband/compare/$CURRENT..$LATEST
ARG RUBBERBAND_VERSION=2.0.2
ARG RUBBERBAND_URL="https://breakfastquay.com/files/releases/rubberband-$RUBBERBAND_VERSION.tar.bz2"
ARG RUBBERBAND_SHA256=b9eac027e797789ae99611c9eaeaf1c3a44cc804f9c8a0441a0d1d26f3d6bdf9
RUN \
  wget $WGET_OPTS -O rubberband.tar.bz2 "$RUBBERBAND_URL" && \
  echo "$RUBBERBAND_SHA256  rubberband.tar.bz2" | sha256sum --status -c - && \
  tar xf rubberband.tar.bz2 && \
  cd rubberband-* && \
  meson -Ddefault_library=static -Dfft=fftw -Dresampler=libsamplerate build && \
  ninja -j$(nproc) -vC build install && \
  echo "Requires.private: fftw3 samplerate" >> /usr/local/lib/pkgconfig/rubberband.pc

# bump: LIBSHINE /LIBSHINE_VERSION=([\d.]+)/ https://github.com/toots/shine.git|*
# bump: LIBSHINE after ./hashupdate Dockerfile LIBSHINE $LATEST
# bump: LIBSHINE link "CHANGELOG" https://github.com/toots/shine/blob/master/ChangeLog
# bump: LIBSHINE link "Source diff $CURRENT..$LATEST" https://github.com/toots/shine/compare/$CURRENT..$LATEST
ARG LIBSHINE_VERSION=3.1.1
ARG LIBSHINE_URL="https://github.com/toots/shine/releases/download/$LIBSHINE_VERSION/shine-$LIBSHINE_VERSION.tar.gz"
ARG LIBSHINE_SHA256=58e61e70128cf73f88635db495bfc17f0dde3ce9c9ac070d505a0cd75b93d384
RUN \
  wget $WGET_OPTS -O libshine.tar.gz "$LIBSHINE_URL" && \
  echo "$LIBSHINE_SHA256  libshine.tar.gz" | sha256sum --status -c - && \
  tar xf libshine.tar.gz && cd shine* && \
  ./configure --with-pic --enable-static --disable-shared --disable-fast-install && \
  make -j$(nproc) install

# bump: srt /SRT_VERSION=([\d.]+)/ https://github.com/Haivision/srt.git|^1
# bump: srt after ./hashupdate Dockerfile SRT $LATEST
# bump: srt link "Release notes" https://github.com/Haivision/srt/releases/tag/v$LATEST
ARG SRT_VERSION=1.5.3
ARG SRT_URL="https://github.com/Haivision/srt/archive/v$SRT_VERSION.tar.gz"
ARG SRT_SHA256=befaeb16f628c46387b898df02bc6fba84868e86a6f6d8294755375b9932d777
RUN \
  wget $WGET_OPTS -O libsrt.tar.gz "$SRT_URL" && \
  echo "$SRT_SHA256  libsrt.tar.gz" | sha256sum --status -c - && \
  tar xf libsrt.tar.gz && cd srt-* && mkdir build && cd build && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SHARED=OFF \
    -DENABLE_APPS=OFF \
    -DENABLE_CXX11=ON \
    -DUSE_STATIC_LIBSTDCXX=ON \
    -DOPENSSL_USE_STATIC_LIBS=ON \
    -DENABLE_LOGGING=OFF \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_INCLUDEDIR=include \
    -DCMAKE_INSTALL_BINDIR=bin \
    .. && \
  make -j$(nproc) && make install

# bump: libssh /LIBSSH_VERSION=([\d.]+)/ https://gitlab.com/libssh/libssh-mirror.git|*
# bump: libssh after ./hashupdate Dockerfile LIBSSH $LATEST
# bump: libssh link "Source diff $CURRENT..$LATEST" https://gitlab.com/libssh/libssh-mirror/-/compare/libssh-$CURRENT...libssh-$LATEST
# bump: libssh link "Release notes" https://gitlab.com/libssh/libssh-mirror/-/tags/libssh-$LATEST
ARG LIBSSH_VERSION=0.10.5
ARG LIBSSH_URL="https://gitlab.com/libssh/libssh-mirror/-/archive/libssh-$LIBSSH_VERSION/libssh-mirror-libssh-$LIBSSH_VERSION.tar.gz"
ARG LIBSSH_SHA256=6cc403619d35b3ebdb42e712e70240b54ba51cd9bb88214e9d16ed19ef6ab103
# LIBSSH_STATIC=1 is REQUIRED to link statically against libssh.a so add to pkg-config file
# make does not -j as it seems to be shaky, libssh.a used before created
RUN \
  wget $WGET_OPTS -O libssh.tar.gz "$LIBSSH_URL" && \
  echo "$LIBSSH_SHA256  libssh.tar.gz" | sha256sum --status -c - && \
  tar xf libssh.tar.gz && cd libssh* && mkdir build && cd build && \
  echo -e 'Requires.private: libssl libcrypto zlib \nLibs.private: -DLIBSSH_STATIC=1 -lssh\nCflags.private: -DLIBSSH_STATIC=1 -I${CMAKE_INSTALL_FULL_INCLUDEDIR}' >> ../libssh.pc.cmake && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_SYSTEM_ARCH=$(arch) \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DPICKY_DEVELOPER=ON \
    -DBUILD_STATIC_LIB=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_GSSAPI=OFF \
    -DWITH_BLOWFISH_CIPHER=ON \
    -DWITH_SFTP=ON \
    -DWITH_SERVER=OFF \
    -DWITH_ZLIB=ON \
    -DWITH_PCAP=ON \
    -DWITH_DEBUG_CRYPTO=OFF \
    -DWITH_DEBUG_PACKET=OFF \
    -DWITH_DEBUG_CALLTRACE=OFF \
    -DUNIT_TESTING=OFF \
    -DCLIENT_TESTING=OFF \
    -DSERVER_TESTING=OFF \
    -DWITH_EXAMPLES=OFF \
    -DWITH_INTERNAL_DOC=OFF \
    .. && \
  make install


# has to be before theora
# bump: ogg /OGG_VERSION=([\d.]+)/ https://github.com/xiph/ogg.git|*
# bump: ogg after ./hashupdate Dockerfile OGG $LATEST
# bump: ogg link "CHANGES" https://github.com/xiph/ogg/blob/master/CHANGES
# bump: ogg link "Source diff $CURRENT..$LATEST" https://github.com/xiph/ogg/compare/v$CURRENT..v$LATEST
ARG OGG_VERSION=1.3.5
ARG OGG_URL="https://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz"
ARG OGG_SHA256=0eb4b4b9420a0f51db142ba3f9c64b333f826532dc0f48c6410ae51f4799b664
RUN \
  wget $WGET_OPTS -O libogg.tar.gz "$OGG_URL" && \
  echo "$OGG_SHA256  libogg.tar.gz" | sha256sum --status -c - && \
  tar xf libogg.tar.gz && \
  cd libogg-* && ./configure --disable-shared --enable-static && \
  make -j$(nproc) install

# bump: twolame /TWOLAME_VERSION=([\d.]+)/ https://github.com/njh/twolame.git|*
# bump: twolame after ./hashupdate Dockerfile TWOLAME $LATEST
# bump: twolame link "Source diff $CURRENT..$LATEST" https://github.com/njh/twolame/compare/v$CURRENT..v$LATEST
ARG TWOLAME_VERSION=0.4.0
ARG TWOLAME_URL="https://github.com/njh/twolame/releases/download/$TWOLAME_VERSION/twolame-$TWOLAME_VERSION.tar.gz"
ARG TWOLAME_SHA256=cc35424f6019a88c6f52570b63e1baf50f62963a3eac52a03a800bb070d7c87d
RUN \
  wget $WGET_OPTS -O twolame.tar.gz "$TWOLAME_URL" && \
  echo "$TWOLAME_SHA256  twolame.tar.gz" | sha256sum --status -c - && \
  tar xf twolame.tar.gz && \
  cd twolame-* && ./configure --disable-shared --enable-static --disable-sndfile --with-pic && \
  make -j$(nproc) install

# bump: vorbis /VORBIS_VERSION=([\d.]+)/ https://github.com/xiph/vorbis.git|*
# bump: vorbis after ./hashupdate Dockerfile VORBIS $LATEST
# bump: vorbis link "CHANGES" https://github.com/xiph/vorbis/blob/master/CHANGES
# bump: vorbis link "Source diff $CURRENT..$LATEST" https://github.com/xiph/vorbis/compare/v$CURRENT..v$LATEST
ARG VORBIS_VERSION=1.3.7
ARG VORBIS_URL="https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz"
ARG VORBIS_SHA256=0e982409a9c3fc82ee06e08205b1355e5c6aa4c36bca58146ef399621b0ce5ab
RUN \
  wget $WGET_OPTS -O libvorbis.tar.gz "$VORBIS_URL" && \
  echo "$VORBIS_SHA256  libvorbis.tar.gz" | sha256sum --status -c - && \
  tar xf libvorbis.tar.gz && \
  cd libvorbis-* && ./configure --disable-shared --enable-static --disable-oggtest && \
  make -j$(nproc) install

# bump: libwebp /LIBWEBP_VERSION=([\d.]+)/ https://github.com/webmproject/libwebp.git|*
# bump: libwebp after ./hashupdate Dockerfile LIBWEBP $LATEST
# bump: libwebp link "Release notes" https://github.com/webmproject/libwebp/releases/tag/v$LATEST
# bump: libwebp link "Source diff $CURRENT..$LATEST" https://github.com/webmproject/libwebp/compare/v$CURRENT..v$LATEST
ARG LIBWEBP_VERSION=1.3.1
ARG LIBWEBP_URL="https://github.com/webmproject/libwebp/archive/v$LIBWEBP_VERSION.tar.gz"
ARG LIBWEBP_SHA256=1c45f135a20c629c31cebcba62e2b399bae5d6e79851aa82ec6686acedcf6f65
RUN \
  wget $WGET_OPTS -O libwebp.tar.gz "$LIBWEBP_URL" && \
  echo "$LIBWEBP_SHA256  libwebp.tar.gz" | sha256sum --status -c - && \
  tar xf libwebp.tar.gz && \
  cd libwebp-* && ./autogen.sh && ./configure --disable-shared --enable-static --with-pic --enable-libwebpmux --disable-libwebpextras --disable-libwebpdemux --disable-sdl --disable-gl --disable-png --disable-jpeg --disable-tiff --disable-gif && \
  make -j$(nproc) install


# bump: libvpx /VPX_VERSION=([\d.]+)/ https://github.com/webmproject/libvpx.git|*
# bump: libvpx after ./hashupdate Dockerfile VPX $LATEST
# bump: libvpx link "CHANGELOG" https://github.com/webmproject/libvpx/blob/master/CHANGELOG
# bump: libvpx link "Source diff $CURRENT..$LATEST" https://github.com/webmproject/libvpx/compare/v$CURRENT..v$LATEST
ARG VPX_VERSION=1.13.0
ARG VPX_URL="https://github.com/webmproject/libvpx/archive/v$VPX_VERSION.tar.gz"
ARG VPX_SHA256=cb2a393c9c1fae7aba76b950bb0ad393ba105409fe1a147ccd61b0aaa1501066
RUN \
  wget $WGET_OPTS -O libvpx.tar.gz "$VPX_URL" && \
  echo "$VPX_SHA256  libvpx.tar.gz" | sha256sum --status -c - && \
  tar xf libvpx.tar.gz && \
  cd libvpx-* && ./configure --enable-static --enable-vp9-highbitdepth --disable-shared --disable-unit-tests --disable-examples && \
  make -j$(nproc) install

# bump: speex /SPEEX_VERSION=([\d.]+)/ https://github.com/xiph/speex.git|*
# bump: speex after ./hashupdate Dockerfile SPEEX $LATEST
# bump: speex link "ChangeLog" https://github.com/xiph/speex//blob/master/ChangeLog
# bump: speex link "Source diff $CURRENT..$LATEST" https://github.com/xiph/speex/compare/$CURRENT..$LATEST
ARG SPEEX_VERSION=1.2.1
ARG SPEEX_URL="https://github.com/xiph/speex/archive/Speex-$SPEEX_VERSION.tar.gz"
ARG SPEEX_SHA256=beaf2642e81a822eaade4d9ebf92e1678f301abfc74a29159c4e721ee70fdce0
RUN \
  wget $WGET_OPTS -O speex.tar.gz "$SPEEX_URL" && \
  echo "$SPEEX_SHA256  speex.tar.gz" | sha256sum --status -c - && \
  tar xf speex.tar.gz && \
  cd speex-Speex-* && ./autogen.sh && ./configure --disable-shared --enable-static && \
  make -j$(nproc) install

# http://websvn.xvid.org/cvs/viewvc.cgi/trunk/xvidcore/build/generic/configure.in?revision=2146&view=markup
# bump: xvid /XVID_VERSION=([\d.]+)/ svn:http://anonymous:@svn.xvid.org|/^release-(.*)$/|/_/./|^1
# bump: xvid after ./hashupdate Dockerfile XVID $LATEST
# add extra CFLAGS that are not enabled by -O3
ARG XVID_VERSION=1.3.7
ARG XVID_URL="https://downloads.xvid.com/downloads/xvidcore-$XVID_VERSION.tar.gz"
ARG XVID_SHA256=abbdcbd39555691dd1c9b4d08f0a031376a3b211652c0d8b3b8aa9be1303ce2d
RUN \
  wget $WGET_OPTS -O libxvid.tar.gz "$XVID_URL" && \
  echo "$XVID_SHA256  libxvid.tar.gz" | sha256sum --status -c - && \
  tar xf libxvid.tar.gz && \
  cd xvidcore/build/generic && \
  CFLAGS="$CFLAGS -fstrength-reduce -ffast-math" ./configure && \
  make -j$(nproc) && make install

# bump: ffmpeg /FFMPEG_VERSION=([\d.]+)/ https://github.com/FFmpeg/FFmpeg.git|^6
# bump: ffmpeg after ./hashupdate Dockerfile FFMPEG $LATEST
# bump: ffmpeg link "Changelog" https://github.com/FFmpeg/FFmpeg/blob/n$LATEST/Changelog
# bump: ffmpeg link "Source diff $CURRENT..$LATEST" https://github.com/FFmpeg/FFmpeg/compare/n$CURRENT..n$LATEST
ARG FFMPEG_VERSION=6.0
ARG FFMPEG_URL="https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2"
ARG FFMPEG_SHA256=47d062731c9f66a78380e35a19aac77cebceccd1c7cc309b9c82343ffc430c3d
# sed changes --toolchain=hardened -pie to -static-pie
# extra ldflags stack-size=2097152 is to increase default stack size from 128KB (musl default) to something
# more similar to glibc (2MB). This fixing segfault with libaom-av1 and libsvtav1 as they seems to pass
# large things on the stack.

RUN \
  wget $WGET_OPTS -O ffmpeg.tar.bz2 "$FFMPEG_URL" && \
  echo "$FFMPEG_SHA256  ffmpeg.tar.bz2" | sha256sum --status -c - && \
  tar xf ffmpeg.tar.bz2 && \
  cd ffmpeg-* && \
  sed -i 's/add_ldexeflags -fPIE -pie/add_ldexeflags -fPIE -static-pie/' configure && \
  ./configure \
  --pkg-config-flags="--static" \
  --extra-cflags="-fopenmp -O2" \
  --extra-ldflags="-fopenmp -Wl,-z,stack-size=4194304" \
  --toolchain=hardened \
    --disable-debug \
    --disable-shared \
    --disable-ffplay \
    --disable-doc \
    --enable-static \
    --enable-gpl \
    --enable-version3 \
    --enable-nonfree \
    --disable-avdevice \
    --disable-swscale \
    --disable-postproc \
    --disable-ffmpeg \
    \
    --disable-iconv \
    --disable-zlib \
    --disable-bzlib \
    --disable-lzma \
    --disable-sdl2 \
    --disable-schannel \
    --disable-xlib \
    \
    --disable-muxers \
    --disable-demuxers \
    --disable-hwaccels \
    --disable-d3d11va \
    --disable-nvenc \
    --disable-dxva2 \
    --disable-bsfs \
    --disable-filters \
    --disable-parsers \
    --disable-indevs \
    --disable-outdevs \
    --disable-encoders \
    --disable-decoders \
    --disable-bsfs \
    \
    --enable-demuxer=image2 \
    --enable-demuxer=aac \
    --enable-demuxer=ac3 \
    --enable-demuxer=aiff \
    --enable-demuxer=ape \
    --enable-demuxer=asf \
    --enable-demuxer=au \
    --enable-demuxer=avi \
    --enable-demuxer=flac \
    --enable-demuxer=flv \
    --enable-demuxer=matroska \
    --enable-demuxer=mov \
    --enable-demuxer=m4v \
    --enable-demuxer=mp3 \
    --enable-demuxer=mpc* \
    --enable-demuxer=ogg \
    --enable-demuxer=pcm* \
    --enable-demuxer=rm \
    --enable-demuxer=shorten \
    --enable-demuxer=tak \
    --enable-demuxer=tta \
    --enable-demuxer=wav \
    --enable-demuxer=wv \
    --enable-demuxer=xwma \
    --enable-demuxer=dsf \
    --enable-demuxer=dts \
    --enable-demuxer=truehd \
    \
    --enable-decoder=aac* \
    --enable-decoder=ac3 \
    --enable-decoder=alac \
    --enable-decoder=als \
    --enable-decoder=ape \
    --enable-decoder=atrac* \
    --enable-decoder=eac3 \
    --enable-decoder=flac \
    --enable-decoder=gsm* \
    --enable-decoder=mp1* \
    --enable-decoder=mp2* \
    --enable-decoder=mp3* \
    --enable-decoder=mpc* \
    --enable-decoder=opus \
    --enable-decoder=ra* \
    --enable-decoder=ralf \
    --enable-decoder=shorten \
    --enable-decoder=tak \
    --enable-decoder=tta \
    --enable-decoder=vorbis \
    --enable-decoder=wavpack \
    --enable-decoder=wma* \
    --enable-decoder=pcm* \
    --enable-decoder=dsd* \
    --enable-decoder=truehd \
    --enable-decoder=mjpeg \
    \
    --enable-parser=aac* \
    --enable-parser=ac3 \
    --enable-parser=cook \
    --enable-parser=dca \
    --enable-parser=flac \
    --enable-parser=gsm \
    --enable-parser=mpegaudio \
    --enable-parser=tak \
    --enable-parser=vorbis \
    \
    --enable-gray \
    --enable-iconv \
    --enable-libfdk-aac \
    --enable-libgsm \
    --enable-libmp3lame \
    --enable-libopencore-amrnb \
    --enable-libopencore-amrwb \
    --enable-libopenjpeg \
    --enable-libopus \
    --enable-librubberband \
    --enable-libshine \
    --enable-libspeex \
    --enable-libsrt \
    --enable-libssh \
    --enable-libtwolame \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwebp \
    --enable-libxvid \
  || (cat ffbuild/config.log ; false) \
  && make -j$(nproc) install

# make sure binaries has no dependencies, is relro, pie and stack nx
COPY checkelf /
RUN \
  /checkelf /usr/local/bin/ffmpeg && \
  /checkelf /usr/local/bin/ffprobe

FROM scratch AS final1
COPY --from=builder /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/cert.pem

# clamp all files into one layer
FROM scratch AS final2
COPY --from=final1 / /

FROM final2

ENTRYPOINT ["/ffmpeg"]