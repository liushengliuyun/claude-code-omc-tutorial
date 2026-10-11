# -*- coding: utf-8 -*-
"""Build a single-page HTML version (docs/index.html) from src/*.xhtml."""
import os
import re

BASE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(BASE, "src")
OUT = os.path.join(BASE, "docs", "index.html")

CHAPTERS = [
    ("cover", "封面"),
    ("preface", "前言：从“敲代码的助手”到“可指挥的团队”"),
    ("ch01", "第 1 章 心智模型：AI 是一个失忆的聪明同事"),
    ("ch02", "第 2 章 Claude Code 快速上手"),
    ("ch03", "第 3 章 指挥的艺术：需求、上下文与成功标准"),
    ("ch04", "第 4 章 记忆体系：让 AI 记住你和你的项目"),
    ("ch05", "第 5 章 OMC 入门：多智能体定义与路由"),
    ("ch06", "第 6 章 OMC 核心工作流：plan → execute → review → verify"),
    ("ch07", "第 7 章 自主模式：autopilot / ralph / ultragoal / team"),
    ("ch08", "第 8 章 知识沉淀：wiki / remember / deepinit / skillify"),
    ("ch09", "第 9 章 持续进化的闭环"),
    ("ch10", "第 10 章 实战：从需求到交付的完整演练"),
    ("appendix", "附录 常用命令速查表"),
]

CSS = """
* { box-sizing: border-box; }
body { margin: 0; font-family: "Segoe UI", "Microsoft YaHei", sans-serif;
       line-height: 1.75; color: #24292f; background: #fff; }
.layout { display: flex; max-width: 1280px; margin: 0 auto; }
nav.toc { width: 300px; flex: none; position: sticky; top: 0;
          max-height: 100vh; overflow-y: auto; padding: 24px 16px;
          border-right: 1px solid #d0d7de; background: #f6f8fa; }
nav.toc h2 { font-size: 1em; margin: 0 0 12px; color: #57606a; }
nav.toc a { display: block; padding: 5px 10px; border-radius: 6px;
            color: #24292f; text-decoration: none; font-size: 0.9em; }
nav.toc a:hover { background: #eaeef2; }
main { flex: 1; min-width: 0; padding: 24px 40px 80px; max-width: 860px; }
h1 { font-size: 1.55em; border-bottom: 2px solid #d0d7de; padding-bottom: 8px; }
h2 { font-size: 1.25em; border-bottom: 1px solid #eaeef2; padding-bottom: 6px; }
pre { background: #f6f8fa; border: 1px solid #d0d7de; border-radius: 6px;
      padding: 12px; overflow-x: auto; font-size: 0.88em; line-height: 1.5; }
code { font-family: Consolas, "Cascadia Mono", monospace; font-size: 0.9em;
       background: #f6f8fa; padding: 1px 5px; border-radius: 4px; }
pre code { background: none; padding: 0; }
table { border-collapse: collapse; width: 100%; margin: 12px 0; font-size: 0.92em; }
th, td { border: 1px solid #d0d7de; padding: 6px 10px; text-align: left; }
th { background: #f6f8fa; }
blockquote { color: #57606a; border-left: 4px solid #d0d7de;
             margin-left: 0; padding-left: 12px; }
header.book { border-bottom: 3px double #d0d7de; margin-bottom: 24px; padding-bottom: 16px; }
header.book h1 { border: none; margin: 0; }
header.book .meta { color: #57606a; }
@media (max-width: 900px) {
  nav.toc { position: static; width: auto; border-right: none;
            border-bottom: 1px solid #d0d7de; max-height: none; }
  .layout { flex-direction: column; }
}
"""

PAGE = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>{css}</style>
</head>
<body>
<div class="layout">
<nav class="toc">
<h2>目录</h2>
{toc}
</nav>
<main>
<header class="book">
<h1>{title}</h1>
<p class="meta">代逸凡 · 编 · 2026 年 10 月 ·
<a href="https://github.com/liushengliuyun/claude-code-omc-tutorial">GitHub 仓库</a></p>
</header>
{body}
</main>
</div>
</body>
</html>
"""


def body_of(path):
    text = open(path, encoding="utf-8").read()
    m = re.search(r"<body>(.*)</body>", text, re.S)
    return m.group(1)


def main():
    toc = []
    parts = []
    for slug, label in CHAPTERS:
        path = os.path.join(SRC, slug + ".xhtml")
        toc.append('<a href="#sec-%s">%s</a>' % (slug, label))
        parts.append('<section id="sec-%s">%s</section>' % (slug, body_of(path)))
    title = "指挥AI的艺术：用 Claude Code + OMC 打造持续学习与进化的智能工作流"
    html = PAGE.format(title=title, css=CSS,
                       toc="\n".join(toc), body="\n".join(parts))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(html)
    print("HTML written: %s (%d bytes)" % (OUT, os.path.getsize(OUT)))


if __name__ == "__main__":
    main()
