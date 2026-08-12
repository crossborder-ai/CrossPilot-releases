#!/usr/bin/env bash
# CrossPilot one-line remote installer.
#
#   curl -fsSL https://raw.githubusercontent.com/crossborder-ai/CrossPilot-releases/main/install.sh | bash
#
# Downloads the latest prebuilt distribution package (headless daemon bundle +
# renderer static assets — architecture-agnostic, no bundled Node runtime),
# extracts it, installs its production dependencies with the user's own
# bun/npm, and starts the daemon via the package's own setup.sh (which opens
# the browser at http://127.0.0.1:3456).
#
# Prerequisite: Node.js 22+ and bun (or npm) must already be installed on
# this machine — this installer does not manage the Node/bun environment
# itself (see README).
#
# This script is synced into the PUBLIC crossborder-ai/CrossPilot-releases
# repo by CI (see .github/workflows/dist.yml "Publish to public releases
# repo" step) so it can be curled without any GitHub auth. The canonical
# source lives here, in the private crossborder-ai/CrossPilot repo.
set -euo pipefail

PUBLIC_REPO="crossborder-ai/CrossPilot-releases"
ASSET="crosspilot-dist.tar.gz"
# Distinct from the dev-flow clone default ($HOME/CrossPilot in
# setup-crosspilot.sh) so this installer never collides with / wipes a git
# checkout the user made for development.
INSTALL_DIR="${CROSSPILOT_INSTALL_DIR:-$HOME/CrossPilot-app}"

if ! command -v node >/dev/null 2>&1; then
  echo "❌ 未找到 node。CrossPilot 需要先安装 Node.js 22+，安装完成后重新运行本脚本。" >&2
  exit 1
fi
if ! command -v bun >/dev/null 2>&1 && ! command -v npm >/dev/null 2>&1; then
  echo "❌ 未找到 bun 或 npm。CrossPilot 需要其中一个来安装依赖，请先安装后重试。" >&2
  exit 1
fi

URL="https://github.com/${PUBLIC_REPO}/releases/latest/download/${ASSET}"
echo "→ CrossPilot installer"
echo "→ downloading ${URL}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL "$URL" -o "$TMP_DIR/$ASSET"

if [ -d "$INSTALL_DIR" ]; then
  echo "→ removing previous install at ${INSTALL_DIR} (app data lives separately in ~/.crosspilot and is not touched)"
  rm -rf "$INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"

echo "→ installing to ${INSTALL_DIR}"
tar -xzf "$TMP_DIR/$ASSET" -C "$INSTALL_DIR" --strip-components=1

cd "$INSTALL_DIR"
chmod +x setup.sh

echo "→ starting CrossPilot…"
exec ./setup.sh
