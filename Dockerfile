FROM ubuntu:20.04@sha256:8ae9bafbb64f63a50caab98fd3a5e37b3eb837a3e0780b78e5218e63193961f9


RUN set -e \
	&& apt-get update \
	&& DEBIAN_FRONTEND='noninteractive' \
	   apt-get install -y \
		awscli \
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

RUN GITHUB_RUNNER_VERSION="${GITHUB_RUNNER_VERSION:-$(curl -s 'https://api.github.com/repos/actions/runner/releases/latest' | jq -r .tag_name | tr -d 'v')}" \
	&& curl -sSLO "https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" \
	&& tar -zxvf "actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" \
	&& rm -f "actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" \
	&& './bin/installdependencies.sh' \
	&& chown -R runner:runner '/home/runner'

COPY entrypoint.sh entrypoint.sh
USER runner
ENTRYPOINT ["./entrypoint.sh"]
