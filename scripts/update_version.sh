#!/usr/bin/env bash
set -euo pipefail

NEXT_VERSION="${TAGPR_NEXT_VERSION:-${1:-}}"

if [ -z "$NEXT_VERSION" ]; then
  echo "Usage: $0 <version> (or set TAGPR_NEXT_VERSION)" >&2
  exit 1
fi

echo "Updating pubspec.yaml version to ${NEXT_VERSION}..."

# Update version in pubspec.yaml (e.g. version: 2.4.1 -> version: 2.4.2)
perl -i -pe "s/^version:\s*.*/version: ${NEXT_VERSION}/" pubspec.yaml

echo "Updated pubspec.yaml:"
grep '^version:' pubspec.yaml
