#!/usr/bin/env python3
"""
BWL Slayer · GitHub-Release-Asset auflösen.

Godot-Editor und Export-Templates werden als Release-Assets von
godotengine/godot verteilt. Der direkte Download-Link leitet auf
objects.githubusercontent.com um, was auf CI-Runnern nicht immer
zuverlässig funktioniert. Stattdessen wird die Asset-ID ueber die
Release-API ermittelt und der Download laeuft ueber den
Release-Asset-Endpunkt.

Aufruf:  python3 tools/resolve_asset.py <tag> <asset-name>
Ausgabe: die numerische Asset-ID auf stdout (Exit-Code 0)

Bei Fehlern: Liste aller verfuegbaren Assets auf stderr, Exit-Code 1.

Hinweis zur Authentifizierung: Fuer oeffentliche Repositories ist
kein Token noetig. Fuer private Repositories wird GITHUB_TOKEN bzw.
GH_TOKEN aus der Umgebung verwendet, sofern gesetzt.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request

API_ROOT = "https://api.github.com"
DEFAULT_REPO = "godotengine/godot"
RETRY_COUNT = 5
RETRY_DELAY = 3


def _headers() -> dict:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "bwl-slayer-ci",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = "Bearer %s" % token
    return headers


def _fetch(url: str) -> dict:
    """Holt eine URL mit Wiederholungen (Rate-Limits und Netzwerkfehler)."""
    last_error = None
    for attempt in range(1, RETRY_COUNT + 1):
        request = urllib.request.Request(url, headers=_headers())
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            last_error = error
            # 403/429: Rate-Limit oder sekundaere Stoerung -> warten
            if error.code in (403, 429, 500, 502, 503, 504):
                if attempt < RETRY_COUNT:
                    wait = RETRY_DELAY * attempt
                    print(
                        "WARNUNG: HTTP %s bei %s – Versuch %d/%d, warte %ds"
                        % (error.code, url, attempt, RETRY_COUNT, wait),
                        file=sys.stderr,
                    )
                    time.sleep(wait)
                    continue
            break
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            last_error = error
            if attempt < RETRY_COUNT:
                wait = RETRY_DELAY * attempt
                print(
                    "WARNUNG: Netzwerkfehler (%s) – Versuch %d/%d, warte %ds"
                    % (error, attempt, RETRY_COUNT, wait),
                    file=sys.stderr,
                )
                time.sleep(wait)
                continue
            break
    raise last_error


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "Aufruf: resolve_asset.py <tag> <asset-name> [repo]",
            file=sys.stderr,
        )
        return 2

    tag = sys.argv[1]
    asset_name = sys.argv[2]
    repo = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_REPO

    url = "%s/repos/%s/releases/tags/%s" % (API_ROOT, repo, tag)
    try:
        release = _fetch(url)
    except Exception as error:  # noqa: BLE001 – Fehler sollen lesbar sein
        print("FEHLER: Release %s nicht abrufbar: %s" % (tag, error), file=sys.stderr)
        return 1

    assets = release.get("assets", [])
    for asset in assets:
        if asset.get("name") == asset_name:
            print(asset["id"])
            return 0

    # Nicht gefunden: alle verfuegbaren Namen ausgeben, damit die
    # Ursache auf einen Blick erkennbar ist.
    print(
        "FEHLER: Asset '%s' existiert im Release '%s' nicht." % (asset_name, tag),
        file=sys.stderr,
    )
    print("Verfuegbare Assets:", file=sys.stderr)
    for asset in assets:
        print("  %s" % asset.get("name"), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
