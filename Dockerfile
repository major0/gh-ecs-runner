FROM ubuntu:22.04

ARG VERSION=latest

RUN set -e \
	&& apt-get update \
	&& DEBIAN_FRONTEND='noninteractive' \
	   apt-get install -y \
		awscli \
		bc \
		build-essential \
		curl \
		git \
		jq \
		sudo \
		wget \
		unzip \
	&& rm -rf /var/lib/apt/lists/*

RUN set -e \
	&& addgroup runner \
	&& adduser \
		--system \
		--disabled-password \
		--home /home/runner \
		--ingroup runner \
		runner

WORKDIR /home/runner

COPY install-gh-runner.sh .
#RUN set -e \
#        && sh install-gh-runner.sh "${VERSION}" \
#        && rm install-gh-runner.sh \
#        && rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh entrypoint.sh
USER runner
ENTRYPOINT ["./entrypoint.sh"]
