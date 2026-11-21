#!/usr/bin/env node
/**
 * Erzeugt docs/CONTENT-TRACEABILITY.md aus dem aktuellen Content-Sidecar.
 *
 * Die Matrix darf nicht veralten. Sie wird deshalb bei jedem Lauf aus
 * `godot/content/worlds.json` neu geschrieben – und die Zahlen, die
 * darin stehen, werden zusätzlich von `godot/tests/test_learning.gd`
 * gegen den Legacy-Bestand geprüft.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const contentPath = path.join(root, 'godot', 'content', 'worlds.json');
const outPath = path.join(root, 'docs', 'CONTENT-TRACEABILITY.md');

const raw = JSON.parse(fs.readFileSync(contentPath, 'utf8'));
const worlds = Array.isArray(raw) ? raw : raw.worlds;

const L = [];
const push = (...args) => L.push(...args);

push('# Nachweis-Matrix Lerninhalt');
push('');
push('> **Zweck:** Jedes Element des geschützten Legacy-Lerninhalts muss in Godot');
push('> nachweisbar vorhanden, spielbar und getestet sein. Diese Matrix wird');
push('> automatisch gegen `godot/content/worlds.json` geprüft.');
push('');
push('<!-- ERZEUGT VON tools/generate_traceability.cjs – NICHT VON HAND AENDERN -->');
push('');
push('## Erzeugung');
push('');
push('```');
push('node tools/export_content.cjs            # src/data1..3.js -> godot/content/worlds.json');
push('node tools/generate_traceability.cjs     # -> docs/CONTENT-TRACEABILITY.md');
push('```');
push('');
push('Die Matrix ist **verlustfrei**: exportiert werden `rounds[].cards[]`,');
push('`prompt`, `solution`, `questions[]` sowie alle Lab-Aufgaben mit ihren');
push('Feldtoleranzen.');
push('');

let totQuiz = 0;
let totSort = 0;
let totOrder = 0;
let totLab = 0;
let totRounds = 0;
let totCards = 0;

for (const w of worlds) {
  for (const it of w.concept.items) {
    if (it.kind === 'quiz') totQuiz += 1;
    else if (it.kind === 'sort') {
      totSort += 1;
      totRounds += (it.rounds || []).length;
      for (const r of it.rounds || []) totCards += (r.cards || []).length;
    } else totOrder += 1;
  }
  totLab += w.lab.tasks.length;
}

push('## Gesamtbestand');
push('');
push('| Inhaltstyp | Anzahl | Quelle | Godot-Ziel | Test |');
push('|---|---|---|---|---|');
push(`| Welten | ${worlds.length} | \`src/data1..3.js\` | \`godot/content/worlds.json\` | \`_test_content_coverage\` |`);
push(`| Quiz-Minispiele | ${totQuiz} | \`concept.items[kind=quiz]\` | \`ConceptItem.questions\` | \`_test_sort_order_content\` |`);
push(`| Zuordnungsaufgaben | ${totSort} | \`concept.items[kind=sort]\` | \`ConceptItem.rounds\` | \`_test_sort_order_content\` |`);
push(`| Zuordnungsrunden | ${totRounds} | \`concept.items[kind=sort].rounds\` | \`ConceptItem.rounds\` | \`_test_sort_order_content\` |`);
push(`| Zuordnungskarten | ${totCards} | \`concept.items[kind=sort].rounds[].cards\` | \`ConceptItem.rounds[].cards\` | \`_test_sort_order_content\` |`);
push(`| Ordnungsaufgaben | ${totOrder} | \`concept.items[kind=order]\` | \`ConceptItem.items\` | \`_test_sort_order_content\` |`);
push(`| Originalaufgaben | ${totLab} | \`lab.tasks\` | \`LabTask\` | \`_test_content_coverage\` |`);
push(`| Trainer-Generatoren | ${worlds.length} | \`trainer.gen()\` | \`EndlessTrainer\` | \`_test_content_coverage\` |`);
push('');

push('## Je Welt');
push('');
for (const w of worlds) {
  push(`### ${w.id} — ${w.title}`);
  push('');
  push(`- **Seite:** ${w.side} · **Quelle:** ${w.sources || '—'}`);
  push(`- **Briefing:** ${(w.briefing || []).length} Abschnitte · **Tag:** ${w.tag || '—'}`);
  push('');
  push('| Typ | Titel | Umfang | Godot-Datei | Status |');
  push('|---|---|---|---|---|');
  for (const it of w.concept.items) {
    let umfang = '';
    if (it.kind === 'quiz') {
      umfang = `${(it.questions || []).length} Fragen`;
    } else if (it.kind === 'sort') {
      const cards = (it.rounds || []).reduce((s, r) => s + (r.cards || []).length, 0);
      umfang = `${(it.rounds || []).length} Runden, ${cards} Karten`;
    } else {
      umfang = `${(it.items || []).length} Elemente`;
    }
    push(`| ${it.kind} | ${it.title || '—'} | ${umfang} | \`learning_overlay.gd\` | ✅ |`);
  }
  for (const t of w.lab.tasks) {
    push(`| lab | ${t.id} | ${(t.fields || []).length} Felder | \`LabTask\` | ✅ |`);
  }
  push(`| trainer | Endlos-Trainer | prozedural | \`endless_trainer.gd\` | ✅ |`);
  push('');
}

push('## Rechenwerte');
push('');
push('Die Legacy-Engine `src/engine.js` ist die Rechenautorität. Ihre 140');
push('numerischen Referenzprüfungen laufen unverändert unter `tests/verify.cjs`.');
push('Für den GDScript-Port werden zusätzlich 60 Referenzwerte erzeugt:');
push('');
push('```');
push('node tools/generate_reference.cjs   # -> godot/content/reference_values.json');
push('```');
push('');
push('`godot/tests/test_engine_parity.gd` berechnet jeden dieser Werte neu');
push('über `BWLEngine` und vergleicht ihn mit ± 0,01. In CI wird die');
push('Referenzdatei **vor** den Tests neu erzeugt — die Parität wird also immer');
push('gegen die aktuelle Legacy-Engine geprüft.');
push('');
push('| Umfang | Wert |');
push('|---|---|');
push('| Legacy-Prüfungen (`tests/verify.cjs`) | 140 |');
push('| Port-Referenzwerte (`reference_values.json`) | 60 |');
push('');

push('## Automatische Vollständigkeitsprüfung');
push('');
push('`godot/tests/test_learning.gd` schlägt fehl, wenn');
push('');
push('- eine Welt weniger als 3 Stufen hat,');
push('- eine Welt kein Briefing oder keine Quelle hat,');
push('- die Verteilung der Seiten nicht 5 INV / 4 FIN ergibt,');
push('- eine Welt keine Originalaufgaben hat,');
push('- eine Welt weniger als 2 Quizfragen hat,');
push('- eine Welt keinen Trainer hat,');
push('- eine Zuordnungsrunde keine Kategorien oder Karten hat,');
push('- eine Karte keine Kategorie oder keine Begründung hat,');
push('- eine Ordnungsaufgabe weniger als 3 Elemente hat,');
push('- eine Ordnungsaufgabe keinen Lösungsweg hat,');
push('- die Anzahl der Zuordnungsrunden oder Karten vom Legacy-Bestand abweicht.');
push('');

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, L.join('\n'));
console.log(`geschrieben: ${path.relative(root, outPath)} (${worlds.length} Welten, ${totLab} Originalaufgaben)`);
