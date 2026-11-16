/**
 * Exportiert den bestehenden JS-Lerncontent in ein JSON-Sidecar.
 *
 * Zweck: Der Content (src/data1.js … data3.js) bleibt die单一 Quelle der
 * Wahrheit für alle Lerninhalte. Dieses Skript liest ihn über Node ein und
 * schreibt eine normalisierte JSON-Datei, die Godot zur Laufzeit liest.
 *
 * Damit bleibt der Bestandsschutz gewahrt (kein doppeltes Pflegen des
 * Contents) und Godot bekommt trotzdem ein robustes, typisiertes Format.
 *
 * Aufruf:  node tools/export_content.cjs
 */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
global.window = {};
const FIN = require(path.join(root, 'src/engine.js'));
global.FIN = FIN;

for (const file of ['src/data1.js', 'src/data2.js', 'src/data3.js']) {
  eval(fs.readFileSync(path.join(root, file), 'utf8'));
}

const parts = [
  ...(window.GAMEDATA_PART1 || []),
  ...(window.GAMEDATA_PART2 || []),
  ...(window.GAMEDATA_PART3 || []),
];

// Trainer-Generatoren enthalten Funktionen -> nur die "seed"-Struktur sichern.
// Der Generator selbst wird pro Welt deterministisch aus den festen Werten
// rekonstruiert (siehe godot/src/learning/trainer.gd).
const worlds = parts.map((w) => ({
  id: w.id,
  no: w.no,
  side: w.side,
  color: w.color,
  icon: w.icon,
  title: w.title,
  tag: w.tag,
  sources: w.sources,
  briefing: w.briefing,
  concept: {
    intro: w.concept.intro,
    // Der Export muss verlustfrei sein: das Legacy-Format kennt zwei
    // Strukturvarianten.
    //
    //  - "sort" speichert Kategorien und Karten in `rounds[]`
    //    (je Runde eigener Kategoriensatz mit `cards[]`).
    //  - "order" und "quiz" speichern ihre Elemente direkt in
    //    `items[]` bzw. `questions[]`.
    //
    // Früher wurden nur die Top-Level-Felder übernommen; damit sind
    // alle Zuordnungsaufgaben (12 sort-Items) ohne Inhalt in Godot
    // gelandet. `rounds` wird jetzt vollständig mit exportiert und
    // zusätzlich auf die flache Form normalisiert, damit das
    // Datenmodell ConceptItem beide Varianten abdecken kann.
    items: w.concept.items.map((it) => ({
      kind: it.kind,
      title: it.title,
      intro: it.intro || '',
      // `prompt` und `solution` stehen bei den order-Items; ohne sie
      // ginge die Aufgabenstellung verloren.
      prompt: it.prompt || '',
      solution: it.solution || '',
      categories: it.categories || [],
      items: it.items || [],
      questions: it.questions || [],
      rounds: (it.rounds || []).map((r) => ({
        title: r.title || '',
        categories: r.categories || [],
        cards: (r.cards || []).map((c) => ({
          id: c.id || '',
          text: c.text || '',
          cat: c.cat || '',
          why: c.why || '',
        })),
      })),
    })),
  },
  lab: {
    intro: w.lab.intro,
    tasks: w.lab.tasks,
  },
  // Feste Parameter des prozeduralen Trainers, damit der GDScript-Port
  // dieselben Werte erzeugt wie der JS-Generator.
  trainer: extractTrainerParams(w),
}));

function extractTrainerParams(world) {
  // Der JS-Generator nutzt Math.random() fuer some Welten; fuer die
  // uebrigen sind die Werte deterministisch. Wir erfassen die Grundparameter
  // durch mehrfaches Generieren und Vergleichen der Streuung.
  const samples = [];
  for (let i = 0; i < 40; i++) {
    try {
      samples.push(world.trainer.gen());
    } catch (e) {
      break;
    }
  }
  if (!samples.length) return null;

  // Konstante Felder (in allen Samples identisch) extrahieren.
  const constant = {};
  const first = samples[0];
  for (const key of ['prompt', 'given']) {
    if (typeof first[key] === 'string') {
      const same = samples.every((s) => s[key] === first[key]);
      constant[key] = same ? first[key] : null;
    }
  }
  const fields = first.fields.map((f, idx) => {
    const same = samples.every((s) => s.fields[idx] && s.fields[idx].ans === f.ans);
    return {
      key: f.key,
      label: f.label,
      unit: f.unit || '',
      tol: f.tol ?? 0.02,
      constant: same,
      ans: same ? f.ans : null,
    };
  });
  return { constant, fields };
}

const out = { version: 1, generated_from: 'src/data1.js,src/data2.js,src/data3.js', worlds };
const target = path.join(root, 'godot/content/worlds.json');
fs.mkdirSync(path.dirname(target), { recursive: true });
fs.writeFileSync(target, JSON.stringify(out, null, 1), 'utf8');
console.log(`geschrieben: ${target} (${worlds.length} Welten, ${(fs.statSync(target).size / 1024).toFixed(1)} KB)`);
