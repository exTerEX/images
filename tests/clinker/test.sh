#!/usr/bin/env bash
# Functional tests for the clinker (clinker-py) container image.
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
# 2. Help output mentions clinker
# -------------------------------------------------------------------
echo ""
echo "2) Help output sanity"
if OUTPUT=$(docker run --rm "${IMAGE}" --help 2>&1) && \
   echo "${OUTPUT}" | grep -qiE "clinker"; then
  pass "Help output mentions clinker"
else
  fail "Help output missing clinker reference (output: ${OUTPUT:0:200})"
fi

# -------------------------------------------------------------------
# 3. Python runtime works
# -------------------------------------------------------------------
echo ""
echo "3) Python runtime sanity"
if OUTPUT=$(docker run --rm --entrypoint python "${IMAGE}" -c 'print("ok")' 2>&1) && \
   echo "${OUTPUT}" | grep -q "ok"; then
  pass "Python executes successfully"
else
  fail "Python failed (output: ${OUTPUT:0:300})"
fi

# -------------------------------------------------------------------
# 4. clinker module is importable
# -------------------------------------------------------------------
echo ""
echo "4) clinker Python module import"
if OUTPUT=$(docker run --rm --entrypoint python "${IMAGE}" -c 'import clinker; print("ok")' 2>&1) && \
   echo "${OUTPUT}" | grep -q "ok"; then
  pass "clinker module imports successfully"
else
  fail "clinker module import failed (output: ${OUTPUT:0:300})"
fi

# -------------------------------------------------------------------
# 5. Functional: run clinker on a minimal GenBank file
#    Create a tiny synthetic GenBank record with one CDS and verify
#    clinker can parse it without errors.
# -------------------------------------------------------------------
echo ""
echo "5) Functional: parse a minimal GenBank file"
TMPDIR=$(mktemp -d)
cat > "${TMPDIR}/test1.gbk" <<'GBK'
LOCUS       SEQ1                     300 bp    DNA     linear   UNK
DEFINITION  Test sequence 1.
ACCESSION   SEQ1
VERSION     SEQ1.1
FEATURES             Location/Qualifiers
     CDS             1..300
                     /gene="geneA"
                     /locus_tag="SEQ1_001"
                     /product="hypothetical protein"
                     /translation="MKTLFAILAAVALSTQALA"
ORIGIN
        1 atgaaaacac tatttgcaat tcttgcagca gttgcactgt ctactcaagc attagcaatg
       61 aaaacactat ttgcaattct tgcagcagtt gcactgtcta ctcaagcatt agcaatgaaa
      121 acactatttg caattcttgc agcagttgca ctgtctactc aagcattagc aatgaaaaca
      181 ctatttgcaa ttcttgcagc agttgcactg tctactcaag cattagcaat gaaaacacta
      241 tttgcaattc ttgcagcagt tgcactgtct actcaagcat tagcaatgaa aacattatga
//
GBK

cat > "${TMPDIR}/test2.gbk" <<'GBK'
LOCUS       SEQ2                     300 bp    DNA     linear   UNK
DEFINITION  Test sequence 2.
ACCESSION   SEQ2
VERSION     SEQ2.1
FEATURES             Location/Qualifiers
     CDS             1..300
                     /gene="geneB"
                     /locus_tag="SEQ2_001"
                     /product="hypothetical protein"
                     /translation="MKTLFAILAAVALSTQALA"
ORIGIN
        1 atgaaaacac tatttgcaat tcttgcagca gttgcactgt ctactcaagc attagcaatg
       61 aaaacactat ttgcaattct tgcagcagtt gcactgtcta ctcaagcatt agcaatgaaa
      121 acactatttg caattcttgc agcagttgca ctgtctactc aagcattagc aatgaaaaca
      181 ctatttgcaa ttcttgcagc agttgcactg tctactcaag cattagcaat gaaaacacta
      241 tttgcaattc ttgcagcagt tgcactgtct actcaagcat tagcaatgaa aacattatga
//
GBK

chmod 755 "${TMPDIR}"
chmod 644 "${TMPDIR}"/*.gbk

if OUTPUT=$(docker run --rm -v "${TMPDIR}:/data" "${IMAGE}" \
    /data/test1.gbk /data/test2.gbk 2>&1); then
  pass "clinker ran successfully on GenBank files"
else
  fail "clinker failed on GenBank files (exit $?, output: ${OUTPUT:0:300})"
fi

rm -rf "${TMPDIR}"

# -------------------------------------------------------------------
# Summary
# -------------------------------------------------------------------
echo ""
echo "── Results: ${PASS} passed, ${FAIL} failed ──"
[[ ${FAIL} -eq 0 ]]
