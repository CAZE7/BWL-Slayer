#!/usr/bin/env python3
"""
BWL Slayer · GitHub-Release-Asset herunterladen.

Der Editor und die Export-Templates von Godot liegen als Release-Assets
im Repository ``godotengine/godot``. Ein direkter Download ueber den
Redirect-Link ist auf CI-Runnern nicht zuverlaessig, und der Weg ueber
die Asset-API ist bei kurzfristigen Stoerungen der GitHub-API
(Rate-Limit 429, 5xx) fehleranfaellig.

Dieses Tool erledigt beides in einem Schritt:

  1. Die Asset-ID wird ueber die Release-API aufgeloest.
  2. Das Asset wird ueber den Release-Asset-Endpunkt geladen.

Beide Schritte wiederholen sich bei Stoerungen mit wachsender
Wartezeit. Das haelt den Build auch dann am Laufen, wenn die GitHub-API
kurzzeitig nicht antwortet – was in der Praxis die haeufigste Ursache
fuer rote Exportlaeufe war, obwohl der Quellcode in Ordnung war.

Aufruf:
    python3 tools/download_asset.py <tag> <asset-name> <ziel-datei> [repo]

Ausgabe: die Ziel-Datei existiert und ist groesser als ``--min-size``
(Standard 1 000 000 Bytes). Bei Fehlern: Meldung auf stderr, Exit-Code 1.
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

API_ROOT = "https://api.github.com"
DEFAULT_REPO = "godotengine/godot"
RETRY_COUNT = 6
RETRY_DELAY = 5
MIN_SIZE = 1_000_000

# HTTP-Statuscodes, die auf eine voruebergehende Stoerung hindeuten.
RETRYABLE = (403, 408, 429, 500, 502, 503, 504)


def _headers(accept: str) -> dict:
    headers = {
        "Accept": accept,
        "User-Agent": "bwl-slayer-ci",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = "Bearer %s" % token
    return headers


def _sleep(attempt: int, reason: str) -> None:
    # Wachsende Wartezeit, gedeckelt: 5, 10, 15, 20, 25 Sekunden.
    wait = min(RETRY_DELAY * attempt, 30)
    print(
        "WARNUNG: %s – Versuch %d/%d, warte %ds" % (reason, attempt, RETRY_COUNT, wait),
        file=sys.stderr,
    )
    time.sleep(wait)


def _resolve_asset_id(tag: str, asset_name: str, repo: str) -> int:
    """Loest die Asset-ID ueber die Release-API auf."""
    url = "%s/repos/%s/releases/tags/%s" % (API_ROOT, repo, tag)
    last_error = None
    for attempt in range(1, RETRY_COUNT + 1):
        request = urllib.request.Request(url, headers=_headers("application/vnd.github+json"))
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                release = json.loads(response.read().decode("utf-8"))
            break
        except urllib.error.HTTPError as error:
            last_error = error
            if error.code in RETRYABLE and attempt < RETRY_COUNT:
                _sleep(attempt, "HTTP %s bei der Asset-Aufloesung" % error.code)
                continue
            raise
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            last_error = error
            if attempt < RETRY_COUNT:
                _sleep(attempt, "Netzwerkfehler bei der Asset-Aufloesung (%s)" % error)
                continue
            raise
    else:
        raise last_error

    for asset in release.get("assets", []):
        if asset.get("name") == asset_name:
            return int(asset["id"])

    names = [str(a.get("name")) for a in release.get("assets", [])]
    raise SystemExit(
        "FEHLER: Asset '%s' existiert im Release '%s' nicht.\n"
        "Verfuegbare Assets:\n  %s"
        % (asset_name, tag, "\n  ".join(names))
    )


def _download(asset_id: int, target: str, repo: str, min_size: int) -> int:
    """Laedt das Asset herunter und legt es unter ``target`` ab."""
    url = "%s/repos/%s/releases/assets/%d" % (API_ROOT, repo, asset_id)
    temporary = target + ".teil"
    last_error = None
    for attempt in range(1, RETRY_COUNT + 1):
        request = urllib.request.Request(
            url, headers=_headers("application/octet-stream")
        )
        try:
            with urllib.request.urlopen(request, timeout=300) as response:
                with open(temporary, "wb") as handle:
                    while True:
                        chunk = response.read(1024 * 1024)
                        if not chunk:
                            break
                        handle.write(chunk)
            size = os.path.getsize(temporary)
            if size < min_size:
                raise OSError(
                    "Download unvollstaendig (%d Bytes, erwartet mindestens %d)"
                    % (size, min_size)
                )
            os.replace(temporary, target)
            return size
        except urllib.error.HTTPError as error:
            last_error = error
            if error.code in RETRYABLE and attempt < RETRY_COUNT:
                _sleep(attempt, "HTTP %s beim Asset-Download" % error.code)
                continue
            break
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            last_error = error
            if attempt < RETRY_COUNT:
                _sleep(attempt, "Netzwerkfehler beim Asset-Download (%s)" % error)
                continue
            break
        finally:
            if os.path.exists(temporary) and os.path.getsize(temporary) < min_size:
                try:
                    os.remove(temporary)
                except OSError:
                    pass

    raise SystemExit("FEHLER: Download von Asset %d fehlgeschlagen: %s" % (asset_id, last_error))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tag")
    parser.add_argument("asset_name")
    parser.add_argument("target")
    parser.add_argument("repo", nargs="?", default=DEFAULT_REPO)
    parser.add_argument("--min-size", type=int, default=MIN_SIZE)
    args = parser.parse_args()

    asset_id = _resolve_asset_id(args.tag, args.asset_name, args.repo)
    print("Asset-ID: %d" % asset_id)

    size = _download(asset_id, args.target, args.repo, args.min_size)
    print("Groesse: %d Bytes" % size)
    print("Gespeichert unter: %s" % args.target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
