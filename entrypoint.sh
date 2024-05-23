#!/bin/sh
set -e

##
# Utility functions
echo() { printf '%s' "${*}"; }
error() { echo "error: $*" >&2; }
die() { echo "error: $*" >&2; exit 1; }
upper() { printf '%s' "${*}" | tr '[a-z]' '[A-Z]'; }
lower() { printf '%s' "${*}" | tr '[A-Z]' '[a-z]'; }
debug()
{
	"${DEBUG}" || return
	printf '%s:\n' "${1}"
	printf '%s' "${2}" | paste /dev/null -
}

##
# 1: GITHUB_ACTIONS_RUNNER_CONTEXT
gh_url()
{
	: 'gh_url:' "$@"
	! test -z "${1}" || die "missing parameter 'github_actions_runner_context'"

	# 1:username, 2:repository
	set -- "$(printf '%s' "${1}" | cut -d/ -f1)" "$(printf '%s' "${1}" | cut -d/ -f2)"

	! test -z "${1}" || die 'no username found in context'

	if test -z "${2}"; then
		echo "https://api.github.com/orgs/${1}/actions/runners/registration-token"
	else
		echo "https://api.github.com/repos/${1}/${2}/actions/runners/registration-token"
	fi
}

##
# 1:registration_url
__gh_token_request()
{
	: '__gh_token_request:' "$@"
	curl -XPOST -fsSL \
		-H 'Accept: application/vnd.github.v3+json' \
		-H "Authorization: token ${GITHUB_TOKEN}" \
		"${1}"
}

##
# 1:registration_url
gh_token()
{
	: 'gh_token:' "$@"
	! test -z "${1}" || die "missing parameter 'registration_url'"
	set -- "$(__gh_token_request "${1}")"
	set -- "${1}" "$(printf '%s' "${1}" | jq --raw-output '.token')"
	if test "${2}" = 'null'; then
		error 'failed to get token'
		debug 'payload' "${1}"
		exit 1
	fi
	echo "${2}"
}

##
# 1:runner_name
gh_runner_id()
{
	set -- "${1}" "$(openssl rand -hex 6)"
	! test -z "$#" || die "failed to generate suffix for '${1}'"
	echo "${1}_${2}"
}

## main ##

case "$(lower "${DEBUG}")" in
(N|no|0|false)	DEBUG='false';;
(*)		DEBUG='true';;
esac

! test -z "${GITHUB_TOKEN}" || die "not set 'GITHUB_TOKEN'"

printf 'hello745\n'

RUNNER_ID="$(gh_runner_id "${RUNNER_NAME}")"
REGISTRATION_URL="$(gh_url "${RUNNER_CONTEXT:-${GITHUB_REPOSITORY}}")"
TEMP_TOKEN="$(gh_token "${REGISTRATION_URL}")"

printf "runner_id ${RUNNER_ID} -- registration_url ${REGISTRATION_URL} -- temp_token ${TEMP_TOKEN}\n"

retry=0
while test -z "${TEMP_TOKEN}"; do
	timer="$((1 << retry))"
	test "${timer}" -le '300' || timer='300'
	printf 'failed to acquire token, sleeping for %d\n' "${timer}"
	sleep "${timer}" || break # allow sigint to terminate the loop
	TEMP_TOKEN="$(gh_token "${REGISTRATION_URL}")"
	retry="$((retry+1))"
done
unset retry nth timer

sudo ./install-gh-runner.sh latest

./config.sh \
	--name "${RUNNER_ID}" \
	--work "${RUNNER_WORKDIR:-_work}" \
        --labels "${RUNNER_LABELS}" \
	--url "https://github.com/${RUNNER_CONTEXT}" \
	--token "${TEMP_TOKEN}" \
        --unattended \
	--ephemeral \
	--disableupdate

cleanup() { ./config.sh remove --unattended --token "${TEMP_TOKEN}"; }
trap 'cleanup; exit 130' 'INT'
trap 'cleanup; exit 143' 'TERM'

# Using `exec` here would remove our traps.
./run.sh "$*"
