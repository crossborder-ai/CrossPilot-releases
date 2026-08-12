# CrossPilot

CrossPilot 是一个跨境电商 AI 决策平台，提供库存分析、补货建议等 agent 工作流能力。本仓库存放公开构建产物（安装包 + 安装脚本），源码仓库保持私有。

## 安装

### 前提条件

- **Node.js 22+** — [nodejs.org](https://nodejs.org/)
- **bun**（推荐）或 **npm** — [bun.sh](https://bun.sh/)

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/crossborder-ai/CrossPilot-releases/main/install.sh | bash
```

安装脚本会自动：
1. 下载最新构建包（默认装到 `~/CrossPilot-app`）
2. 安装运行时依赖
3. 启动 CrossPilot 守护进程

安装完成后，浏览器打开 <http://localhost:3456> 即可使用。

### 环境变量

| 变量 | 说明 | 默认值 |
|---|---|---|
| `CROSSPILOT_INSTALL_DIR` | 安装目录 | `~/CrossPilot-app` |
| `CROSSPILOT_DATA_DIR` | 数据目录 | `~/.crosspilot` |
| `CROSSPILOT_PORT` | 监听端口 | `3456` |

> **注意**：重新安装会替换 `CROSSPILOT_INSTALL_DIR` 下的应用文件，数据目录（`CROSSPILOT_DATA_DIR`）不受影响。
