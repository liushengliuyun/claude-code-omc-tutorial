# 指挥AI的艺术：用 Claude Code + OMC 打造持续学习与进化的智能工作流

一本中文 EPUB 电子书教程，回答三个问题：

1. **怎么指挥 AI** —— 委派指令四要素（目标/约束/验收标准/执行方式）、任务规模与指挥粒度、反模式清单；
2. **怎么让 AI 持续学习** —— 五层记忆体系（全局 CLAUDE.md / 项目 CLAUDE.md·AGENTS.md / auto-memory / OMC notepad·project-memory / wiki）；
3. **怎么让 AI 进化** —— OMC 多智能体编排（plan → execute → review → verify）、自主模式（autopilot / ralph / ultragoal / team）、知识沉淀（wiki / remember / deepinit / skillify）、持续进化闭环。

## 目录

| 章节 | 内容 |
|------|------|
| 第 1 章 | 心智模型：AI 是一个失忆的聪明同事 |
| 第 2 章 | Claude Code 快速上手 |
| 第 3 章 | 指挥的艺术：需求、上下文与成功标准 |
| 第 4 章 | 记忆体系：让 AI 记住你和你的项目 |
| 第 5 章 | OMC 入门：多智能体定义与路由 |
| 第 6 章 | 核心工作流 plan → execute → review → verify |
| 第 7 章 | 自主模式：autopilot / ralph / ultragoal / team |
| 第 8 章 | 知识沉淀：wiki / remember / deepinit / skillify |
| 第 9 章 | 持续进化的闭环 |
| 第 10 章 | 实战：从需求到交付的完整演练 |
| 附录 | 常用命令速查表 |

## 文件说明

- `ClaudeCodeTutorial.epub` — 成品电子书（EPUB 3，可直接导入阅读器）
- `src/` — 各章节 XHTML 源文件 + 样式表
- `build_epub.py` — 打包脚本（纯标准库，`python build_epub.py` 重新生成 EPUB）

## 阅读

- **在线阅读（推荐）**：https://liushengliuyun.github.io/claude-code-omc-tutorial/ （GitHub Pages，左侧目录导航）
- **番外篇**：[CC Switch 指南 — 给 Claude Code 换发动机](https://liushengliuyun.github.io/claude-code-omc-tutorial/cc-switch.html)（作用/使用说明/买 Key/配 Key，DeepSeek 按量付费）
- **EPUB 下载**：`ClaudeCodeTutorial.epub` — 用任意 EPUB 阅读器打开（内置目录索引 + NCX 兼容旧阅读器）
- **[Releases](https://github.com/liushengliuyun/claude-code-omc-tutorial/releases)**：v1.0（舟氏AI启航包暂未挂载，受本机网络上传限制，如需获取请联系作者）

## 番外：CC Switch + 国内按量付费模型（DeepSeek 示例）

**CC Switch**（[farion1231/cc-switch](https://github.com/farion1231/cc-switch)，官网 ccswitch.io）是开源桌面工具，给 Claude Code / Codex 等命令行 AI 工具做**供应商管理**：多供应商配置卡片一键切换（原理是改写 `~/.claude/settings.json` 里的 `ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN`/`ANTHROPIC_MODEL`），带格式路由（Anthropic/OpenAI 互转）、用量日志、MCP/提示词/Skills 管理和自动备份。

**买 Key（国内可买、按量付费、非包月）首选 DeepSeek**：

1. [platform.deepseek.com](https://platform.deepseek.com) 注册 → 充值（微信/支付宝）→「API Keys」创建 `sk-...`（只显示一次）；
2. 按量计费无包月：`deepseek-flash` 输入错峰 $0.15/百万 tokens（高峰 $0.3），输出错峰 $0.6（高峰 $1.2）；`deepseek-v4-pro` 约为 flash 的 4.4 倍；缓存命中输入低至 $0.003；
3. CC Switch 里添加 Claude 类型供应商：Base URL `https://api.deepseek.com/anthropic` + Key + 模型 `deepseek-flash`（服务端自动把 claude-opus 映射 v4-pro、sonnet/haiku 映射 flash，想控成本就显式指定）；
4. 免安装方案直接设环境变量：`ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_MODEL` / `CLAUDE_CODE_SUBAGENT_MODEL`。

详细图文与注意事项见[在线番外篇](https://liushengliuyun.github.io/claude-code-omc-tutorial/cc-switch.html)。

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
