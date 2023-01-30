# this container is used to build binaries for Debian 10 (aka oldstable)
FROM node:16.16-buster-slim

RUN apt-get update -y && \
	apt-get install -y \
		autoconf \
		build-essential \
		curl \
		libmagic-dev \
		libssl-dev \
		libtool \
		pkg-config \
		python3

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

RUN npx node-pre-gyp configure rebuild

RUN npx node-pre-gyp package && \
	cp build/stage/Automattic/node-yara/raw/master/binaries/yara-*.tar.gz /tmp && \
	ls -lh /tmp
