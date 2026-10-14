#!/usr/bin/env bash
# [SOURCE=<source>] ./run.sh <lucee.jar | luceeVersionQuery> <scenario>
#
# Same harness locally and in CI. Starts (or reuses) the squids and httpbin, sets the
# scenario's proxy via SOURCE, runs webroot/index.cfm through script-runner, then
# captures run.txt, results.json, the squid lines written during the run and the Lucee
# working dir into <repo>/test-output/http-proxy/<label>/<source>/<scenario>/
#
# Scenarios (the proxy):
#   none       no proxy (control)
#   good       squid, no auth
#   auth       basic-auth squid, user lucee / secret
#   wrongpass  basic-auth squid, wrong password
#   nocreds    basic-auth squid, no creds
#   deadport   localhost:3199, nothing listening: anything that still works bypassed the proxy
#   badhost    unresolvable proxy host
#
# Sources (where the proxy is configured):
#   cfconfig         .CFConfig.json via -Dlucee.base.config (default)
#   baseconfig       .CFConfig.json via the LUCEE_BASE_CONFIG env var
#   context          .CFConfig.json placed in lucee-server/context before startup
#   env              LUCEE_PROXY_SERVER / _PORT / _USERNAME / _PASSWORD (8.0+)
#   env-vs-cfconfig  env vars as above, plus a dead proxy (localhost:3199) in .CFConfig.json
#   app              Application.cfc this.proxy only, no server proxy
#
# SCRIPT_RUNNER: script-runner checkout (default <repo>/../script-runner)
# LOG_LEVEL: Lucee log level on the console (default info)
set -euo pipefail

LUCEE="$1"
SCENARIO="$2"
SOURCE="${SOURCE:-cfconfig}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SCRIPT_RUNNER="${SCRIPT_RUNNER:-$REPO/../script-runner}"

SQUID_PORT=3138
SQUID_AUTH_PORT=3139
HTTPBIN_PORT=8091
MAVEN_PORT=8092
# testlab-maven and testlab-httpbin resolve only inside this network, so with a proxy configured
# anything that bypasses it fails with an unknown host
NETWORK=testlab

winpath() {
	if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi
}

if [[ "$LUCEE" == *.jar ]]; then
	LABEL="$(basename "$LUCEE" .jar)-$(md5sum "$LUCEE" | cut -c1-8)"
	LUCEE_ARG="-DluceeJar=$LUCEE"
else
	LABEL="${LUCEE//\//-}"
	LUCEE_ARG="-DluceeVersionQuery=$LUCEE"
fi

# major.minor from the jar name or the version query, e.g. 6.2
[[ "$LABEL" =~ ([0-9]+\.[0-9]+) ]] || { echo "can't tell the Lucee version from [$LABEL]"; exit 1; }
LUCEE_MAJOR_MINOR="${BASH_REMATCH[1]}"

OUT="$REPO/test-output/http-proxy/$LABEL/$SOURCE/$SCENARIO"
WORK="$OUT/work"
CONTEXT="$WORK/lucee/lucee-server/context"
rm -rf "$OUT"
mkdir -p "$OUT/home" "$CONTEXT"

PROXY_HOST=""
PROXY_PORT=""
PROXY_USER=""
PROXY_PASS=""
case "$SCENARIO" in
	none) ;;
	good) PROXY_HOST=localhost; PROXY_PORT=$SQUID_PORT ;;
	auth) PROXY_HOST=localhost; PROXY_PORT=$SQUID_AUTH_PORT; PROXY_USER=lucee; PROXY_PASS=secret ;;
	wrongpass) PROXY_HOST=localhost; PROXY_PORT=$SQUID_AUTH_PORT; PROXY_USER=lucee; PROXY_PASS=wrong ;;
	nocreds) PROXY_HOST=localhost; PROXY_PORT=$SQUID_AUTH_PORT ;;
	deadport) PROXY_HOST=localhost; PROXY_PORT=3199 ;;
	badhost) PROXY_HOST=proxy.invalid; PROXY_PORT=$SQUID_PORT ;;
	*) echo "unknown scenario [$SCENARIO]"; exit 1 ;;
esac

# the no-proxy control goes direct to the published ports, every other scenario uses the
# network-only names so only proxied requests can work
if [ "$SCENARIO" = none ]; then
	MAVEN_REPO="http://localhost:$MAVEN_PORT/maven2/"
	TARGET_HTTP="http://localhost:$HTTPBIN_PORT"
else
	MAVEN_REPO="http://testlab-maven/maven2/"
	TARGET_HTTP="http://testlab-httpbin"
fi

# writes the base config plus the fake maven repos and a proxy block (none when host is empty) to $1
# Lucee writes its config back to the file it was given, so it always gets a generated copy
write_config() {
	local file="$1" host="$2" port="$3" user="$4" pass="$5"
	jq --arg repo "$MAVEN_REPO" --arg host "$host" --arg port "$port" --arg user "$user" --arg pass "$pass" \
		'.maven = { repository: [ $repo ], snapshotRepository: [ $repo ] }
		| if $host != "" then .proxy = ( { server: $host, port: ( $port | tonumber ) }
			+ ( if $user != "" then { username: $user, password: $pass } else {} end ) ) else . end' \
		"$HERE/.CFConfig-base.json" > "$file"
}

export_proxy_env() {
	[ -n "$PROXY_HOST" ] || return 0
	export LUCEE_PROXY_SERVER="$PROXY_HOST" LUCEE_PROXY_PORT="$PROXY_PORT"
	if [ -n "$PROXY_USER" ]; then
		export LUCEE_PROXY_USERNAME="$PROXY_USER" LUCEE_PROXY_PASSWORD="$PROXY_PASS"
	fi
}

CONFIG="$OUT/.CFConfig.json"
SR_CONFIG="$CONFIG"
APP_PROXY=0
case "$SOURCE" in
	cfconfig) write_config "$CONFIG" "$PROXY_HOST" "$PROXY_PORT" "$PROXY_USER" "$PROXY_PASS" ;;
	baseconfig)
		write_config "$CONFIG" "$PROXY_HOST" "$PROXY_PORT" "$PROXY_USER" "$PROXY_PASS"
		export LUCEE_BASE_CONFIG="$(winpath "$CONFIG")"
		SR_CONFIG="" ;;
	context)
		CONFIG="$CONTEXT/.CFConfig.json"
		write_config "$CONFIG" "$PROXY_HOST" "$PROXY_PORT" "$PROXY_USER" "$PROXY_PASS"
		SR_CONFIG="" ;;
	env)
		write_config "$CONFIG" "" "" "" ""
		export_proxy_env ;;
	env-vs-cfconfig)
		write_config "$CONFIG" localhost 3199 "" ""
		export_proxy_env ;;
	app)
		write_config "$CONFIG" "" "" "" ""
		APP_PROXY=1 ;;
	*) echo "unknown source [$SOURCE]"; exit 1 ;;
esac

ensure_container() {
	local name="$1"
	shift
	if ! docker ps --format '{{.Names}}' | grep -qx "$name"; then
		docker rm -f "$name" >/dev/null 2>&1 || true
		"$@"
		sleep 3
	fi
}

docker network inspect $NETWORK >/dev/null 2>&1 || docker network create $NETWORK >/dev/null

# images from Lucee's GHCR mirror (mirror-docker-images.yml in lucee/lucee), no Docker Hub rate limits
HTTPBIN_IMAGE=ghcr.io/lucee/httpbin:test-mirror
SQUID_IMAGE=ghcr.io/lucee/squid:test-mirror
NGINX_IMAGE=ghcr.io/lucee/nginx:test-mirror

ensure_container testlab-httpbin docker run -d --name testlab-httpbin --network $NETWORK -p $HTTPBIN_PORT:80 $HTTPBIN_IMAGE >/dev/null

# ipv6 off in the containers that go out to the internet: on Docker Desktop names can resolve to
# unreachable v6 addresses first, and squid doesn't fall back to v4 (503)
# the mirror's cache is a named volume by default: nginx's cache doesn't work on a Docker Desktop
# (Windows) bind mount, every request is a MISS. MAVEN_CACHE_DIR bind-mounts a host dir instead (CI, so it can be cached)
start_maven() {
	local cache=testlab-maven-cache
	if [ -n "${MAVEN_CACHE_DIR:-}" ]; then
		mkdir -p "$MAVEN_CACHE_DIR"
		# restored by the CI cache as the runner user, nginx runs as its own and needs to add dirs
		chmod -R a+rwX "$MAVEN_CACHE_DIR"
		cache="$(winpath "$MAVEN_CACHE_DIR")"
	fi
	docker create --name testlab-maven --network $NETWORK --sysctl net.ipv6.conf.all.disable_ipv6=1 -p $MAVEN_PORT:80 \
		-v "$cache:/var/cache/nginx/maven" $NGINX_IMAGE >/dev/null
	docker cp "$(winpath "$HERE/maven/nginx.conf")" testlab-maven:/etc/nginx/conf.d/default.conf
	docker start testlab-maven >/dev/null
}
ensure_container testlab-maven start_maven

start_squid() {
	local name="$1" port="$2" conf="$3"
	docker create --name "$name" --network $NETWORK --sysctl net.ipv6.conf.all.disable_ipv6=1 -p "$port":3128 $SQUID_IMAGE >/dev/null
	docker cp "$(winpath "$HERE/squid/$conf")" "$name":/etc/squid/squid.conf
	docker cp "$(winpath "$HERE/squid/passwd")" "$name":/etc/squid/passwd
	docker start "$name" >/dev/null
}
ensure_container testlab-squid start_squid testlab-squid $SQUID_PORT squid.conf
ensure_container testlab-squid-auth start_squid testlab-squid-auth $SQUID_AUTH_PORT squid-auth.conf

squid_lines() {
	docker exec "$1" sh -c 'wc -l < /var/log/squid/access.log'
}
before_squid=$(squid_lines testlab-squid)
before_auth=$(squid_lines testlab-squid-auth)

started=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# before 8.0 there's no maven.repository config, only this, which goes before Central rather than
# replacing it: a bypassing download falls back to Central instead of failing, so attribution is
# the mirror and squid logs. 8.0 uses the .CFConfig.json repos, so it still fails hard
if [ "${LUCEE_MAJOR_MINOR%%.*}" -lt 8 ]; then
	export LUCEE_MAVEN_DEFAULT_REPOSITORIES="$MAVEN_REPO"
fi

export SCENARIO SOURCE PROXY_HOST PROXY_PORT PROXY_USER PROXY_PASS APP_PROXY TARGET_HTTP
export RESULTS_FILE="$(winpath "$OUT/results.json")"
export LUCEE_LOGGING_FORCE_APPENDER=console
export LUCEE_LOGGING_FORCE_LEVEL="${LOG_LEVEL:-info}"

# empty user.home: MavenUtil copies from ~/.m2/repository when it can, which skips the network
ant -buildfile "$SCRIPT_RUNNER/build.xml" \
	"$LUCEE_ARG" \
	-Dwebroot="$(winpath "$HERE/webroot")" \
	-Dexecute=index.cfm \
	-DluceeCFConfig="${SR_CONFIG:+$(winpath "$SR_CONFIG")}" \
	-DuniqueWorkingDir="$(winpath "$WORK")" \
	-DpreCleanup=false \
	-DpostCleanup=false \
	-DjvmArgs="-Duser.home=$(winpath "$OUT/home")" \
	> "$OUT/run.txt" 2>&1 || echo "script-runner failed, see $OUT/run.txt"

docker exec testlab-squid sh -c "tail -n +$(( before_squid + 1 )) /var/log/squid/access.log" > "$OUT/squid.log"
docker exec testlab-squid-auth sh -c "tail -n +$(( before_auth + 1 )) /var/log/squid/access.log" > "$OUT/squid-auth.log"
docker logs --since "$started" testlab-maven > "$OUT/maven.log" 2>&1

echo "== $LABEL / $SOURCE / $SCENARIO"
grep -E '\[check\]|BUILD' "$OUT/run.txt" | sed 's/^.*\[script\] //' | cut -c1-220 || true
for log in squid squid-auth; do
	echo "$log lines: $(wc -l < "$OUT/$log.log")"
	# status/code, method, host (full URLs are in the log)
	awk '{ u = $7; sub( /^[a-z]+:\/\//, "", u ); sub( /[\/:].*$/, "", u ); print $4, $6, u }' "$OUT/$log.log" | sort | uniq -c
done
# client (squid container or the docker gateway for direct), status, cache status
echo "maven lines: $(grep -c '"GET' "$OUT/maven.log" || true)"
grep '"GET' "$OUT/maven.log" | awk '{ print $1, $(NF-1), $NF }' | sort | uniq -c || true
echo "cookie WARNs: $(grep -c 'Invalid cookie header' "$OUT/run.txt" || true)"
