#!/usr/bin/env bash
# Functional tests for the trnascan-se container image.
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
# 1. Version check (extracted from -h output)
# -------------------------------------------------------------------
echo ""
echo "1) Version check"
if OUTPUT=$(docker run --rm --entrypoint tRNAscan-SE "${IMAGE}" -h 2>&1) && \
   echo "${OUTPUT}" | grep -qiE "tRNAscan-SE ${EXPECTED_VERSION}"; then
  pass "Version string contains ${EXPECTED_VERSION}"
else
  fail "Version string missing (output: ${OUTPUT:0:200})"
fi

# -------------------------------------------------------------------
# 2. Help flag exits cleanly
# -------------------------------------------------------------------
echo ""
echo "2) Help flag"
if docker run --rm --entrypoint tRNAscan-SE "${IMAGE}" -h >/dev/null 2>&1; then
  pass "Exit code 0 with -h"
else
  fail "Non-zero exit code with -h"
fi

# -------------------------------------------------------------------
# 3. Perl runtime works (libcrypt.so.1 regression check)
# -------------------------------------------------------------------
echo ""
echo "3) Perl runtime sanity"
if OUTPUT=$(docker run --rm --entrypoint perl "${IMAGE}" -e 'print "ok\n"' 2>&1) && \
   echo "${OUTPUT}" | grep -q "ok"; then
  pass "Perl executes successfully"
else
  fail "Perl failed (output: ${OUTPUT:0:300})"
fi

# -------------------------------------------------------------------
# 4. Functional: scan a minimal FASTA for tRNAs
#    E. coli tRNA-fMet (well-characterised, should always be found).
# -------------------------------------------------------------------
echo ""
echo "4) Functional: detect tRNA in sample FASTA"
FASTA=">ecoli_tRNA_fMet
CGCGGGGTGGAGCAGCCTGGTAGCTCGTCGGGCTCATAACCCGAAGGTCG
TCGGTTCAAATCCGGCCCCCGCAACCA"

TMPDIR=$(mktemp -d)
echo "${FASTA}" > "${TMPDIR}/sample.fa"
chmod 755 "${TMPDIR}"
chmod 644 "${TMPDIR}/sample.fa"

if OUTPUT=$(docker run --rm -v "${TMPDIR}:/data" "${IMAGE}" /data/sample.fa 2>&1) && \
   echo "${OUTPUT}" | grep -qiE "Met|CAT|tRNA"; then
  pass "tRNA detected in sample sequence"
else
  fail "No tRNA detected (output: ${OUTPUT:0:300})"
fi

rm -rf "${TMPDIR}"

# -------------------------------------------------------------------
# 5. Shared libraries resolve at runtime
# -------------------------------------------------------------------
echo ""
echo "5) Runtime library check"
if OUTPUT=$(docker run --rm --entrypoint perl "${IMAGE}" -e 'use POSIX; print "ok\n"' 2>&1) && \
   echo "${OUTPUT}" | grep -q "ok"; then
  pass "Perl loads POSIX module (shared libs OK)"
else
  fail "Perl POSIX module failed (output: ${OUTPUT:0:300})"
fi

# -------------------------------------------------------------------
# Summary
# -------------------------------------------------------------------
echo ""
echo "── Results: ${PASS} passed, ${FAIL} failed ──"
[[ ${FAIL} -eq 0 ]]
