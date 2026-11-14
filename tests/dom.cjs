/* Smoke-Test der Single-File-App in jsdom */
const fs = require('fs');
const path = require('path');
const { JSDOM } = require('/tmp/node_modules/jsdom');

const html = fs.readFileSync(path.join(__dirname, '../../delizioso-cfo-simulator.html'), 'utf8');
const dom = new JSDOM(html, { runScripts: 'dangerously', url: 'https://example.org/', pretendToBeVisual: true });
const { window } = dom;
const doc = window.document;

let fails = 0;
const ok = (label, cond) => { if (!cond) { fails++; console.log('FAIL ' + label); } else console.log('OK   ' + label); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const APP = window.APP;
  ok('APP initialisiert', !!APP);
  ok('8 Welten geladen', APP.WORLDS.length === 8);
  ok('Topbar gerendert', !!doc.querySelector('.topbar'));
  ok('8 Weltkarten', doc.querySelectorAll('.world-card').length === 8);
  ok('ENGINE global', typeof window.FIN.npv === 'function');

  // --- Simulatoren ---
  for (const id of ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8']) {
    if (!window.SIMULATORS[id]) { console.log('     (kein Simulator für ' + id + ')'); continue; }
    APP.go({ name: 'sim', id });
    ok('Simulator ' + id + ' rendert', doc.querySelector('#simbody').innerHTML.length > 500);
  }

  // --- Weltansicht ---
  APP.go({ name: 'world', id: 'W2' });
  ok('Weltansicht 3 Stufen', doc.querySelectorAll('.stage-row').length === 3);

  // --- Rechen-Labore aller Welten automatisch korrekt lösen ---
  for (const w of APP.WORLDS) {
    APP.go({ name: 'stage', id: w.id, stage: 2 });
    const tasks = w.lab.tasks;
    for (const t of tasks) {
      t.fields.forEach((f) => {
        const el = doc.getElementById(t.id + '_' + f.key);
        if (!el) { fails++; console.log('FAIL Feld fehlt: ' + t.id + '/' + f.key); return; }
        if (f.type === 'choice') el.value = f.ans;
        else el.value = String(f.ans).replace('.', ',');
      });
      doc.querySelector('[data-check="' + t.id + '"]').click();
    }
    const chip = doc.querySelector('.chip.mint');
    const solved = doc.querySelectorAll('.feedback.good').length;
    ok('Labor ' + w.id + ': alle ' + tasks.length + ' Aufgaben lösen (' + solved + ')', solved === tasks.length);
    const fin = doc.getElementById('finishLab');
    ok('Labor ' + w.id + ': Abschluss freigeschaltet', fin && !fin.disabled);
    if (fin) fin.click();
    ok('Labor ' + w.id + ': Stufe 2 als erledigt markiert', APP.SAVE.worlds[w.id].stages[1] === true);
  }

  // --- Konzeptspiele aller Welten automatisch durchspielen ---
  for (const w of APP.WORLDS) {
    APP.go({ name: 'stage', id: w.id, stage: 1 });
    let guard = 0;
    while (guard++ < 500 && !doc.body.textContent.includes('Stufe 1 abgeschlossen')) {
      const next = doc.getElementById('next');
      if (next) { next.click(); await sleep(5); continue; }
      const cont = doc.getElementById('cont');
      if (cont) { cont.click(); await sleep(5); continue; }
      const chk = doc.getElementById('check');
      if (chk && !chk.disabled) { chk.click(); await sleep(20); continue; }
      const quizQ = window.__quizQ;
      const opt = doc.querySelector('.opt:not([disabled])');
      if (opt) { opt.click(); await sleep(5); continue; }
      const card = window.__sortCard;
      const sortBtn = doc.querySelector('.sort-btn:not([disabled])');
      if (sortBtn && card) {
        const btn = doc.querySelector('.sort-btn[data-cat="' + card.cat + '"]');
        (btn || sortBtn).click();
        await sleep(40);
        continue;
      }
      const orderItem = doc.querySelector('.order-item');
      if (orderItem) {
        const pool = Array.from(doc.querySelectorAll('.order-item'));
        const item = w.concept.items.find((x) => x.kind === 'order');
        if (item) {
          const placed = doc.querySelectorAll('.order-slot.filled').length;
          const target = item.items[placed];
          const b = pool.find((p) => p.textContent.trim() === target.text);
          (b || pool[0]).click();
          await sleep(5);
          continue;
        }
      }
      await sleep(60);
    }
    ok('Konzeptspiel ' + w.id + ' abgeschlossen', doc.body.textContent.includes('Stufe 1 abgeschlossen'));
  }

  // --- Endlos-Trainer: pro Welt 5 richtige Antworten ---
  for (const w of APP.WORLDS) {
    APP.go({ name: 'stage', id: w.id, stage: 3 });
    let guard = 0;
    while (guard++ < 40 && !doc.body.textContent.includes('Stufe 3 abgeschlossen')) {
      const task = window.__trainerTask;
      if (!task) break;
      task.fields.forEach((f) => {
        const el = doc.getElementById('tr_' + f.key);
        if (!el) return;
        if (f.type === 'choice') el.value = f.ans;
        else el.value = String(f.ans).replace('.', ',');
      });
      const btn = doc.getElementById('tr_check');
      if (!btn) break;
      const before = window.__trainerTask;
      btn.click();
      await sleep(40);
      const nb = doc.getElementById('tr_next');
      if (nb) { ok('Trainer ' + w.id + ': Fallback greift', true); nb.click(); await sleep(30); }
      else { await sleep(950); } // richtige Antwort -> nächste Aufgabe nach 900 ms
    }
    ok('Trainer ' + w.id + ' abgeschlossen', doc.body.textContent.includes('Stufe 3 abgeschlossen'));
  }

  // --- Probeklausur ---
  APP.go({ name: 'exam' });
  const cards = doc.querySelectorAll('#examitems .card');
  ok('Probeklausur 20 Aufgaben', cards.length === 20);
  doc.getElementById('submitExam').click();
  await sleep(30);
  ok('Auswertung erzeugt', /\/ 120 Punkte/.test(doc.body.textContent));

  // --- Neustart / Persistenz ---
  const raw = window.localStorage.getItem('delizioso-cfo-savegame-v1');
  ok('Savegame geschrieben', !!raw && raw.length > 50);

  console.log(fails === 0 ? '\nDOM-SMOKE-TEST: ALLES GRÜN\n' : `\n${fails} FEHLER\n`);
  process.exit(fails ? 1 : 0);
})().catch((e) => { console.error('CRASH', e); process.exit(1); });
