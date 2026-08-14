#!/usr/bin/env bash
# CrossPilot one-line remote installer.
#
#   curl -fsSL https://raw.githubusercontent.com/crossborder-ai/CrossPilot-releases/main/install.sh | bash
#
# Downloads the latest prebuilt distribution package (headless daemon bundle +
# renderer static assets — architecture-agnostic, no bundled Node runtime),
# extracts it, registers the `crosspilot` launcher command, and starts the
# daemon via the package's own setup.sh (which opens the browser at
# http://127.0.0.1:3456). The package normally includes production
# dependencies; setup.sh only needs bun/npm if it has to reinstall them locally.
#
# Prerequisite: Node.js 22+ must already be installed on this machine — this
# installer does not manage the Node environment itself (see README).
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
CONFIG_DIR="${CROSSPILOT_DATA_DIR:-$HOME/.crosspilot}"

_register_launcher() {
  local launcher="$INSTALL_DIR/crosspilot"
  if [ ! -x "$launcher" ]; then
    echo "⚠️  crosspilot launcher missing from package; skipping command registration." >&2
    return 0
  fi

  local bin_dir=""
  if [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
    bin_dir="/usr/local/bin"
  else
    bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
  fi

  local target="$bin_dir/crosspilot"
  ln -sf "$launcher" "$target" 2>/dev/null || cp "$launcher" "$target"
  chmod +x "$target"
  echo "→ registered command: $target"

  case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *)
      if [ "$bin_dir" = "$HOME/.local/bin" ]; then
        local profile="$HOME/.profile"
        case "${SHELL:-}" in
          */zsh) profile="$HOME/.zshrc" ;;
          */bash) profile="$HOME/.bashrc" ;;
        esac
        if ! grep -qs 'CrossPilot launcher' "$profile" 2>/dev/null; then
          {
            echo ''
            echo '# CrossPilot launcher'
            echo 'export PATH="$HOME/.local/bin:$PATH"'
          } >> "$profile"
        fi
        echo "→ added $bin_dir to PATH in $profile (open a new terminal before running crosspilot directly)"
      else
        echo "⚠️  $bin_dir is not in PATH; add it before running crosspilot directly." >&2
      fi
      ;;
  esac
}

if ! command -v node >/dev/null 2>&1; then
  echo "❌ 未找到 node。CrossPilot 需要先安装 Node.js 22+，安装完成后重新运行本脚本。" >&2
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

mkdir -p "$CONFIG_DIR"
printf '%s\n' "$INSTALL_DIR" > "$CONFIG_DIR/install-dir"

cd "$INSTALL_DIR"
chmod +x setup.sh crosspilot 2>/dev/null || chmod +x setup.sh
_register_launcher

echo "→ starting CrossPilot…"
exec ./setup.sh
