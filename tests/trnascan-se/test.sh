#!/usr/bin/env bash
# Tests for the trnascan-se container image.
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
if docker run --rm --entrypoint tRNAscan-SE "${IMAGE}" -h >/dev/null 2>&1; then
  pass "Exit code 0 with -h"
else
  fail "Non-zero exit code with -h"
fi

# 2. Version check
#    Some releases omit the patch digit (e.g. "2.0" instead of "2.0.0"),
#    so we also accept the major.minor prefix when patch is 0.
echo ""
echo "2) Version check"
if OUTPUT=$(docker run --rm --entrypoint tRNAscan-SE "${IMAGE}" -h 2>&1) && \
   echo "${OUTPUT}" | grep -qiE "tRNAscan-SE ${EXPECTED_VERSION}( |$)"; then
  pass "Version string contains ${EXPECTED_VERSION}"
elif TRIMMED="${EXPECTED_VERSION%.0}" && [[ "$TRIMMED" != "$EXPECTED_VERSION" ]] && \
   echo "${OUTPUT}" | grep -qiE "tRNAscan-SE ${TRIMMED}( |$)"; then
  pass "Version string contains ${TRIMMED} (trailing .0 omitted by program)"
else
  fail "Version string missing (output: ${OUTPUT:0:200})"
fi

# 3. Perl runtime works (libcrypt regression check)
echo ""
echo "3) Perl runtime sanity"
if OUTPUT=$(docker run --rm --entrypoint perl "${IMAGE}" -e 'print "ok\n"' 2>&1) && \
   echo "${OUTPUT}" | grep -q "ok"; then
  pass "Perl executes successfully"
else
  fail "Perl failed (output: ${OUTPUT:0:300})"
fi

# 4. Functional: scan a minimal FASTA for tRNAs
#    E. coli tRNA-fMet (well-characterised, should always be found).
echo ""
echo "4) Functional: detect tRNA in sample FASTA"
FASTA=">ecoli_tRNA_fMet
CGCGGGGTGGAGCAGCCTGGTAGCTCGTCGGGCTCATAACCCGAAGGTCG
TCGGTTCAAATCCGGCCCCCGCAACCA"

TMPDIR_HOST=$(mktemp -d)
echo "${FASTA}" > "${TMPDIR_HOST}/sample.fa"
chmod 755 "${TMPDIR_HOST}"
chmod 644 "${TMPDIR_HOST}/sample.fa"

if OUTPUT=$(docker run --rm -v "${TMPDIR_HOST}:/data" "${IMAGE}" /data/sample.fa 2>&1) && \
   echo "${OUTPUT}" | grep -qiE "Met|CAT|tRNA"; then
  pass "tRNA detected in sample sequence"
else
  fail "No tRNA detected (output: ${OUTPUT:0:300})"
fi

rm -rf "${TMPDIR_HOST}"

# 5. Runtime library check (shared libs load correctly)
echo ""
echo "5) Runtime library check"
if OUTPUT=$(docker run --rm --entrypoint perl "${IMAGE}" -e 'use POSIX; print "ok\n"' 2>&1) && \
   echo "${OUTPUT}" | grep -q "ok"; then
  pass "Perl loads POSIX module (shared libs OK)"
else
  fail "Perl POSIX module failed (output: ${OUTPUT:0:300})"
fi

# 6. Read-only filesystem (Apptainer/Singularity compatibility)
echo ""
echo "6) Read-only filesystem with /tscan_tmp"
TMPDIR_HOST=$(mktemp -d)
echo "${FASTA}" > "${TMPDIR_HOST}/sample.fa"
chmod 755 "${TMPDIR_HOST}"
chmod 644 "${TMPDIR_HOST}/sample.fa"

if OUTPUT=$(docker run --rm --read-only --tmpfs /tscan_tmp -v "${TMPDIR_HOST}:/data" "${IMAGE}" -B /data/sample.fa 2>&1) && \
   ! echo "${OUTPUT}" | grep -qi "error"; then
  pass "Runs on read-only filesystem"
else
  fail "Failed on read-only filesystem (output: ${OUTPUT:0:300})"
fi

rm -rf "${TMPDIR_HOST}"

# Summary
echo ""
echo "── Results: ${PASS} passed, ${FAIL} failed ──"
[[ ${FAIL} -eq 0 ]]
