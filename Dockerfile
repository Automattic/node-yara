# This container is used to build binaries for Debian 11 (aka stable)
# https://hub.docker.com/_/node/
ARG NODEJS=16.16
FROM node:$NODEJS-bullseye-slim

RUN apt-get update -y && \
	apt-get install -y \
		autoconf \
		build-essential \
		curl \
		libmagic-dev \
		libssl-dev \
		libtool \
		pkg-config \
		python3 \
		time

WORKDIR /opt/a8c/node-yara
ENV HOME /opt/a8c/node-yara

# leverage the build cache by copying only the dependencies definition
COPY package.json .
RUN npm install --ignore-scripts

# now, let's copy the rest of the code
COPY . .

# we do not need root anymore
RUN chown -R nobody:nogroup ${HOME}
USER nobody

# build and test it
RUN time -p npx node-pre-gyp configure rebuild && \
	npm t

# see dynamic dependencies
RUN ldd build/Release/yara.node

# prepare a tar.gz package and copy it to the binaries/ directory
RUN npx node-pre-gyp package && \
	cp build/stage/Automattic/node-yara/raw/master/binaries/yara-*.tar.gz ./binaries && \
	ls -lh ./binaries
