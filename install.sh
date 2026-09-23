#!/usr/bin/env bash
# CrossPilot one-line remote installer.
#
#   curl -fsSL https://download.crosspilot.ai/install.sh | bash
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

ASSET="crosspilot-dist.tar.gz"
DOWNLOAD_BASE_URL="${CROSSPILOT_DOWNLOAD_BASE_URL:-https://download.crosspilot.ai}"
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
URL="${CROSSPILOT_DIST_URL:-${DOWNLOAD_BASE_URL%/}/${ASSET}}"
echo "→ CrossPilot installer"
echo "→ downloading ${URL}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL "$URL" -o "$TMP_DIR/$ASSET"

# ─── integrity check ────────────────────────────────────────────────────────────
# What this defends against: a truncated or CDN-mangled download. What it does NOT
# defend against: the server itself serving tampered bytes — the checksum comes from
# the same server as the tarball, so it is a transport check, not a trust anchor. Do
# not describe it as "verified safe" on that basis.
# The published pair must be produced by one build (see docs/specs/distribution-surfaces.md).
# VERIFY_SHA256_BEGIN (kept as a marked block so tests can exercise the real code)
verify_sha256() {
  # $1 = downloaded file, $2 = checksum file whose first field is the expected hash
  local file="$1" sumfile="$2"
  local expected actual
  expected="$(awk 'NF {print $1; exit}' "$sumfile" 2>/dev/null)"
  if [ -z "$expected" ]; then
    echo "❌ 校验文件是空的或读不到：$sumfile" >&2
    return 1
  fi
  actual="$(shasum -a 256 "$file" 2>/dev/null | awk '{print $1}')"
  if [ -z "$actual" ]; then
    echo "❌ 无法计算本机下载文件的 sha256（缺 shasum？）" >&2
    return 1
  fi
  if [ "$expected" != "$actual" ]; then
    echo "❌ 下载的文件校验不通过（可能传输被截断或镜像不一致）：" >&2
    echo "   期望 $expected" >&2
    echo "   实际 $actual" >&2
    echo "   请重新运行安装命令；若反复失败，说明发布面本身有问题，请反馈给我们。" >&2
    return 1
  fi
  echo "→ checksum ok (sha256 ${actual})"
  return 0
}
# VERIFY_SHA256_END

SUM_URL="${CROSSPILOT_DIST_SUM_URL:-${URL}.sha256}"
if curl -fsSL "$SUM_URL" -o "$TMP_DIR/$ASSET.sha256"; then
  verify_sha256 "$TMP_DIR/$ASSET" "$TMP_DIR/$ASSET.sha256" || exit 1
else
  # Backwards compatible on purpose: an older mirror has no .sha256 yet, and refusing
  # to install at all would be worse than installing without the transport check.
  echo "⚠️  没能取到校验文件（${SUM_URL}）；跳过校验继续安装。" >&2
fi

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
