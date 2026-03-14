#!/usr/bin/env bash
# Functional tests for the cblaster container image.
# Usage: ./test.sh <image> <expected_version>
#
# Exit codes:
#   0 – all tests passed
#   1 – one or more tests failed
set -euo pipefail

IMAGE="${1:?Usage: $0 <image> <expected_version>}"
EXPECTED_VERSION="${2:?Usage: $0 <image> <expected_version>}"

PASS=0
FAIL=0

pass() { ((++PASS)); echo "  ✅  $1"; }
fail() { ((++FAIL)); echo "  ❌  $1"; }

echo "── Testing ${IMAGE} (expected v${EXPECTED_VERSION}) ──"

# -------------------------------------------------------------------
# 1. Help flag exits cleanly
# -------------------------------------------------------------------
echo ""
echo "1) Help flag"
if docker run --rm "${IMAGE}" --help >/dev/null 2>&1; then
  pass "Exit code 0 with --help"
else
  fail "Non-zero exit code with --help"
fi

# -------------------------------------------------------------------
# 2. Help output mentions cblaster
# -------------------------------------------------------------------
echo ""
echo "2) Help output sanity"
if OUTPUT=$(docker run --rm "${IMAGE}" --help 2>&1) && \
   echo "${OUTPUT}" | grep -qiE "cblaster"; then
  pass "Help output mentions cblaster"
else
  fail "Help output missing cblaster reference (output: ${OUTPUT:0:200})"
fi

# -------------------------------------------------------------------
# 3. Version check
#    cblaster --version or cblaster -V prints the version string.
# -------------------------------------------------------------------
echo ""
echo "3) Version check"
if OUTPUT=$(docker run --rm "${IMAGE}" --version 2>&1) && \
   echo "${OUTPUT}" | grep -qF "${EXPECTED_VERSION}"; then
  pass "Version string contains ${EXPECTED_VERSION}"
else
  fail "Version string missing (output: ${OUTPUT:0:200})"
fi

# -------------------------------------------------------------------
# 4. Python runtime works
# -------------------------------------------------------------------
echo ""
echo "4) Python runtime sanity"
if OUTPUT=$(docker run --rm --entrypoint python "${IMAGE}" -c 'print("ok")' 2>&1) && \
   echo "${OUTPUT}" | grep -q "ok"; then
  pass "Python executes successfully"
else
  fail "Python failed (output: ${OUTPUT:0:300})"
fi

# -------------------------------------------------------------------
# 5. cblaster module is importable
# -------------------------------------------------------------------
echo ""
echo "5) cblaster Python module import"
if OUTPUT=$(docker run --rm --entrypoint python "${IMAGE}" -c 'import cblaster; print("ok")' 2>&1) && \
   echo "${OUTPUT}" | grep -q "ok"; then
  pass "cblaster module imports successfully"
else
  fail "cblaster module import failed (output: ${OUTPUT:0:300})"
fi

# -------------------------------------------------------------------
# 6. cagecleaner is installed and callable
# -------------------------------------------------------------------
echo ""
echo "6) cagecleaner availability"
if OUTPUT=$(docker run --rm --entrypoint cagecleaner "${IMAGE}" --help 2>&1) && \
   echo "${OUTPUT}" | grep -qiE "cagecleaner|usage"; then
  pass "cagecleaner is installed and shows help"
else
  fail "cagecleaner not available or broken (output: ${OUTPUT:0:300})"
fi

# -------------------------------------------------------------------
# 7. Subcommands are accessible (spot-check 'search' help)
# -------------------------------------------------------------------
echo ""
echo "7) Subcommand: search --help"
if OUTPUT=$(docker run --rm "${IMAGE}" search --help 2>&1) && \
   echo "${OUTPUT}" | grep -qiE "search|query"; then
  pass "search subcommand help works"
else
  fail "search subcommand help failed (output: ${OUTPUT:0:300})"
fi

# -------------------------------------------------------------------
# Summary
# -------------------------------------------------------------------
echo ""
echo "── Results: ${PASS} passed, ${FAIL} failed ──"
[[ ${FAIL} -eq 0 ]]
