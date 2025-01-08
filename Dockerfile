# This container is used to build binaries for Debian 10 (aka buster)
FROM debian:buster-slim
ARG NODEJS=18.18

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

# install Node.js via nvm
# https://github.com/nvm-sh/nvm#install--update-script
#
# we want to have repeatable builds independented from Debian updating their Node.js packages
ENV NODE_VERSION=${NODEJS}
ENV NVM_VERSION=0.40.1
ENV NVM_DIR /root/.nvm

RUN echo ">> Installing Node.js v${NODE_VERSION} ..."

# copy the binaries to the shared place and clean up the things
RUN curl --fail --location --retry 3 --retry-delay 5 \
    https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash && \
    echo "${NODE_VERSION}" > .nvmrc && \
    . ${NVM_DIR}/nvm.sh && \
    nvm install && \
    echo "Copying Node.js binaries to /usr/local/bin ..." && \
    mv -v ${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/* /usr/local/bin && \
    mv -v ${NVM_DIR}/versions/node/v${NODE_VERSION}/lib/* /usr/local/lib && \
    echo "Cleaning up ..." && \
    rm -rf ${NVM_DIR}

RUN node -v && \
    npm -v && \
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
