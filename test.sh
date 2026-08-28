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
bash src/wallet/test/run_tests.sh || EXIT=1

echo ""
echo "=============================="
echo "   Running Erlang EUnit tests"
echo "=============================="
erlc -o src/rest/ebin src/rest/twallet_server.erl
erlc -o src/rest/ebin \
    src/rest/test/parse_json_tests.erl \
    src/rest/test/parse_cobol_output_tests.erl \
    src/rest/test/json_helpers_tests.erl \
    src/rest/test/shell_quote_tests.erl \
    src/rest/test/http_response_tests.erl \
    src/rest/test/integration_tests.erl \
    src/rest/test/qr_tests.erl
erl -noshell -pa src/rest/ebin \
    -eval "case eunit:test([parse_json_tests, parse_cobol_output_tests,
                            json_helpers_tests, shell_quote_tests,
                            http_response_tests, integration_tests,
                            qr_tests],
                           [verbose]) of ok -> init:stop(0); _ -> init:stop(1) end" \
    || EXIT=1

echo ""
echo "=============================="
echo "   Running Python stats tests"
echo "=============================="
python3 -m pytest src/stats/test/test_visualize.py -v || EXIT=1

echo ""
if [ "$EXIT" -eq 0 ]; then
    echo "All test suites passed."
else
    echo "One or more test suites FAILED."
fi
exit "$EXIT"
