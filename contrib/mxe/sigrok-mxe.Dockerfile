# MXE build image for PulseView / libsigrok Windows builds, one target per
# image. Based on sigrokproject/sigrok-build's docker/sigrok-mxe.Dockerfile
# (sigrok's published ghcr.io/sigrokproject/sigrok-mxe image is no longer
# pullable), with these changes:
#   - one MXE target per image (MXE_TARGET build arg), so each image is
#     built in its own CI job and stays within GitHub's 6 hour job limit
#   - libusb 1.0.30 with sigrok's RAW_IO policy instead of sigrok's old
#     event-abstraction fork (libusb1.mk and libusb1-1-fixes.patch here)
#   - Debian bookworm pinned (the MXE commit below predates trixie's
#     compilers)
#
# Build context: this folder plus mxe_fixes.patch and hidapi_fixes.patch
# from sigrok-build/docker (.github/workflows/mxe-image.yml copies them in).

FROM debian:bookworm

ARG MXE_TARGET=i686-w64-mingw32.static.posix

ENV BASE_DIR=/opt
ENV MXE_DIR=$BASE_DIR/mxe
ENV MXE_TARGETS=$MXE_TARGET
ENV MXE_PLUGIN_DIRS=plugins/examples/qt5-freeze

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		sudo autoconf automake autopoint bash bison bzip2 flex g++ \
		g++-multilib sdcc gettext git gperf gtk-doc-tools intltool \
		libc6-dev-i386 libgdk-pixbuf2.0-dev libltdl-dev libssl-dev \
		libtool-bin libxml-parser-perl lzip make openssl p7zip-full \
		patch perl pkg-config python3 python-is-python3 ruby sed unzip \
		wget xz-utils doxygen nsis ca-certificates cmake \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR $BASE_DIR
COPY mxe_fixes.patch hidapi_fixes.patch libusb1.mk libusb1-1-fixes.patch $BASE_DIR/
RUN git clone https://github.com/mxe/mxe.git $MXE_DIR \
	&& cd $MXE_DIR \
	&& git reset --hard b48b3cc7085548e896fe967dc6371ff9951390a4 \
	&& patch -p1 < $BASE_DIR/mxe_fixes.patch \
	&& patch -p1 < $BASE_DIR/hidapi_fixes.patch \
	&& cp $BASE_DIR/libusb1.mk $BASE_DIR/libusb1-1-fixes.patch src/

# One RUN per group, so a failed or timed-out build resumes from the cache.
ENV MXE_MAKE="make -j4 JOBS=2 MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1"
RUN cd $MXE_DIR && $MXE_MAKE MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" gcc
RUN cd $MXE_DIR && $MXE_MAKE MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" glib
RUN cd $MXE_DIR && $MXE_MAKE MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" \
		libzip libusb1 libftdi1 hidapi
RUN cd $MXE_DIR && $MXE_MAKE MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" glibmm
RUN cd $MXE_DIR && $MXE_MAKE MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" \
		qtbase qtimageformats qtbase_CONFIGURE_OPTS='-no-sql-mysql'
RUN cd $MXE_DIR && $MXE_MAKE MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" \
		qtsvg qttools qttranslations qtbase_CONFIGURE_OPTS='-no-sql-mysql'
RUN cd $MXE_DIR && $MXE_MAKE MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" boost
RUN cd $MXE_DIR && $MXE_MAKE MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" \
		check gendef libieee1284 nettle qwt qtbase_CONFIGURE_OPTS='-no-sql-mysql'

# Downloads and logs are not needed in the image.
RUN rm -rf $MXE_DIR/pkg $MXE_DIR/log $MXE_DIR/.ccache \
	&& grep Version $MXE_DIR/usr/$MXE_TARGET/lib/pkgconfig/libusb-1.0.pc
