# This container is used to build binaries for Debian 11 (aka bullseye)
ARG DEBIAN_RELEASE=bullseye

# The "python" base image is used to get a more up-to-date Python (buster ships with Python 3.7)
FROM python:3.13-slim-$DEBIAN_RELEASE
ARG NODEJS=22

RUN apt-get update -y && \
	apt-get install -y \
		autoconf \
		build-essential \
		curl \
		libmagic-dev \
		libssl-dev \
		libtool \
		pkg-config \
		time

# install Node.js via nvm
# https://github.com/nvm-sh/nvm#install--update-script
#
# we want to have repeatable builds independented from Debian updating their Node.js packages
ENV NODE_VERSION=${NODEJS}
ENV NVM_VERSION=0.40.3
ENV NVM_DIR /root/.nvm

RUN echo ">> Installing Node.js v${NODE_VERSION} ..."

# copy the binaries to the shared place and clean up the things
RUN curl --fail --location --retry 3 --retry-delay 5 \
    https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash && \
    echo "${NODE_VERSION}" > .nvmrc && \
    . ${NVM_DIR}/nvm.sh && \
    nvm install && \
    ls -lh ${NVM_DIR}/versions/node && \
    echo "Copying Node.js binaries to /usr/local/bin ..." && \
    cp -r ${NVM_DIR}/versions/node/$(nvm current)/bin/* /usr/local/bin && \
    cp -r ${NVM_DIR}/versions/node/$(nvm current)/lib/* /usr/local/lib && \
    echo "Cleaning up ..." && \
    rm -rf ${NVM_DIR}

RUN node -v && \
    npm -v && \
    python3 --version && \
    env

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
