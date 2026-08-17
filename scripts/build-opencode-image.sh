#!/usr/bin/env bash
set -euo pipefail

# build-opencode-image.sh — build/tag/push the opencode-flow Docker image.
#
# Produces:
#   ghcr.io/pereirawe/opencode-flow:latest
#   ghcr.io/pereirawe/opencode-flow:v<semver>   (from VERSION file)
#
# Idempotent (AC 2): docker build layers are cached; re-running produces the
# same tags and the version check guarantees opencode --version matches the
# pinned binary (AC 17 — no drift).
#
# Usage:
#   ./scripts/build-opencode-image.sh                    # build + tag (no push)
#   ./scripts/build-opencode-image.sh --push             # build + tag + push
#   ./scripts/build-opencode-image.sh --version 1.18.7   # pin opencode binary
#   ./scripts/build-opencode-image.sh --registry ghcr.io/user/repo
#
# Env overrides:
#   OPENCODE_VERSION   pin the opencode binary version (default: 1.18.7)
#   REGISTRY           image registry/repo (default: ghcr.io/pereirawe/opencode-flow)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

REGISTRY="${REGISTRY:-ghcr.io/pereirawe/opencode-flow}"
OPENCODE_VERSION="${OPENCODE_VERSION:-1.18.7}"
PUSH=false

usage() {
  sed -n '2,30p' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --push) PUSH=true; shift ;;
    --version) OPENCODE_VERSION="${2:?--version requires a value}"; shift 2 ;;
    --registry) REGISTRY="${2:?--registry requires a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker not found in PATH" >&2
  exit 1
fi

VERSION="$(cat "$CONFIG_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
if [[ -z "$VERSION" ]]; then
  echo "error: cannot read VERSION from $CONFIG_DIR/VERSION" >&2
  exit 1
fi
# Accept VERSION with or without leading v
SEMVER_TAG="v${VERSION#v}"
LATEST_TAG="$REGISTRY:latest"
VERSION_TAG="$REGISTRY:$SEMVER_TAG"

log() { printf '[build-image] %s\n' "$*"; }

log "opencode binary: $OPENCODE_VERSION"
log "tags: $LATEST_TAG | $VERSION_TAG"
log "build context: $CONFIG_DIR"

# Build with the pinned opencode version as build-arg (AC 17 — no drift).
# --build-arg OPENCODE_VERSION also makes the layer cache key deterministic.
docker build \
  --build-arg "OPENCODE_VERSION=$OPENCODE_VERSION" \
  -t "$LATEST_TAG" \
  -t "$VERSION_TAG" \
  "$CONFIG_DIR"

# Smoke test inside the built image: opencode --version must equal the pin.
ACTUAL="$(docker run --rm --entrypoint opencode "$LATEST_TAG" --version 2>/dev/null || true)"
if [[ "$ACTUAL" != "$OPENCODE_VERSION" ]]; then
  echo "error: opencode in image responded '$ACTUAL', expected '$OPENCODE_VERSION'" >&2
  exit 1
fi
log "smoke test OK: opencode --version = $ACTUAL"

if [[ "$PUSH" == true ]]; then
  log "push: $LATEST_TAG"
  docker push "$LATEST_TAG"
  log "push: $VERSION_TAG"
  docker push "$VERSION_TAG"
  log "publicado: $LATEST_TAG e $VERSION_TAG"
else
  log "build complete (no push). Use --push to publish to registry."
fi
