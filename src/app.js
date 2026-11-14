/* ============================================================
   src/app.js – Probeklausur (Bosskampf) & Init
   ============================================================ */
(function () {
  'use strict';
  const R = window.R;
  const parseNum = (s) => {
    if (s == null) return NaN;
    const raw = String(s).trim().replace(/[€%\s]/g, '');
    if (!raw) return NaN;
    const cands = [];
    if (raw.includes(',')) {
      cands.push(parseFloat(raw.replace(/\./g, '').replace(',', '.')));
      cands.push(parseFloat(raw.replace(/,/g, '')));
    } else {
      cands.push(parseFloat(raw));
      cands.push(parseFloat(raw.replace(/\./g, '')));
    }
    return cands.filter((x) => !isNaN(x));
  };

  function shuffle(a) {
    return a.map((x) => [Math.random(), x]).sort((p, q) => p[0] - q[0]).map((x) => x[1]);
  }

  /* ---------- Klausur zusammenbauen ---------- */
  function buildExam() {
    const sides = {
      INV: APP.WORLDS.filter((w) => w.side === 'INV').map((w) => w.id),
      FIN: APP.WORLDS.filter((w) => w.side === 'FIN').map((w) => w.id)
    };
    const out = [];
    Object.keys(sides).forEach((side) => {
      const pool = [];
      sides[side].forEach((id) => {
        const w = APP.WORLDS.find((x) => x.id === id);
        // MC-Fragen aus den Konzeptspielen
        w.concept.items.forEach((it) => {
          if (it.kind === 'quiz') {
            it.questions.forEach((q) => pool.push({
              side: side, world: id, kind: 'mc',
              text: q.q, options: q.options, a: q.a, why: q.why
            }));
          }
        });
        // generierte Rechenaufgabe
        try {
          const g = w.trainer.gen();
          const f = g.fields[0];
          pool.push({
            side: side, world: id, kind: 'num',
            text: g.prompt + (g.given ? `<div class="given" style="margin-top:8px">${g.given}</div>` : ''),
            label: f.label, ans: f.ans, unit: f.unit, tol: f.tol, type: f.type, options: f.options,
            why: 'Richtig sind hier ' + (f.type === 'choice' ? f.ans : R(f.ans) + ' ' + (f.unit || '')) + '.'
          });
        } catch (e) {}
      });
      const picked = shuffle(pool).slice(0, 10);
      picked.forEach((p) => out.push(p));
    });
    return shuffle(out).sort((a, b) => (a.side === b.side ? 0 : a.side === 'INV' ? -1 : 1));
  }

  /* ---------- Prüfungs-View ---------- */
  window.renderExam = function (root) {
    const items = buildExam();
    const perItem = 120 / items.length; // = 6
    let remaining = 120 * 60;
    let submitted = false;

    root.innerHTML = `
      <div class="row" style="justify-content:space-between;margin-bottom:6px">
        <button class="btn sm ghost" data-nav="home">← Cockpit</button>
        <span class="chip amber">Investition 60 P. · Finanzierung 60 P.</span>
      </div>
      <div class="row" style="justify-content:space-between;align-items:flex-end;margin-top:10px">
        <div>
          <h1 style="margin:0">🎯 Probeklausur · Investition &amp; Finanzierung 1</h1>
          <p class="muted small" style="margin:6px 0 0">${items.length} Aufgaben · je ${perItem} Punkte · Gesamtpunktzahl 120</p>
        </div>
        <div style="text-align:right">
          <div class="exam-timer" id="timer">02:00:00</div>
          <div class="tiny muted">Restzeit</div>
        </div>
      </div>
      <div class="pbar" style="margin:14px 0 18px"><i id="epbar" style="width:0%"></i></div>
      <div id="examitems">
        ${items.map((it, i) => `
          <div class="card" style="margin-bottom:12px" id="ex_${i}">
            <div class="row" style="justify-content:space-between;margin-bottom:8px">
              <span class="chip">Aufgabe ${i + 1} · ${it.side === 'INV' ? 'Investition' : 'Finanzierung'}</span>
              <span class="tiny muted">${perItem} Punkte</span>
            </div>
            <p class="prompt">${it.text}</p>
            ${it.kind === 'mc'
              ? `<div class="opt-list">${it.options.map((o, k) => `<button class="opt" data-q="${i}" data-o="${k}">${o}</button>`).join('')}</div>`
              : `<div class="field-row"><label>${it.label}</label><div style="display:flex;align-items:center">
                  ${it.type === 'choice'
                    ? `<select data-q="${i}" data-key="v">${['', ...it.options].map((o) => `<option>${o}</option>`).join('')}</select>`
                    : `<input type="text" inputmode="decimal" data-q="${i}" data-key="v" autocomplete="off"><span class="unit">${it.unit || ''}</span>`}
                </div></div>`}
          </div>`).join('')}
      </div>
      <div class="row" style="justify-content:center;margin-top:8px">
        <button class="btn primary" id="submitExam">Prüfung abgeben</button>
      </div>`;

    const answers = {};
    root.querySelectorAll('[data-o]').forEach((b) => {
      b.onclick = () => {
        const qi = b.getAttribute('data-q');
        answers[qi] = parseInt(b.getAttribute('data-o'), 10);
        root.querySelectorAll(`[data-o="${qi}"]`).forEach((x) => x.classList.remove('correct'));
        b.classList.add('correct');
        updateBar();
      };
    });
    root.querySelectorAll('[data-key="v"]').forEach((inp) => {
      inp.oninput = () => { answers[inp.getAttribute('data-q')] = inp.value; updateBar(); };
      inp.onchange = inp.oninput;
    });
    function updateBar() {
      const answered = Object.keys(answers).filter((k) => answers[k] !== '' && answers[k] != null).length;
      const bar = document.getElementById('epbar');
      if (bar) bar.style.width = (answered / items.length) * 100 + '%';
    }

    const timerEl = document.getElementById('timer');
    const tick = setInterval(() => {
      if (submitted) return clearInterval(tick);
      remaining--;
      const hh = String(Math.floor(remaining / 3600)).padStart(2, '0');
      const mm = String(Math.floor((remaining % 3600) / 60)).padStart(2, '0');
      const ss = String(remaining % 60).padStart(2, '0');
      timerEl.textContent = `${hh}:${mm}:${ss}`;
      if (remaining < 600) timerEl.classList.add('low');
      if (remaining <= 0) { clearInterval(tick); grade(); }
    }, 1000);

    function grade() {
      submitted = true;
      clearInterval(tick);
      let inv = 0, fin = 0;
      const weak = {};
      items.forEach((it, i) => {
        const card = document.getElementById('ex_' + i);
        let ok = false;
        if (it.kind === 'mc') {
          const chosen = answers[i];
          ok = chosen === it.a;
          card.querySelectorAll('.opt').forEach((b) => {
            const k = parseInt(b.getAttribute('data-o'), 10);
            b.disabled = true;
            if (k === it.a) b.classList.add('correct');
            else if (k === chosen) b.classList.add('wrong');
          });
        } else {
          const raw = answers[i];
          const input = card.querySelector('[data-key="v"]');
          let ok2 = false;
          if (it.type === 'choice') ok2 = raw === it.ans;
          else {
            const nums = parseNum(raw);
            const tol = it.tol != null ? it.tol : Math.max(0.02, Math.abs(it.ans) * 0.003);
            ok2 = nums.some((x) => Math.abs(x - it.ans) <= tol);
          }
          ok = ok2;
          if (input) {
            input.classList.add(ok ? 'ok' : 'bad');
            input.disabled = true;
          }
        }
        if (ok) { if (it.side === 'INV') inv += perItem; else fin += perItem; }
        else weak[it.world] = (weak[it.world] || 0) + 1;
        const fb = document.createElement('div');
        fb.className = 'feedback ' + (ok ? 'good' : 'warn');
        fb.innerHTML = `<b>${ok ? '+' + perItem + ' Punkte' : '0 Punkte'}</b>${it.why}`;
        card.appendChild(fb);
      });

      const total = inv + fin;
      APP.SAVE.exam.taken += 1;
      APP.SAVE.exam.best = Math.max(APP.SAVE.exam.best, total);
      APP.SAVE.exam.lastSplit = [inv, fin];
      APP.persist();

      const note = total >= 96 ? 'Klausurniveau sicher erreicht – jetzt Tempo und Formulierung trainieren.'
        : total >= 72 ? 'Solide Basis. Arbeite die schwächsten Welten gezielt nach.'
        : total >= 48 ? 'Grundlagen sitzen teilweise – wiederhole die Rechen-Labore der markierten Welten.'
        : 'Starte die Kampagne erneut: Konzeptstufe, dann Labor, dann Endlos-Trainer.';

      const weakList = Object.keys(weak).map((id) => {
        const w = APP.WORLDS.find((x) => x.id === id);
        return `<li>Welt ${w.no} · ${w.title} – ${weak[id]} Aufgabe(n) falsch</li>`;
      }).join('') || '<li>Keine Schwachstellen erkannt.</li>';

      const checklist = `CFO-Simulator · Auswertung Probeklausur
Datum: ${new Date().toLocaleDateString('de-DE')}
Gesamt: ${total} / 120 Punkte
Investition: ${inv} / 60
Finanzierung: ${fin} / 60
Bewertung: ${note}

Schwachstellen:
${Object.keys(weak).map((id) => { const w = APP.WORLDS.find((x) => x.id === id); return `- Welt ${w.no} ${w.title}: ${weak[id]} Aufgabe(n) falsch`; }).join('\n') || '- keine'}

Empfehlung: Stufe 1 (Konzept) → Stufe 2 (Rechen-Labor) → Stufe 3 (Endlos-Trainer) der markierten Welten.`;

      root.innerHTML = `
        <div class="card center" style="padding:30px">
          <div style="font-size:40px">${total >= 96 ? '🏆' : total >= 72 ? '🎉' : total >= 48 ? '📈' : '📚'}</div>
          <h1 style="margin:8px 0 4px">${total} / 120 Punkte</h1>
          <p class="muted">${note}</p>
          <div class="tiles" style="margin:18px 0">
            <div class="tile"><div class="t-label">Investition</div><div class="t-value" style="color:var(--sky)">${inv} / 60</div></div>
            <div class="tile"><div class="t-label">Finanzierung</div><div class="t-value" style="color:var(--pink)">${fin} / 60</div></div>
          </div>
          <div style="text-align:left;max-width:560px;margin:0 auto">
            <h3>Schwachstellen-Analyse</h3>
            <ul class="small muted" style="padding-left:18px">${weakList}</ul>
          </div>
          <div class="row" style="justify-content:center;margin-top:16px">
            <button class="btn" data-nav="home">Zurück ins Cockpit</button>
            <button class="btn primary" data-nav="exam">Neuer Versuch</button>
          </div>
          <details style="margin-top:18px;text-align:left">
            <summary class="small muted" style="cursor:pointer">Checkliste als Text anzeigen (kopieren)</summary>
            <pre class="small" style="white-space:pre-wrap;background:#0a1220;border:1px solid var(--line);border-radius:10px;padding:12px;margin-top:10px">${checklist}</pre>
          </details>
        </div>`;
    }

    document.getElementById('submitExam').onclick = () => {
      const open = items.length - Object.keys(answers).filter((k) => answers[k] !== '' && answers[k] != null).length;
      if (open > 0 && !confirm(`${open} Aufgabe(n) sind noch leer. Trotzdem abgeben?`)) return;
      grade();
    };
    window.scrollTo({ top: 0, behavior: 'instant' });
  };

  /* ---------- Start ---------- */
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && APP.view.name !== 'home') APP.go({ name: 'home' });
  });
  APP.render();
})();
