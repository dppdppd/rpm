#!/usr/bin/env python3
"""Tier-1 offline citation audit (zero research tokens).

For each completed research tree under /home/coder/projects/*/docs/research/<slug>/,
extract the DISTINCTIVE quantitative figures from findings/report.md and screen each
against the tree's OWN cached fetched/ sources. A figure whose digit-core appears in
NO fetched source is an ORPHAN — a deterministic lower bound on unsupported figures
(model-memory / Frankenstein citations). Precise rate needs the LLM semantic pass;
this is the cheap screen that establishes the baseline.

Limitations (by design, v1):
- Only .md/.txt/.html fetched files are searchable; PDFs without an extracted sidecar
  are unsearchable -> such trees are flagged low-search and excluded from the headline.
- "core in corpus" is digit-run presence, separator-insensitive. It can't tell a
  correctly-cited figure from a coincidental digit match -> it UNDERCOUNTS unsupported
  (orphan is high-precision: absent digits => genuinely not in the sources).
"""
import os, re, glob, sys

ROOT = "/home/coder/projects"
MIN_CORPUS = 2000  # chars; below this a tree is "low-search" (thin/all-PDF)

def load_corpus(tree):
    fdir = os.path.join(tree, "fetched")
    if not os.path.isdir(fdir):
        return "", 0
    files = os.listdir(fdir)
    texts, pdfs_no_sidecar = [], 0
    md_bases = {f[:-3] for f in files if f.endswith(".md")}
    for f in files:
        p = os.path.join(fdir, f)
        if not os.path.isfile(p):
            continue
        if f.endswith((".md", ".txt", ".html", ".htm")):
            try:
                texts.append(open(p, encoding="utf-8", errors="ignore").read())
            except Exception:
                pass
        elif f.endswith(".pdf"):
            base = f[:-4]
            if not any(b.startswith(base) for b in md_bases):
                pdfs_no_sidecar += 1
    corpus = " ".join(texts).lower()
    corpus = re.sub(r"(?<=\d),(?=\d)", "", corpus)        # 1,234 -> 1234
    corpus = re.sub(r"<[^>]+>", " ", corpus)               # crude tag strip
    return corpus, pdfs_no_sidecar

def extract_figures(text):
    figs = []
    pats = [
        r"ƒ\s?(\d[\d.,]*)\s?(?:m|million|bn|billion)?",
        r"(\d[\d.,]*)\s?(?:million|billion)\s?(?:guilders|florins?)",
        r"(\d[\d.,]*)\s?(?:guilders|florins)",
        r"(\d+(?:\.\d+)?)\s?(?:%|per ?cents?)",
    ]
    for pat in pats:
        for m in re.finditer(pat, text, re.I):
            raw = m.group(0).strip()
            core = m.group(1).replace(",", "").rstrip(".")
            figs.append((raw, core))
    return figs

def distinctive(core):
    # Deterministic screen is only reliable where a digit-match isn't coincidence:
    # decimals + 3-digit+ integers. 2-digit cores (43, 62, 18) match by chance in a
    # large corpus -> they read as false "present" and need the LLM semantic pass.
    if "." in core:
        return True
    return len(core) >= 3

def in_corpus(core, corpus):
    if "." in core:
        intp, dec = core.split(".", 1)
        variants = [core]
        if dec == "5":
            variants += [f"{intp}½", f"{intp} ½", f"{intp} 1/2"]
        return any(v in corpus for v in variants)
    return re.search(r"(?<!\d)" + re.escape(core) + r"(?!\d)", corpus) is not None

def main():
    trees = sorted(glob.glob(f"{ROOT}/*/docs/research/*/"))
    rows, agg_fig, agg_orphan, low_search = [], 0, 0, 0
    voc_detail = None
    for tree in trees:
        rpt = os.path.join(tree, "findings", "report.md")
        if not os.path.isfile(rpt):
            continue
        report = open(rpt, encoding="utf-8", errors="ignore").read()
        corpus, pdf_ns = load_corpus(tree)
        figs = extract_figures(report)
        # dedupe by (raw lower) and keep only distinctive
        seen, dist = set(), []
        for raw, core in figs:
            k = raw.lower()
            if k in seen:
                continue
            seen.add(k)
            if distinctive(core):
                dist.append((raw, core))
        if not dist:
            continue
        orphans = [(raw, core) for raw, core in dist if not in_corpus(core, corpus)]
        slug = os.path.basename(tree.rstrip("/"))
        proj = tree.split("/docs/research/")[0].split("/")[-1]
        searchable = len(corpus) >= MIN_CORPUS
        rate = 100.0 * len(orphans) / len(dist)
        rows.append((proj, slug, len(dist), len(orphans), rate, searchable, pdf_ns))
        if searchable:
            agg_fig += len(dist)
            agg_orphan += len(orphans)
        else:
            low_search += 1
        if slug == "voc-decline-era-1680-1800":
            voc_detail = (dist, orphans, len(corpus), pdf_ns)

    rows.sort(key=lambda r: (-r[4], -r[2]))
    print(f"{'PROJECT':<10} {'SLUG':<36} {'figs':>4} {'orph':>4} {'orph%':>6} {'srch':>4} {'pdf?':>4}")
    for proj, slug, nf, no, rate, srch, pdf_ns in rows:
        print(f"{proj:<10} {slug[:36]:<36} {nf:>4} {no:>4} {rate:>5.0f}% {('y' if srch else 'LOW'):>4} {pdf_ns:>4}")
    print("-" * 76)
    print(f"searchable trees: {sum(1 for r in rows if r[5])}   low-search excluded: {low_search}")
    if agg_fig:
        print(f"AGGREGATE (searchable): {agg_orphan}/{agg_fig} distinctive figures ORPHAN "
              f"= {100.0*agg_orphan/agg_fig:.0f}% deterministic lower-bound unsupported rate")
    if voc_detail:
        dist, orphans, clen, pdf_ns = voc_detail
        oset = {r for r, _ in orphans}
        print(f"\n=== voc-decline-era validation (corpus {clen} chars, {pdf_ns} unsearchable pdfs) ===")
        print(f"distinctive figures: {len(dist)}  orphan: {len(orphans)}")
        print("orphans (grader flagged ƒ134M/ƒ62M as memory-sourced — expect 134/62 here):")
        for raw, core in orphans:
            print(f"   ORPHAN  {raw}   (core {core})")

if __name__ == "__main__":
    main()
