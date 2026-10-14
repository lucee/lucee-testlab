#!/usr/bin/env bash
# ./summary.sh [dir]: markdown tables from the run.sh output, one per Lucee version and source
# rows are checks, columns are scenarios, plus the squid and mirror request counts
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIR="${1:-$(cd "$HERE/../.." && pwd)/test-output/http-proxy}"
SCENARIOS="none good auth wrongpass nocreds deadport badhost"

# tr: jq on Windows prints CRLF
cell() {
	# short enough for a table cell, no pipes or newlines
	jq -r --arg name "$2" '.[] | select( .name == $name )
		| ( if .ok then "ok " + ( .detail | tostring ) else "**fail** " + .error end )
		| gsub( "[|\n\r]"; " " ) | .[0:90]' "$1" | tr -d '\r'
}

count() {
	if [ -f "$1" ]; then grep -c "$2" "$1" || true; else echo "n/a"; fi
}

for label_dir in "$DIR"/*/; do
	label="$(basename "$label_dir")"
	for source_dir in "$label_dir"*/; do
		source="$(basename "$source_dir")"
		present=""
		for s in $SCENARIOS; do
			[ -f "$source_dir$s/results.json" ] && present="$present $s"
		done
		[ -n "$present" ] || continue

		echo "### $label / $source"
		echo
		printf "| Check |"; for s in $present; do printf " %s |" "$s"; done; echo
		printf "| --- |"; for s in $present; do printf " --- |"; done; echo

		# check names in run order, from the scenario with the most checks
		names_from="$(for s in $present; do echo "$(jq length "$source_dir$s/results.json" | tr -d '\r') $source_dir$s/results.json"; done | sort -rn | head -1 | cut -d' ' -f2-)"
		jq -r '.[].name' "$names_from" | tr -d '\r' | while read -r name; do
			printf "| %s |" "$name"
			for s in $present; do printf " %s |" "$(cell "$source_dir$s/results.json" "$name")"; done
			echo
		done

		for log in squid squid-auth; do
			printf "| %s lines |" "$log"
			for s in $present; do printf " %s |" "$(count "$source_dir$s/$log.log" '')"; done
			echo
		done
		printf "| mirror requests |"
		for s in $present; do printf " %s |" "$(count "$source_dir$s/maven.log" '"GET')"; done
		echo
		echo
	done
done
