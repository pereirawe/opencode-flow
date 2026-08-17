# syntax=docker/dockerfile:1
# opencode-flow — pre-built opencode config image (issue #40)
#
# Contains the opencode binary (pinned version, no drift — AC 17) plus the full
# ~/.config/opencode/ config: agents, skills, commands, scripts, standards,
# deny rules (opencode.json permission block) and aibot-repos.json allowlist.
#
# Used by the CI-native aibot entry point (.github/workflows/aibot-develop.yml):
# the workflow mounts the target repo at /workspace and runs the pipeline
# headless with `opencode run --command "ocf:develop" <id> --auto` (BR 13 —
# headless SPIKE passed on opencode 1.18.7: no `--attach`/web server needed).
#
# Build with scripts/build-opencode-image.sh (tags: latest + v<semver>).

ARG OPENCODE_VERSION=1.18.7
ARG GH_VERSION=2.63.2
ARG GLAB_VERSION=1.51.0

FROM debian:bookworm-slim

ARG OPENCODE_VERSION
ARG GH_VERSION
ARG GLAB_VERSION
ARG TARGETARCH=amd64

# --- OS deps: git (pipeline), jq (scripts), curl (install + health), bash ---
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq bash \
 && rm -rf /var/lib/apt/lists/*

# --- opencode binary (pinned, no drift — AC 17) ---
# Official release asset name: opencode-linux-{x64,arm64}.tar.gz (single binary
# named `opencode` at the archive root, same layout as the official installer).
RUN case "$TARGETARCH" in \
      amd64) OC_ARCH=x64 ;; \
      arm64) OC_ARCH=arm64 ;; \
      *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${OC_ARCH}.tar.gz" \
      -o /tmp/opencode.tar.gz \
 && tar -xzf /tmp/opencode.tar.gz -C /usr/local/bin \
 && rm /tmp/opencode.tar.gz \
 && chmod 755 /usr/local/bin/opencode \
 && test "$(opencode --version)" = "$OPENCODE_VERSION" \
 && opencode --version

# --- GitHub CLI (gh) — pinned, for issue/MR operations ---
RUN case "$TARGETARCH" in \
      amd64) GH_ARCH=amd64 ;; \
      arm64) GH_ARCH=arm64 ;; \
      *) exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz" \
      -o /tmp/gh.tar.gz \
 && tar -xzf /tmp/gh.tar.gz -C /tmp \
 && cp /tmp/gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh /usr/local/bin/gh \
 && chmod 755 /usr/local/bin/gh \
 && rm -rf /tmp/gh.tar.gz /tmp/gh_${GH_VERSION}_linux_${GH_ARCH} \
 && gh --version | head -1

# --- GitLab CLI (glab) — pinned, for GitLab provider (AC 15 matrix) ---
RUN case "$TARGETARCH" in \
      amd64) GLAB_ARCH=amd64 ;; \
      arm64) GLAB_ARCH=arm64 ;; \
      *) exit 1 ;; \
    esac \
 && curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_${GLAB_ARCH}.tar.gz" \
      -o /tmp/glab.tar.gz \
 && tar -xzf /tmp/glab.tar.gz -C /tmp \
 && cp /tmp/glab_${GLAB_VERSION}_linux_${GLAB_ARCH}/bin/glab /usr/local/bin/glab \
 && chmod 755 /usr/local/bin/glab \
 && rm -rf /tmp/glab.tar.gz /tmp/glab_${GLAB_VERSION}_linux_${GLAB_ARCH} \
 && glab --version

# --- copy the opencode config (agents, skills, commands, scripts, standards,
# --- opencode.json deny rules, aibot-repos.json) into the image ---
COPY . /root/.config/opencode/

# Git identity for pipeline commits inside the container (overridable by the
# workflow via git config in the mounted workspace — safe defaults here).
RUN git config --global user.name "opencode-flow[bot]" \
 && git config --global user.email "opencode-flow[bot]@users.noreply.github.com"

WORKDIR /workspace

# Healthcheck / smoke test: opencode must answer --version (AC 1/AC 17).
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD opencode --version >/dev/null 2>&1 || exit 1

ENTRYPOINT ["opencode"]
CMD ["--version"]
