#!/bin/sh
# Case: --verbose-logging + --no-syslog-logging are mutually exclusive.
# Both orderings of the flags MUST exit EX_USAGE=64 with a clear stderr
# message.
set -eu

CASE_NAME=verbose-logging-mutex-no-syslog-logging
export CASE_NAME

# shellcheck source=tests/lib/case-env.sh disable=SC1091
. "$(dirname "$0")/../lib/case-env.sh"
# shellcheck source=tests/lib/case-tree.sh disable=SC1091
. "$REPO_ROOT/tests/lib/case-tree.sh"
# shellcheck source=tests/lib/assert.sh disable=SC1091
. "$REPO_ROOT/tests/lib/assert.sh"

trap 'rm -rf "$CASE_TMP"' EXIT INT HUP TERM

# Both orderings must error with EX_USAGE=64.
for args in \
    "--verbose-logging --no-syslog-logging" \
    "--no-syslog-logging --verbose-logging"
do
    OUT=$CASE_TMP/out.conf
    set +e
    # shellcheck disable=SC2086  # we want the args unquoted for splitting
    "$MODULEJAIL_BIN" $args -o "$OUT" > "$CASE_TMP/stdout" 2> "$CASE_TMP/stderr"
    rc=$?
    set -e
    assert_eq 64 "$rc" "EX_USAGE for: $args"

    # stderr MUST contain a "mutually exclusive" message naming the two flags.
    if ! grep -q "mutually exclusive" "$CASE_TMP/stderr"; then
        case_fail "stderr did not mention 'mutually exclusive' for: $args. stderr=$(cat "$CASE_TMP/stderr")"
    fi

    # The output file MUST NOT have been written.
    if [ -e "$OUT" ]; then
        case_fail "output file written despite EX_USAGE for: $args"
    fi
done

case_pass
