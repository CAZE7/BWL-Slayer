# CI-Diagnose

Dieses Verzeichnis enthält die Ausgabe des letzten fehlgeschlagenen
CI-Laufs. Der Workflow schreibt sie bei einem Fehlschlag automatisch
in den Branch, weil Artefakte und Job-Logs aus manchen Netzen nicht
abrufbar sind.

- `last-run.md` – Testschritt, Testausgabe und JSON-Bericht

Die Datei wird bei jedem fehlgeschlagenen Lauf überschrieben.
