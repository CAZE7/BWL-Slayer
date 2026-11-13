#!/usr/bin/env python3
"""Baut die Single-File-Version des CFO-Simulators (kein CDN, kein Backend)."""
import pathlib, re, datetime

base = pathlib.Path(__file__).parent
src = base / "src"
out = base.parent / "delizioso-cfo-simulator.html"

css = (src / "styles.css").read_text(encoding="utf-8")
js_files = ["engine.js", "data1.js", "data2.js", "data3.js", "ui_core.js", "ui_stages.js", "ui_sims.js", "app.js"]
js = "\n\n".join((src / f).read_text(encoding="utf-8") for f in js_files)

html = f"""<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Delizioso AG – Der CFO-Simulator · Investition &amp; Finanzierung 1</title>
<style>
{css}
</style>
</head>
<body>
<div id="app"></div>
<div id="toast"></div>
<script>
{js}
</script>
</body>
</html>
"""
out.write_text(html, encoding="utf-8")
print(f"geschrieben: {out}  ({len(html)/1024:.1f} KB)")
