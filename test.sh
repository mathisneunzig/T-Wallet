#!/usr/bin/env bash
# Run all T-Wallet tests.
# Must be run from the project root after a successful build.sh.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

EXIT=0

echo "=============================="
echo "   Running action tests"
echo "=============================="
bash tests/run_tests.sh || EXIT=1

echo ""
echo "=============================="
echo "   Running Erlang EUnit tests"
echo "=============================="
erlc -o rest/ebin rest/src/twallet_server.erl
erlc -o rest/ebin rest/test/twallet_server_tests.erl
erl -noshell -pa rest/ebin \
    -eval "case eunit:test(twallet_server_tests, [verbose]) of ok -> init:stop(0); _ -> init:stop(1) end" \
    || EXIT=1

echo ""
if [ "$EXIT" -eq 0 ]; then
    echo "All test suites passed."
else
    echo "One or more test suites FAILED."
fi
exit "$EXIT"
