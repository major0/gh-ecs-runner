FROM ubuntu:20.04@sha256:8ae9bafbb64f63a50caab98fd3a5e37b3eb837a3e0780b78e5218e63193961f9

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
RUN set -e \
        && sh install-gh-runner.sh "${VERSION}" \
        && rm install-gh-runner.sh \
        && rm -rf /var/lib/apt/lists/*


COPY entrypoint.sh entrypoint.sh
USER runner
ENTRYPOINT ["./entrypoint.sh"]
