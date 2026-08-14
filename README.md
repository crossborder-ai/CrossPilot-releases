# CrossPilot

CrossPilot 是一个跨境电商 AI 决策平台，提供库存分析、补货建议等 agent 工作流能力。本仓库存放公开构建产物（安装包 + 安装脚本），源码仓库保持私有。

## 安装

### 前提条件

CrossPilot 需要本机已有 **Node.js 22+**。当前安装包已内置生产依赖，正常安装不需要现场安装 npm 依赖；但建议同时安装 **bun** 作为依赖 fallback 兜底。

先检查本机是否已经满足：

```bash
node -v
bun -v
```

如果 `node -v` 显示 `v22.x` 或更高，可以直接跳到下一节运行 CrossPilot 一键安装命令。

macOS 已安装 Homebrew 时，直接运行：

```bash
brew install node@22 bun
brew link --overwrite --force node@22
node -v
bun -v
```

如果没有 Homebrew，可以用 fnm 安装 Node 22，再安装 bun：

```bash
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null || true
fnm install 22
fnm use 22
curl -fsSL https://bun.sh/install | bash
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null || true
node -v
bun -v
```

如果安装后当前终端仍提示 `node` 或 `bun` 找不到，关闭终端重新打开后再执行检查命令。

### 一键安装 / 更新到最新版

```bash
curl -fsSL https://raw.githubusercontent.com/crossborder-ai/CrossPilot-releases/main/install.sh | bash
```

首次安装和后续更新都使用同一条命令。脚本每次都会下载本仓库 latest release 里的最新 `crosspilot-dist.tar.gz`，替换本地应用文件，但不会删除本地数据。

安装脚本会自动：
1. 下载最新构建包（默认装到 `~/CrossPilot-app`）
2. 使用安装包内置的运行时依赖；仅在本机 Node 架构不兼容时才尝试本地修复/安装依赖（国内网络下会自动探测并切换到 npmmirror.com 镜像加速，无需手动配置）
3. 注册全局命令 `crosspilot`（写入 `/usr/local/bin` 或 `~/.local/bin`）
4. 启动 CrossPilot 守护进程并打开浏览器

安装完成后脚本会自动打开浏览器；如果没有自动打开，手动访问 <http://localhost:3456> 即可使用。

### 日常使用

安装完成后不需要重复走一键安装流程。之后每次要用，在任意终端运行：

```bash
crosspilot
```

它会自动检测服务是否已在运行（未运行则启动、已运行则直接复用），并打开浏览器。

如果终端提示找不到 `crosspilot`，通常是本次安装把命令写到了 `~/.local/bin`，但当前终端还没刷新 PATH。打开一个新终端后再试；仍不行时可临时运行：

```bash
~/.local/bin/crosspilot
```

**启停行为**：关闭浏览器标签页后，服务会在约 30 秒无心跳后自动退出，不需要手动停止或保留终端窗口常驻。

### 领星配置

首次使用领星数据前，先启动 CrossPilot，然后在浏览器里打开 <http://localhost:3456>：

1. 进入设置页。
2. 打开 LingXing / 领星配置区。
3. 如果页面提示缺少 MCP URL，先填入平台提供的 LingXing MCP 地址并保存。
4. 填入 LingXing MCP Key 并保存。
5. 点击连接测试；测试通过后再回到聊天页查询库存、补货等数据。

Key 只在本机配置中保存，不要发到群聊或贴进 README。

### 发布节奏

CrossPilot 主仓库每次合并到 `main` 后会自动构建新的轻量分发包，并发布到本仓库的 latest release。用户侧不需要手动选择版本；重新执行一键安装命令即可更新到当前最新版本。

### 环境变量

| 变量 | 说明 | 默认值 |
|---|---|---|
| `CROSSPILOT_INSTALL_DIR` | 安装目录 | `~/CrossPilot-app` |
| `CROSSPILOT_DATA_DIR` | 数据目录 | `~/.crosspilot` |
| `CROSSPILOT_PORT` | 监听端口 | `3456` |
| `CROSSPILOT_MIRROR` | 强制启用/禁用 npmmirror.com 镜像（`1`/`0`），默认自动探测 | 自动探测 |

> **注意**：重新安装会替换 `CROSSPILOT_INSTALL_DIR` 下的应用文件，数据目录（`CROSSPILOT_DATA_DIR`）不受影响。
