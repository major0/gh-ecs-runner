#!/bin/sh
set -e

case "${1}" in
(latest) VERSION="$(curl -s 'https://api.github.com/repos/actions/runner/releases/latest' | jq -r .tag_name | tr -d 'v')}";;
(*)	 VERSION="${1}";;
esac

cleanup() {
	rm -f "actions-runner-linux-x64-${VERSION}.tar.gz" './bin/installdependencies.sh'
        rm -rf /var/lib/apt/lists/*
}
trap cleanup EXIT

curl -sSLO "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-x64-${VERSION}.tar.gz"
tar -zxvf "actions-runner-linux-x64-${VERSION}.tar.gz"
rm -f "actions-runner-linux-x64-${VERSION}.tar.gz"
./bin/installdependencies.sh
chown -R runner:runner '/home/runner'
