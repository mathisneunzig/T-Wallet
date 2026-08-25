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
erlc -o rest/ebin \
    rest/test/parse_json_tests.erl \
    rest/test/parse_cobol_output_tests.erl \
    rest/test/json_helpers_tests.erl \
    rest/test/shell_quote_tests.erl \
    rest/test/http_response_tests.erl \
    rest/test/integration_tests.erl
erl -noshell -pa rest/ebin \
    -eval "case eunit:test([parse_json_tests, parse_cobol_output_tests,
                            json_helpers_tests, shell_quote_tests,
                            http_response_tests, integration_tests],
                           [verbose]) of ok -> init:stop(0); _ -> init:stop(1) end" \
    || EXIT=1

echo ""
echo "=============================="
echo "   Running Python stats tests"
echo "=============================="
python3 -m pytest stats/test_visualize.py -v || EXIT=1

echo ""
if [ "$EXIT" -eq 0 ]; then
    echo "All test suites passed."
else
    echo "One or more test suites FAILED."
fi
exit "$EXIT"
