#!/usr/bin/env bash
# ./summary.sh [dir]: markdown verdicts from the run.sh output, one section per Lucee version
# exits 1 when any check misbehaved, so CI goes red
#
# a check is right when:
#   none                                   it works
#   good, auth                             it works, through the proxy
#   wrongpass, nocreds, deadport, badhost  it fails (working means it bypassed the proxy)
#
# through the proxy: cfhttp from the X-Testlab-Proxy header httpbin echoes back, downloads from
# their artifact in the squid logs (non-407 lines)
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIR="${1:-$(cd "$HERE/../.." && pwd)/test-output/http-proxy}"
SCENARIOS="none good auth wrongpass nocreds deadport badhost"
SOURCES="cfconfig baseconfig context env env-vs-cfconfig app"
# the checks with a verdict, the rest are diagnostics
CHECKS=( "extension from config" "mavenLoad pinned" "mavenLoad latest" "cfhttp http, no proxy attrs" "cfhttp http, proxyServer attr" )
SHORT=( "extension" "mavenLoad" "mavenLoad latest" "cfhttp" "cfhttp attrs" )
# squid log patterns for the downloads: the 8.0 Maven artifact, or the extension provider before 8.0
PATTERNS=( "ajax-extension|extension\.lucee\.org" "commons-text" "commons-csv" "" "" )

field() {
	# tr: jq on Windows prints CRLF
	jq -r --arg name "$2" --arg f "$3" '.[] | select( .name == $name ) | .[ $f ] | select( . != null )' "$1" | tr -d '\r'
}

proxied() {
	local run="$1" i="$2"
	if [ -n "${PATTERNS[$i]}" ]; then
		cat "$run/squid.log" "$run/squid-auth.log" 2>/dev/null | grep -v TCP_DENIED | grep -qE "${PATTERNS[$i]}"
	else
		[[ "$(field "$run/results.json" "${CHECKS[$i]}" detail)" == via* ]]
	fi
}

# prints the cell, returns 1 when wrong
verdict() {
	local run="$1" scenario="$2" i="$3"
	local ok
	ok="$(field "$run/results.json" "${CHECKS[$i]}" ok)"
	# not run: unsupported on this version, or no proxy attrs to pass
	[ -n "$ok" ] || { echo "➖"; return 0; }
	case "$scenario" in
		none)
			[ "$ok" = true ] && { echo "✅"; return 0; }
			echo "❌ fail"; return 1 ;;
		good|auth)
			[ "$ok" = true ] || { echo "❌ fail"; return 1; }
			proxied "$run" "$i" && { echo "✅"; return 0; }
			echo "❌ bypass"; return 1 ;;
		*)
			[ "$ok" = true ] || { echo "✅"; return 0; }
			echo "❌ bypass"; return 1 ;;
	esac
}

failed=0
for label_dir in "$DIR"/*/; do
	label="$(basename "$label_dir")"
	bad=0
	table=""

	# scenarios, all through .CFConfig.json
	present=""
	for s in $SCENARIOS; do
		[ -f "${label_dir}cfconfig/$s/results.json" ] && present="$present $s"
	done
	# checks this version ran, a check it never runs (mavenLoad latest before 8.0) gets no row or column
	active=()
	if [ -n "$present" ]; then
		table+="| |"; for s in $present; do table+=" $s |"; done; table+=$'\n'
		table+="| --- |"; for s in $present; do table+=" --- |"; done; table+=$'\n'
		for i in "${!CHECKS[@]}"; do
			row="| ${SHORT[$i]} |"
			ran=""
			for s in $present; do
				cell="$(verdict "${label_dir}cfconfig/$s" "$s" "$i")" || bad=$(( bad + 1 ))
				[ "$cell" = "➖" ] || ran=1
				row+=" $cell |"
			done
			[ -n "$ran" ] && { table+="$row"$'\n'; active+=( "$i" ); }
		done
	fi

	# config sources, all with the good proxy
	sources=""
	notes=""
	for src in $SOURCES; do
		if [ -f "${label_dir}$src/good/results.json" ]; then
			sources="$sources $src"
		elif [ -f "${label_dir}$src/good/unsupported.txt" ]; then
			sources="$sources $src"
			notes+="➖ $src: $(tr -d '\r' < "${label_dir}$src/good/unsupported.txt")"$'\n\n'
		fi
	done
	stable=""
	# cfconfig is only there to compare against
	if [ "$sources" != " cfconfig" ] && [ -n "$sources" ]; then
		stable+="| good proxy via |"; for i in "${active[@]}"; do stable+=" ${SHORT[$i]} |"; done; stable+=$'\n'
		stable+="| --- |"; for i in "${active[@]}"; do stable+=" --- |"; done; stable+=$'\n'
		[[ " $sources " == *" app "* ]] && notes+="➖ app: extension installs are server level, at startup with no application, so \`this.proxy\` doesn't apply"$'\n\n'
		for src in $sources; do
			stable+="| $src |"
			for i in "${active[@]}"; do
				if [ -f "${label_dir}$src/good/unsupported.txt" ]; then
					cell="➖"
				elif [ "$src" = app ] && [ "${CHECKS[$i]}" = "extension from config" ]; then
					cell="➖"
				else
					cell="$(verdict "${label_dir}$src/good" good "$i")" || { [ "$src" = cfconfig ] || bad=$(( bad + 1 )); }
				fi
				stable+=" $cell |"
			done
			stable+=$'\n'
		done
		stable+=$'\n'"$notes"
	fi

	# errors and diagnostics, collapsed
	details=""
	for src in $sources; do
		for s in $SCENARIOS; do
			res="${label_dir}$src/$s/results.json"
			[ -f "$res" ] || continue
			[ "$src" = cfconfig ] || [ "$s" = good ] || continue
			details+="**$src / $s**"$'\n\n'
			details+="$(jq -r '.[] | "- \( .name ): " + ( if .ok then ( .detail | tostring ) else "**" + .error + "**" end | gsub( "[\n\r]"; " " ) | .[0:300] )' "$res" | tr -d '\r')"$'\n'
			details+="- squid: $(grep -vc TCP_DENIED "${label_dir}$src/$s/squid.log" 2>/dev/null || true), squid-auth: $(grep -vc TCP_DENIED "${label_dir}$src/$s/squid-auth.log" 2>/dev/null || true) (+ $(grep -c TCP_DENIED "${label_dir}$src/$s/squid-auth.log" 2>/dev/null || true) denied), mirror: $(grep -c '"GET' "${label_dir}$src/$s/maven.log" 2>/dev/null || true)"$'\n\n'
		done
	done

	if [ "$bad" -gt 0 ]; then echo "## $label ❌ $bad"; failed=1; else echo "## $label ✅"; fi
	echo
	echo "$table"
	[ -n "$stable" ] && { echo "$stable"; }
	echo "<details><summary>errors and diagnostics</summary>"
	echo
	echo "$details"
	echo "</details>"
	echo
done

echo "✅ worked as expected: direct with no proxy, through a working proxy, failing with a broken one. ❌ fail: failed with no proxy or a working one. ❌ bypass: didn't use the proxy. ➖ not run."
exit $failed
