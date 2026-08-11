#!/usr/bin/env bash
# CrossPilot one-line remote installer.
#
#   curl -fsSL https://raw.githubusercontent.com/crossborder-ai/CrossPilot-releases/main/install.sh | bash
#
# Downloads the latest self-contained pure-Node distribution package (bundles
# its own Node runtime — no local Node/Bun install required), extracts it,
# and starts the daemon via the package's own setup.sh (which opens the
# browser at http://127.0.0.1:3456).
#
# This script is synced into the PUBLIC crossborder-ai/CrossPilot-releases
# repo by CI (see .github/workflows/dist.yml "Publish to public releases
# repo" step) so it can be curled without any GitHub auth. The canonical
# source lives here, in the private crossborder-ai/CrossPilot repo.
set -euo pipefail

PUBLIC_REPO="crossborder-ai/CrossPilot-releases"
ASSET="crosspilot-dist-mac-arm64.tar.gz"
# Distinct from the dev-flow clone default ($HOME/CrossPilot in
# setup-crosspilot.sh) so this installer never collides with / wipes a git
# checkout the user made for development.
INSTALL_DIR="${CROSSPILOT_INSTALL_DIR:-$HOME/CrossPilot-app}"

if [ "$(uname -s)" != "Darwin" ] || [ "$(uname -m)" != "arm64" ]; then
  echo "❌ This installer currently only supports macOS on Apple Silicon (arm64)." >&2
  echo "   Detected: $(uname -s) $(uname -m)" >&2
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
chmod +x setup.sh bin/node

echo "→ starting CrossPilot…"
exec ./setup.sh
