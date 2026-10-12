# -*- coding: utf-8 -*-
"""Build an EPUB 3 from src/*.xhtml (pure stdlib)."""
import os
import sys
import uuid
import zipfile
import xml.etree.ElementTree as ET

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "src")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ClaudeCodeTutorial.epub")

# (file, toc title)
SPINE = [
    ("cover.xhtml", "封面"),
    ("tldr.xhtml", "速读版：十条最佳实践"),
    ("preface.xhtml", "前言"),
    ("ch01.xhtml", "第 1 章 心智模型"),
    ("ch02.xhtml", "第 2 章 Claude Code 快速上手"),
    ("ch03.xhtml", "第 3 章 指挥的艺术"),
    ("ch04.xhtml", "第 4 章 记忆体系"),
    ("ch05.xhtml", "第 5 章 OMC 入门"),
    ("ch06.xhtml", "第 6 章 核心工作流 plan-execute-review-verify"),
    ("ch07.xhtml", "第 7 章 自主模式"),
    ("ch08.xhtml", "第 8 章 知识沉淀"),
    ("ch09.xhtml", "第 9 章 持续进化的闭环"),
    ("ch10.xhtml", "第 10 章 实战演练"),
    ("appendix.xhtml", "附录 常用命令速查表"),
]

TITLE = "指挥AI的艺术：用 Claude Code + OMC 打造持续学习与进化的智能工作流"
MODIFIED = "2026-10-12T00:00:00Z"


def build():
    for name, _t in SPINE:
        ET.parse(os.path.join(SRC, name))  # raises on malformed XML
    print("XML well-formed: %d files" % len(SPINE))

    uid = "urn:uuid:" + str(uuid.uuid4())
    manifest = ['<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>',
                '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>',
                '<item id="css" href="style.css" media-type="text/css"/>']
    manifest += ['<item id="s%02d" href="%s" media-type="application/xhtml+xml"/>' % (i, n)
                 for i, (n, _t) in enumerate(SPINE)]

    # spine: cover first, then the nav "目录" page, then chapters
    spine_refs = ['    <itemref idref="s00"/>', '    <itemref idref="nav"/>']
    spine_refs += ['    <itemref idref="s%02d"/>' % i for i in range(1, len(SPINE))]

    opf = "\n".join([
        '<?xml version="1.0" encoding="utf-8"?>',
        '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">',
        '  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">',
        '    <dc:identifier id="pub-id">%s</dc:identifier>' % uid,
        '    <dc:title>%s</dc:title>' % TITLE,
        '    <dc:language>zh-CN</dc:language>',
        '    <dc:creator>柳生流云</dc:creator>',
        '    <meta property="dcterms:modified">%s</meta>' % MODIFIED,
        '  </metadata>',
        '  <manifest>',
        ] + ['    ' + m for m in manifest] + [
        '  </manifest>',
        '  <spine toc="ncx">',
        ] + spine_refs + [
        '  </spine>',
        '</package>'])

    nav_items = ['<li><a href="%s">%s</a></li>' % (n, t) for n, t in SPINE]
    nav = "\n".join([
        '<?xml version="1.0" encoding="utf-8"?>',
        '<!DOCTYPE html>',
        '<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">',
        '<head><meta charset="utf-8"/><title>目录</title></head>',
        '<body>',
        '  <nav epub:type="toc" id="toc">',
        '    <h1>目录</h1>',
        '    <ol>',
        ] + ['      ' + li for li in nav_items] + [
        '    </ol>',
        '  </nav>',
        '</body>',
        '</html>'])

    # legacy NCX for older readers
    toc_entries = [("cover.xhtml", "封面"), ("nav.xhtml", "目录")] + SPINE[1:]
    navpoints = []
    for i, (href, label) in enumerate(toc_entries):
        navpoints.append(
            '    <navPoint id="np%d" playOrder="%d"><navLabel><text>%s</text></navLabel>'
            '<content src="%s"/></navPoint>' % (i, i + 1, label, href))
    ncx = "\n".join([
        '<?xml version="1.0" encoding="utf-8"?>',
        '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">',
        '  <head>',
        '    <meta name="dtb:uid" content="%s"/>' % uid,
        '    <meta name="dtb:depth" content="1"/>',
        '    <meta name="dtb:totalPageCount" content="0"/>',
        '    <meta name="dtb:maxPageNumber" content="0"/>',
        '  </head>',
        '  <docTitle><text>%s</text></docTitle>' % TITLE,
        '  <navMap>',
        ] + navpoints + [
        '  </navMap>',
        '</ncx>'])

    tmp = os.path.join(os.path.dirname(SRC), "build")
    os.makedirs(tmp, exist_ok=True)
    for fname, text in (("content.opf", opf), ("nav.xhtml", nav), ("toc.ncx", ncx)):
        p = os.path.join(tmp, fname)
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        ET.parse(p)  # validate

    with open(os.path.join(tmp, "mimetype"), "w", newline="") as f:
        f.write("application/epub+zip")

    container = "\n".join([
        '<?xml version="1.0" encoding="utf-8"?>',
        '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">',
        '  <rootfiles>',
        '    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>',
        '  </rootfiles>',
        '</container>'])
    with open(os.path.join(tmp, "container.xml"), "w", encoding="utf-8", newline="\n") as f:
        f.write(container)

    with zipfile.ZipFile(OUT, "w") as z:
        z.write(os.path.join(tmp, "mimetype"), "mimetype",
                compress_type=zipfile.ZIP_STORED)
        z.write(os.path.join(tmp, "container.xml"), "META-INF/container.xml",
                compress_type=zipfile.ZIP_DEFLATED)
        z.write(os.path.join(tmp, "content.opf"), "OEBPS/content.opf",
                compress_type=zipfile.ZIP_DEFLATED)
        z.write(os.path.join(tmp, "nav.xhtml"), "OEBPS/nav.xhtml",
                compress_type=zipfile.ZIP_DEFLATED)
        z.write(os.path.join(tmp, "toc.ncx"), "OEBPS/toc.ncx",
                compress_type=zipfile.ZIP_DEFLATED)
        z.write(os.path.join(SRC, "style.css"), "OEBPS/style.css",
                compress_type=zipfile.ZIP_DEFLATED)
        for name, _t in SPINE:
            z.write(os.path.join(SRC, name), "OEBPS/" + name,
                    compress_type=zipfile.ZIP_DEFLATED)
    print("EPUB written: %s (%d bytes)" % (OUT, os.path.getsize(OUT)))


if __name__ == "__main__":
    build()

