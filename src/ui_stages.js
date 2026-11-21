/* ============================================================
   src/ui_stages.js – Konzeptspiele, Rechen-Labor, Endlos-Trainer
   ============================================================ */
(function () {
  'use strict';
  const R = window.R;
  const shuffle = (a) => a.map((x) => [Math.random(), x]).sort((p, q) => p[0] - q[0]).map((x) => x[1]);
  // Robustes Parsen: akzeptiert "9.880,20", "9880.2" und "9.880.20" mehrdeutig-tolerant
  function parseNums(s) {
    if (s == null) return [];
    const raw = String(s).trim().replace(/[€%\s]/g, '');
    if (!raw) return [];
    const cands = [];
    if (raw.includes(',')) {
      cands.push(parseFloat(raw.replace(/\./g, '').replace(',', '.'))); // deutsches Format
      cands.push(parseFloat(raw.replace(/,/g, ''))); // Komma als Tausender
    } else {
      cands.push(parseFloat(raw));
      cands.push(parseFloat(raw.replace(/\./g, ''))); // Punkte als Tausender
    }
    return cands.filter((x) => !isNaN(x));
  }

  /* ============================================================
     STAGE ROUTER
     ============================================================ */
  window.renderStage = function (id, stageNo, root) {
    const w = APP.WORLDS.find((x) => x.id === id);
    const st = APP.SAVE.worlds[id];
    root.innerHTML = `
      <div class="row" style="margin-bottom:6px">
        <button class="btn sm ghost" data-nav="world:${id}">← ${w.title}</button>
        <span class="chip" style="color:${w.color};border-color:${w.color}55">Welt ${w.no}</span>
        <span class="chip">Stufe ${stageNo} von 3</span>
      </div>
      <h1 style="margin-top:10px">${stageNo === 1 ? '🧠 ' + w.concept.title : stageNo === 2 ? '🧮 ' + w.lab.title : '♻️ ' + w.trainer.title}</h1>
      <p class="muted small" style="margin-bottom:16px">${stageNo === 1 ? w.concept.intro : stageNo === 2 ? w.lab.intro : w.trainer.intro}</p>
      <div id="game"></div>`;
    const g = document.getElementById('game');
    const finish = (ratio) => {
      const pts = Math.max(0, Math.min(10, Math.round(10 * ratio)));
      APP.award(id, stageNo - 1, pts);
      APP.stagePoints[stageNo - 1] = pts;
      g.innerHTML = `
        <div class="card center" style="padding:34px">
          <div style="font-size:44px">${ratio >= 0.99 ? '🏆' : ratio > 0 ? '✅' : '📘'}</div>
          <h2>Stufe ${stageNo} abgeschlossen</h2>
          <p class="muted">${pts} von 10 möglichen Punkten in dieser Stufe.</p>
          <div class="row" style="justify-content:center;margin-top:14px">
            <button class="btn" data-nav="stage:${id}:${stageNo}">Nochmal spielen</button>
            ${stageNo < 3 ? `<button class="btn primary" data-nav="stage:${id}:${stageNo + 1}">Weiter zu Stufe ${stageNo + 1} →</button>` : `<button class="btn primary" data-nav="world:${id}">Zurück zur Welt</button>`}
          </div>
        </div>`;
      const bar = document.querySelector('.topbar');
      if (bar && window.buildTopbar) bar.outerHTML = window.buildTopbar();
      window.scrollTo({ top: 0, behavior: 'smooth' });
    };
    if (stageNo === 1) runConcept(w, g, finish);
    else if (stageNo === 2) runLab(w, g, finish);
    else runTrainer(w, g, finish);
  };

  /* ============================================================
     STUFE 1 – KONZEPTSPIELE
     ============================================================ */
  function runConcept(world, mount, done) {
    const items = world.concept.items;
    let idx = 0;
    let correct = 0;
    let total = 0;

    function countUnits(it) {
      if (it.kind === 'quiz') return it.questions.length;
      if (it.kind === 'order') return 1;
      return (it.rounds || []).reduce((a, r) => a + r.cards.length, 0);
    }
    const totalAll = items.reduce((a, it) => a + countUnits(it), 0);

    function step() {
      if (idx >= items.length) return done(totalAll ? correct / totalAll : 1);
      const it = items[idx];
      const n = countUnits(it);
      const head = `
        <div class="row" style="justify-content:space-between;margin-bottom:10px">
          <span class="chip">${it.title}</span>
          <span class="tiny muted">${correct} richtig · ${total} bewertet</span>
        </div>
        <div class="pbar" style="margin-bottom:16px"><i style="width:${Math.round(((idx) / items.length) * 100)}%"></i></div>`;
      mount.innerHTML = `<div class="card">${head}<div id="itembody"></div></div>`;
      const body = document.getElementById('itembody');
      const cb = (good) => {
        correct += good;
        total += n;
        idx++;
        step();
      };
      if (it.kind === 'sort') sortGame(it, body, cb);
      else if (it.kind === 'order') orderGame(it, body, cb);
      else quizGame(it, body, cb);
    }
    step();
  }

  function sortGame(item, body, cb) {
    let roundIdx = 0, cards = [], ci = 0, mistakes = 0;
    function startRound() {
      if (roundIdx >= item.rounds.length) return cb(mistakes === 0 ? 1 : 0.5);
      cards = shuffle(item.rounds[roundIdx].cards.slice());
      ci = 0;
      drawRound();
    }
    function drawRound() {
      const round = item.rounds[roundIdx];
      if (ci >= cards.length) {
        roundIdx++;
        return setTimeout(startRound, 600);
      }
      const c = cards[ci];
      window.__sortCard = c; // für automatisierte Tests
      body.innerHTML = `
        <div class="tiny muted" style="margin-bottom:8px">${round.title} · Karte ${ci + 1}/${cards.length}</div>
        <div class="swipe-card">${c.text}</div>
        <div class="sort-btns">
          ${round.categories.map((cat) => `<button class="sort-btn" data-cat="${cat.id}">${cat.label}</button>`).join('')}
        </div>
        <div id="fb"></div>`;
      body.querySelectorAll('.sort-btn').forEach((btn) => {
        btn.onclick = () => {
          const ok = btn.getAttribute('data-cat') === c.cat;
          if (!ok) mistakes++;
          const label = round.categories.find((x) => x.id === c.cat).label;
          body.querySelectorAll('.sort-btn').forEach((b) => {
            b.disabled = true;
            if (b.getAttribute('data-cat') === c.cat) b.classList.add('correct');
            else if (b === btn) b.classList.add('wrong');
          });
          document.getElementById('fb').innerHTML = `
            <div class="feedback ${ok ? 'good' : 'warn'}">
              <b>${ok ? 'Sauber!' : 'Nicht ganz – richtig ist: ' + label}</b>
              ${c.why}
              ${ok ? '' : '<div class="coach"><span class="avatar">🧑‍💼</span><span>Merke dir diese Zuordnung – sie taucht in der Klausur als Aussage-Wahr/Falsch-Aufgabe auf.</span></div>'}
            </div>`;
          ci++;
          setTimeout(drawRound, ok ? 750 : 1600);
        };
      });
    }
    startRound();
  }

  function orderGame(item, body, cb) {
    const pool = shuffle(item.items.slice());
    const seq = [];
    function draw() {
      body.innerHTML = `
        <p class="prompt">${item.prompt}</p>
        <div style="margin-bottom:12px">${item.items
          .map((_, i) => `<div class="order-slot ${seq[i] ? 'filled' : ''}">${seq[i] ? `${i + 1}. ${seq[i].text}` : `${i + 1}. …`}</div>`)
          .join('')}</div>
        <div class="order-pool">
          ${pool.filter((p) => !seq.includes(p)).map((p) => `<button class="order-item" data-id="${p.id}">${p.text}</button>`).join('')}
        </div>
        <div class="row" style="margin-top:12px">
          <button class="btn sm ghost" id="reset"> Zurücksetzen</button>
          <button class="btn primary sm" id="check" ${seq.length === item.items.length ? '' : 'disabled'}>Prüfen</button>
        </div>
        <div id="fb"></div>`;
      body.querySelectorAll('.order-item').forEach((b) => (b.onclick = () => {
        seq.push(pool.find((p) => p.id === b.getAttribute('data-id')));
        draw();
      }));
      document.getElementById('reset').onclick = () => { seq.length = 0; draw(); };
      document.getElementById('check').onclick = () => {
        const ok = seq.every((s, i) => s.id === item.items[i].id);
        document.getElementById('fb').innerHTML = `
          <div class="feedback ${ok ? 'good' : 'bad'}">
            <b>${ok ? 'Perfekt – die Reihenfolge sitzt!' : 'Noch nicht die richtige Reihenfolge'}</b>
            ${item.solution}
          </div>
          <div class="row" style="margin-top:12px"><button class="btn primary sm" id="cont">Weiter →</button></div>`;
        document.getElementById('cont').onclick = () => cb(ok ? 1 : 0);
      };
    }
    draw();
  }

  function quizGame(item, body, cb) {
    let qi = 0, wrong = 0;
    function draw() {
      if (qi >= item.questions.length) return cb(wrong === 0 ? 1 : 0.6);
      const q = item.questions[qi];
      window.__quizQ = q; // für automatisierte Tests
      body.innerHTML = `
        <div class="tiny muted" style="margin-bottom:8px">Frage ${qi + 1}/${item.questions.length}</div>
        <p class="prompt"><b>${q.q}</b></p>
        <div class="opt-list">${q.options.map((o, i) => `<button class="opt" data-i="${i}">${o}</button>`).join('')}</div>
        <div id="fb"></div>`;
      body.querySelectorAll('.opt').forEach((b) => {
        b.onclick = () => {
          const i = parseInt(b.getAttribute('data-i'), 10);
          const ok = i === q.a;
          if (!ok) wrong++;
          body.querySelectorAll('.opt').forEach((x) => {
            x.disabled = true;
            if (parseInt(x.getAttribute('data-i'), 10) === q.a) x.classList.add('correct');
            else if (x === b) x.classList.add('wrong');
          });
          document.getElementById('fb').innerHTML = `
            <div class="feedback ${ok ? 'good' : 'warn'}">
              <b>${ok ? 'Richtig' : 'Knapp daneben'}</b>${q.why}
            </div>
            <div class="row" style="margin-top:12px"><button class="btn primary sm" id="next">${qi + 1 === item.questions.length ? 'Weiter →' : 'Nächste Frage →'}</button></div>`;
          document.getElementById('next').onclick = () => { qi++; draw(); };
        };
      });
    }
    draw();
  }

  /* ============================================================
     STUFE 2 – RECHEN-LABOR
     ============================================================ */
  function checkField(f, raw) {
    if (f.type === 'choice') return { ok: raw === f.ans };
    const vals = parseNums(raw);
    if (!vals.length) return { ok: false, empty: true };
    const tol = f.tol != null ? f.tol : Math.max(0.02, Math.abs(f.ans) * 0.003);
    const ok = vals.some((v) => Math.abs(v - f.ans) <= tol);
    let trap = null;
    if (!ok && f.traps) {
      for (const t of f.traps) {
        const tt = t.tol != null ? t.tol : Math.max(0.02, Math.abs(t.v) * 0.003);
        if (vals.some((v) => Math.abs(v - t.v) <= tt)) { trap = t.msg; break; }
      }
    }
    return { ok, trap, value: vals[0] };
  }

  function fieldHTML(f, tid) {
    const id = tid + '_' + f.key;
    if (f.type === 'choice') {
      return `<div style="margin-bottom:12px">
        <div class="small" style="margin-bottom:6px">${f.label}</div>
        <select id="${id}" data-key="${f.key}">
          <option value="">– bitte wählen –</option>
          ${f.options.map((o) => `<option>${o}</option>`).join('')}
        </select>
      </div>`;
    }
    return `<div class="field-row">
      <label for="${id}">${f.label}${f.hint ? ` <span class="tiny muted">(${f.hint})</span>` : ''}</label>
      <div style="display:flex;align-items:center"><input type="text" inputmode="decimal" id="${id}" data-key="${f.key}" placeholder="…" autocomplete="off"><span class="unit">${f.unit || ''}</span></div>
    </div>`;
  }

  function runLab(world, mount, done) {
    const tasks = world.lab.tasks;
    const solved = new Set();
    const helped = new Set();
    let showAll = false;

    function taskCard(t) {
      const done1 = solved.has(t.id);
      return `<div class="card" id="task_${t.id}" style="${done1 ? 'border-color:rgba(52,211,153,.4)' : ''}">
        <div class="row" style="justify-content:space-between;margin-bottom:8px">
          <span class="chip ${done1 ? 'mint' : ''}">${done1 ? '✓ gelöst' : 'Aufgabe'}</span>
          <button class="btn sm ghost" data-solution="${t.id}">Lösung zeigen</button>
        </div>
        <p class="prompt">${t.prompt}</p>
        ${t.given ? `<div class="given">${t.given}</div>` : ''}
        <div id="fields_${t.id}">${t.fields.map((f) => fieldHTML(f, t.id)).join('')}</div>
        <div class="row" style="margin-top:6px">
          <button class="btn primary sm" data-check="${t.id}">Prüfen</button>
        </div>
        <div id="fb_${t.id}"></div>
      </div>`;
    }

    function draw() {
      mount.innerHTML = `
        <div class="row" style="justify-content:space-between;margin-bottom:12px">
          <span class="chip mint">${solved.size} / ${tasks.length} Aufgaben gelöst</span>
          <span class="tiny muted">Punkte: ${Math.round(10 * Math.max(0, solved.size - helped.size) / tasks.length)} / 10</span>
        </div>
        <div class="pbar" style="margin-bottom:16px"><i style="width:${(solved.size / tasks.length) * 100}%"></i></div>
        ${tasks.map(taskCard).join('')}
        <div class="row" style="margin-top:16px">
          <button class="btn" id="finishLab" ${solved.size === tasks.length ? '' : 'disabled'}>Stufe abschließen</button>
          <span class="tiny muted">${solved.size === tasks.length ? 'Alle Aufgaben bearbeitet.' : 'Löse alle Aufgaben, um abzuschließen (Lösung zeigen zählt als bearbeitet, gibt aber keine Punkte).'}</span>
        </div>
        <p class="tiny muted" style="margin-top:14px">Eingabe-Hinweis: Dezimaltrennzeichen ist das Komma (oder der Punkt) – Tausenderpunkte werden ebenfalls toleriert. Beträge ohne Einheit in der angegebenen Einheit eingeben.</p>`;

      mount.querySelectorAll('[data-check]').forEach((btn) => {
        btn.onclick = () => {
          const t = tasks.find((x) => x.id === btn.getAttribute('data-check'));
          let allOk = true;
          const coach = [];
          t.fields.forEach((f) => {
            const input = document.getElementById(t.id + '_' + f.key);
            const res = checkField(f, input.value);
            input.classList.remove('ok', 'bad');
            if (res.ok) input.classList.add('ok');
            else if (input.value) {
              input.classList.add('bad');
              allOk = false;
              coach.push(res.trap || `„${f.label}“ stimmt noch nicht. ${f.hint ? 'Tipp: ' + f.hint : 'Rechne den Schritt einzeln nach.'}`);
            } else allOk = false;
          });
          const fb = document.getElementById('fb_' + t.id);
          if (allOk) {
            solved.add(t.id);
            fb.innerHTML = `<div class="feedback good"><b>Alle Werte korrekt 🎯</b>${t.solution}</div>`;
            mount.querySelectorAll('[data-check="' + t.id + '"]').forEach((b) => (b.disabled = true));
          } else {
            fb.innerHTML = `<div class="feedback warn"><b>Fast – die Engine hat ${coach.length} Stelle(n) geprüft</b>
              ${coach.map((c) => `<div class="coach"><span class="avatar">🧑‍💼</span><span>${c}</span></div>`).join('')}</div>`;
          }
          // Zähler aktualisieren ohne Neuaufbau (Fokusverlust vermeiden)
          const chip = mount.querySelector('.chip.mint');
          if (chip) chip.textContent = `${solved.size} / ${tasks.length} Aufgaben gelöst`;
          const pbar = mount.querySelector('.pbar > i');
          if (pbar) pbar.style.width = (solved.size / tasks.length) * 100 + '%';
          const fin = document.getElementById('finishLab');
          if (fin) fin.disabled = solved.size !== tasks.length;
        };
      });

      mount.querySelectorAll('[data-solution]').forEach((btn) => {
        btn.onclick = () => {
          const t = tasks.find((x) => x.id === btn.getAttribute('data-solution'));
          helped.add(t.id);
          const fb = document.getElementById('fb_' + t.id);
          fb.innerHTML = `<div class="feedback bad"><b>Musterlösung</b>${t.solution}
            <div class="row" style="margin-top:10px"><button class="btn sm" id="adopt_${t.id}">Als bearbeitet markieren</button></div></div>`;
          document.getElementById('adopt_' + t.id).onclick = () => {
            solved.add(t.id);
            draw();
          };
        };
      });

      const fin = document.getElementById('finishLab');
      if (fin) fin.onclick = () => {
        const ratio = Math.max(0, solved.size - helped.size) / tasks.length;
        done(ratio);
      };
    }
    draw();
  }

  /* ============================================================
     STUFE 3 – ENDLOS-TRAINER
     ============================================================ */
  function runTrainer(world, mount, done) {
    const TARGET = 5;
    let streak = 0, fails = 0, current = null;

    function draw() {
      current = world.trainer.gen();
      window.__trainerTask = current; // für automatisierte Tests
      mount.innerHTML = `
        <div class="row" style="justify-content:space-between;margin-bottom:12px">
          <span class="chip amber">🔥 Serie: ${streak} / ${TARGET}</span>
          <span class="tiny muted">Fehlversuche: ${fails}</span>
        </div>
        <div class="pbar" style="margin-bottom:16px"><i style="width:${(streak / TARGET) * 100}%"></i></div>
        <div class="card">
          <p class="prompt">${current.prompt}</p>
          ${current.given ? `<div class="given">${current.given}</div>` : ''}
          <div id="tr_fields">${current.fields.map((f) => fieldHTML(f, 'tr')).join('')}</div>
          <div class="row" style="margin-top:6px"><button class="btn primary sm" id="tr_check">Prüfen</button>
          <button class="btn sm ghost" id="tr_skip">Aufgabe tauschen</button></div>
          <div id="tr_fb"></div>
        </div>`;
      document.getElementById('tr_check').onclick = () => {
        let allOk = true;
        const coach = [];
        current.fields.forEach((f) => {
          const input = document.getElementById('tr_' + f.key);
          const res = checkField(f, input.value);
          input.classList.remove('ok', 'bad');
          if (res.ok) input.classList.add('ok');
          else { allOk = false; if (input.value) { input.classList.add('bad'); coach.push(res.trap || `„${f.label}“ ist nicht korrekt.`); } }
        });
        const fb = document.getElementById('tr_fb');
        if (allOk) {
          streak++;
          APP.SAVE.streak += 1;
          if (streak >= TARGET) {
            APP.persist();
            return done(Math.max(0.4, (TARGET - fails * 0.5) / TARGET));
          }
          fb.innerHTML = `<div class="feedback good"><b>Richtig! +1 Serie</b>${current.solution}</div>`;
          document.getElementById('tr_check').disabled = true;
          setTimeout(draw, 900);
        } else {
          fails++;
          fb.innerHTML = `<div class="feedback warn"><b>Noch nicht</b>
            ${coach.map((c) => `<div class="coach"><span class="avatar">🧑‍💼</span><span>${c}</span></div>`).join('')}
            <div style="margin-top:8px">${current.solution}</div></div>
            <div class="row" style="margin-top:10px"><button class="btn sm" id="tr_next">Neue Aufgabe →</button></div>`;
          document.getElementById('tr_next').onclick = draw;
        }
      };
      document.getElementById('tr_skip').onclick = draw;
    }
    draw();
  }
})();
