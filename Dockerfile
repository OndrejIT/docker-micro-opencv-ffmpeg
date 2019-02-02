FROM docker.io/python:3.7-alpine
MAINTAINER Ondrej Barta <ondrej@ondrej.it>

RUN \
	echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
	apk update && \
	apk add \
	bash \
	tzdata \
	libass \
	libstdc++ \
	libpng \
	libjpeg \
	xvidcore \
	x264-libs \
	x265 \
	libvpx \
	libvorbis \
	opus \
	lame \
	fdk-aac \
	jasper-libs \
	freetype && \

	# Install build tools
	apk add --virtual build-deps \
	coreutils \
	fdk-aac-dev \
	freetype-dev \
	x264-dev \
	x265-dev \
	yasm \
	yasm-dev \
	libogg-dev \
	libvorbis-dev \
	opus-dev \
	libvpx-dev \
	lame-dev \
	xvidcore-dev \
	libass-dev \
	openssl-dev \
	musl-dev \
	make \
	cmake \
	gcc \
	g++ \
	build-base \
	libjpeg-turbo-dev \
	libpng-dev \
	clang-dev \
	clang \
	linux-headers \
	git \
	curl && \

	# FFmpeg
	export SRC=/usr \
	export FFMPEG_VERSION=4.1 \

	DIR=$(mktemp -d) && cd ${DIR} && \
	curl -Os http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
	tar xzvf ffmpeg-${FFMPEG_VERSION}.tar.gz && \
	cd ffmpeg-${FFMPEG_VERSION} && \
	./configure --prefix="${SRC}" --extra-cflags="-I${SRC}/include" --extra-ldflags="-L${SRC}/lib" --bindir="${SRC}/bin" \
		--extra-libs=-ldl --enable-version3 --enable-libmp3lame --enable-pthreads --enable-libx264 --enable-libxvid --enable-gpl \
		--enable-postproc --enable-nonfree --enable-avresample --enable-libfdk-aac --disable-debug --enable-small --enable-openssl \
		--enable-libx265 --enable-libopus --enable-libvorbis --enable-libvpx --enable-libfreetype --enable-libass \
		--enable-shared --enable-pic && \
	make -j8 && \
	make install && \
	make distclean && \
	hash -r && \
	cd /tmp && \
	rm -rf ${DIR} && \

	# PIP
	pip install --no-cache-dir \
	Cython==0.29.4 \
	numpy==1.16.1 \
	Pillow==5.4.1 \
	av==6.1.2 && \

	## OpenCV
	export OPENCV_VERSION=3.4.5 \
	export PYTHON_VERSION=`python -c 'import platform; print(".".join(platform.python_version_tuple()[:2]))'` \
	export CC=/usr/bin/clang \
	export CXX=/usr/bin/clang++ && \
	# Contrib
	CONTRIB_DIR=$(mktemp -d) && cd ${CONTRIB_DIR} && \
	curl -SL -O https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.tar.gz && \
	tar xzvf ${OPENCV_VERSION}.tar.gz && \

	DIR=$(mktemp -d) && cd ${DIR} && \
	curl -SL -O https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz && \
	tar xzvf ${OPENCV_VERSION}.tar.gz && \
	cd opencv-${OPENCV_VERSION} && \
	mkdir build && \
	cd build && \
	cmake \
	    -D OPENCV_EXTRA_MODULES_PATH=${CONTRIB_DIR}/opencv_contrib-${OPENCV_VERSION}/modules \
		-D CMAKE_BUILD_TYPE=RELEASE \
		-D INSTALL_C_EXAMPLES=OFF \
		-D INSTALL_PYTHON_EXAMPLES=OFF \
		-D CMAKE_INSTALL_PREFIX=/usr/local \
		-D BUILD_EXAMPLES=OFF \
		-D BUILD_opencv_python3=ON \
		-D PYTHON_DEFAULT_EXECUTABLE=/usr/local/bin/python3 \
		-D PYTHON_INCLUDE_DIRS=/usr/local/include/python${PYTHON_VERSION}m \
		-D PYTHON_EXECUTABLE=/usr/local/bin/python${PYTHON_VERSION} \
		-D PYTHON_LIBRARY=/usr/local/lib/libpython${PYTHON_VERSION}m.so \
		.. && \
	make -j8 && \
	make install && \
	cd /tmp && \
	rm -rf ${DIR} && \

	# Cleaning up
	apk del build-deps && \
	rm -rf /var/cache/apk/*
