#!/bin/bash
# Usage: make-fixtures.sh
# Regenerates Fixtures/Inputs/{small,large,corrupt}.pdf and scanned-page.png (notes*.txt and
# empty.txt are hand-written). The generator is not named .swift because the UI test target
# would compile it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp "$HERE/make-fixtures.swiftscript" "$TMP/make-fixtures.swift"
swiftc -O "$TMP/make-fixtures.swift" -o "$TMP/make-fixtures"
"$TMP/make-fixtures" "$HERE/../Fixtures/Inputs"
