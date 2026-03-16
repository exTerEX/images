#!/usr/bin/env bash
# Tests for the rgi container image.
# Usage: ./test.sh <image> <expected_version>
set -euo pipefail

IMAGE="${1:?Usage: $0 <image> <expected_version>}"
EXPECTED_VERSION="${2:?Usage: $0 <image> <expected_version>}"

PASS=0
FAIL=0

pass() { ((++PASS)); echo "  ✅  $1"; }
fail() { ((++FAIL)); echo "  ❌  $1"; }

echo "── Testing ${IMAGE} (expected v${EXPECTED_VERSION}) ──"

# 1. Help flag exits cleanly
echo ""
echo "1) Help flag"
if docker run --rm "${IMAGE}" --help >/dev/null 2>&1; then
  pass "Exit code 0 with --help"
else
  fail "Non-zero exit code with --help"
fi

# 2. Version check
echo ""
echo "2) Version check"
if OUTPUT=$(docker run --rm "${IMAGE}" --version 2>&1) && \
   echo "${OUTPUT}" | grep -qF "${EXPECTED_VERSION}"; then
  pass "Version string contains ${EXPECTED_VERSION}"
else
  fail "Version string missing (output: ${OUTPUT:0:200})"
fi

# 3. Help output mentions rgi
echo ""
echo "3) Help output sanity"
if OUTPUT=$(docker run --rm "${IMAGE}" --help 2>&1) && \
   echo "${OUTPUT}" | grep -qiE "rgi|resistance gene identifier"; then
  pass "Help output mentions rgi"
else
  fail "Help output missing rgi reference (output: ${OUTPUT:0:200})"
fi

# Summary
echo ""
echo "── Results: ${PASS} passed, ${FAIL} failed ──"
[[ ${FAIL} -eq 0 ]]
