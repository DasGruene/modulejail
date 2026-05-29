#!/bin/sh
# Case: --verbose-logging requires /usr/bin/logger (or whatever
# MODULEJAIL_LOGGER_PATH points to) to be executable. When logger is
# absent, modulejail MUST exit EX_NOINPUT=66 with a clear stderr message
# rather than silently falling back to the v1.1.4 /bin/true form (which
# has nothing to enrich).
set -eu

CASE_NAME=verbose-logging-requires-logger
export CASE_NAME

# shellcheck source=tests/lib/case-env.sh disable=SC1091
. "$(dirname "$0")/../lib/case-env.sh"
# shellcheck source=tests/lib/case-tree.sh disable=SC1091
. "$REPO_ROOT/tests/lib/case-tree.sh"
# shellcheck source=tests/lib/assert.sh disable=SC1091
. "$REPO_ROOT/tests/lib/assert.sh"

trap 'rm -rf "$CASE_TMP"' EXIT INT HUP TERM

OUT=$CASE_TMP/out.conf
set +e
MODULEJAIL_LOGGER_PATH=/nonexistent/logger-binary \
"$MODULEJAIL_BIN" --verbose-logging -o "$OUT" \
    > "$CASE_TMP/stdout" 2> "$CASE_TMP/stderr"
rc=$?
set -e

assert_eq 66 "$rc" EX_NOINPUT

# stderr MUST cite --verbose-logging and the missing logger path.
if ! grep -q "verbose-logging" "$CASE_TMP/stderr"; then
    case_fail "stderr did not mention --verbose-logging. stderr=$(cat "$CASE_TMP/stderr")"
fi
if ! grep -q "/nonexistent/logger-binary" "$CASE_TMP/stderr"; then
    case_fail "stderr did not cite the missing logger path. stderr=$(cat "$CASE_TMP/stderr")"
fi

# Output file MUST NOT exist.
if [ -e "$OUT" ]; then
    case_fail "output file written despite EX_NOINPUT"
fi

case_pass
