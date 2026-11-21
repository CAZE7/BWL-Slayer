#!/usr/bin/env python3
"""
BWL Slayer · Testergebnis als GitHub-Actions-Annotation ausgeben.

Liest den JSON-Bericht des GDScript-Testlaufs und gibt ihn als
Workflow-Kommando aus. Damit ist das Ergebnis auch dann lesbar, wenn
das Job-Log nicht abrufbar ist (z. B. aus einem fremden Netzwerk).

Aufruf:  python3 tools/report_tests.py godot/test-report/report.json
"""

import json
import sys


def main() -> int:
    # Modus "--import": Gibt das Import-Log als Annotation aus.
    if len(sys.argv) >= 2 and sys.argv[1] == "--import":
        if len(sys.argv) < 3:
            print("Aufruf: report_tests.py --import <import.log>", file=sys.stderr)
            return 2
        try:
            with open(sys.argv[2], "r", encoding="utf-8", errors="replace") as handle:
                lines = [line.rstrip() for line in handle.readlines()]
        except OSError as error:
            print(f"FEHLER: Import-Log nicht lesbar: {error}", file=sys.stderr)
            return 1
        interesting = [
            line for line in lines
            if line.strip() and "ERROR" in line or "SCRIPT ERROR" in line or "error" in line.lower()
        ]
        print("::group::Import-Protokoll")
        for line in (interesting or lines)[:80]:
            print(line)
        print("::endgroup::")
        return 0

    # Modus "--annotations": Gibt jede fehlgeschlagene Pruefung als
    # eigene Annotation aus. Annotationen sind ueber die REST-API
    # abrufbar, das Job-Log nicht.
    if len(sys.argv) >= 2 and sys.argv[1] == "--annotations":
        if len(sys.argv) < 3:
            print("Aufruf: report_tests.py --annotations <report.json>", file=sys.stderr)
            return 2
        try:
            with open(sys.argv[2], "r", encoding="utf-8") as handle:
                data = json.load(handle)
        except (OSError, json.JSONDecodeError) as error:
            print(f"FEHLER: Bericht nicht lesbar: {error}", file=sys.stderr)
            return 1
        failures = data.get("failures", [])
        for failure in failures[:40]:
            print(f"::error title=Testfehler::{failure}")
        if not failures:
            print("::notice title=Testergebnis::Keine fehlgeschlagenen Pruefungen.")
        return 0

    # Modus "--raw": Gibt die Ausgabe des Godot-Prozesses Zeile fuer
    # Zeile als Annotation aus. Laufzeitfehler von GDScript erscheinen
    # nur dort, nicht im JSON-Bericht.
    if len(sys.argv) >= 2 and sys.argv[1] == "--raw":
        if len(sys.argv) < 3:
            print("Aufruf: report_tests.py --raw <logfile>", file=sys.stderr)
            return 2
        try:
            with open(sys.argv[2], "r", encoding="utf-8", errors="replace") as handle:
                lines = [line.rstrip() for line in handle.readlines()]
        except OSError as error:
            print(f"FEHLER: Log nicht lesbar: {error}", file=sys.stderr)
            return 1
        title = "Godot-Ausgabe"
        if len(sys.argv) >= 4:
            title = sys.argv[3]
        # Nur Zeilen ausgeben, die Erkenntnisse bringen. Die Ausgabe
        # enthaelt sonst viele Fortschrittszeilen von Godot selbst.
        interesting = [
            line for line in lines
            if line.strip()
            and "Godot Engine v" not in line
            and not line.startswith("[")
            and "first_scan_filesystem" not in line
            and "Started Project initialization" not in line
        ]
        if not interesting:
            interesting = [line for line in lines if line.strip()]
        # Die Ausgabe ist auf 80 Annotationen begrenzt.
        for line in interesting[:80]:
            print(f"::error title={title}::{line}")
        return 0

    if len(sys.argv) < 2:
        print("Aufruf: report_tests.py <report.json>", file=sys.stderr)
        return 2

    path = sys.argv[1]
    try:
        with open(path, "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        print(f"FEHLER: Bericht nicht lesbar: {error}", file=sys.stderr)
        return 1

    passed = int(data.get("passed", 0))
    failed = int(data.get("failed", 0))
    failures = data.get("failures", [])

    print("::group::Testergebnis")
    print(f"bestanden: {passed}")
    print(f"fehlgeschlagen: {failed}")
    if failures:
        print("Fehlgeschlagene Pruefungen:")
        for failure in failures[:60]:
            print(f" - {failure}")
    print("::endgroup::")

    return 0


if __name__ == "__main__":
    sys.exit(main())
