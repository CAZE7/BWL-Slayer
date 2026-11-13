/* ============================================================
   src/ui_core.js – Shell, Savegame, Cockpit, Weltansicht
   ============================================================ */
(function () {
  'use strict';

  const WORLDS = window.GAMEDATA_PART1.concat(window.GAMEDATA_PART2, window.GAMEDATA_PART3 || []);
  const SAVE_KEY = 'delizioso-cfo-savegame-v1';

  const TOOLS = {
    W1: [{ id: 'ZAHLUNGSREIHE', label: 'Zahlungsreihen-Klassifikation' }, { id: 'NUTZUNGSDAUER', label: 'Wirtschaftliche Nutzungsdauer' }],
    W2: [{ id: 'KOSTENVERGLEICH', label: 'Kostenvergleichsrechnung' }, { id: 'AMORT', label: 'Amortisationsrechnung' }],
    W3: [{ id: 'ABZINSUNG', label: 'Abzinsungsfaktor (1+i)^-t' }, { id: 'RBF', label: 'Rentenbarwertfaktor' }, { id: 'ANF', label: 'Annuitätenfaktor' }, { id: 'IRR', label: 'Interner Zinsfuß / Sekante' }],
    W4: [{ id: 'BONDPV', label: 'Anleihebewertung' }, { id: 'SPOT', label: 'Kassazinssätze' }, { id: 'DURATION', label: 'Duration & Modified Duration' }],
    W5: [{ id: 'DUPONT', label: 'Du-Pont-Kennzahlen' }, { id: 'CFR', label: 'Kapitalflussrechnung' }, { id: 'LIQUIDITAET', label: 'Liquiditäts- & Deckungsgrade' }],
    W6: [{ id: 'LR', label: 'Lohmann-Ruchti-Simulation' }, { id: 'STILLE', label: 'Stille Reserven' }],
    W7: [{ id: 'BR', label: 'Bezugsrechtsformel' }, { id: 'KE', label: 'Kapitalerhöhungsformen' }],
    W9: [{ id: 'EPS', label: 'Ergebnis je Aktie & KGV' }, { id: 'DDM', label: 'Dividendendiskontierung' }, { id: 'GORDON', label: 'Gordon-Growth' }, { id: 'CAPM', label: 'CAPM' }],
    W8: [{ id: 'SKONTO', label: 'Skonto-/Lieferantenkreditformel' }, { id: 'TILGUNG', label: 'Tilgungspläne' }, { id: 'LEASING', label: 'Leasing-Zurechnung' }, { id: 'LEVERAGE', label: 'Leverage-Formel' }]
  };

  const emptyWorld = () => ({ stages: [false, false, false], points: [0, 0, 0] });
  const defaultSave = () => {
    const w = {};
    WORLDS.forEach((x) => (w[x.id] = emptyWorld()));
    return {
      playerName: 'CFO Delizioso',
      streak: 0,
      cash: 27000,
      tools: ['ABZINSUNG'],
      worlds: w,
      exam: { best: 0, taken: 0, lastSplit: [0, 0] },
      createdAt: Date.now()
    };
  };

  const SAVE = (function load() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (!raw) return defaultSave();
      const p = JSON.parse(raw);
      const base = defaultSave();
      WORLDS.forEach((w) => {
        if (!p.worlds || !p.worlds[w.id]) return;
        base.worlds[w.id] = {
          stages: (p.worlds[w.id].stages || [false, false, false]).slice(0, 3),
          points: (p.worlds[w.id].points || [0, 0, 0]).slice(0, 3)
        };
      });
      Object.assign(base, {
        playerName: p.playerName || base.playerName,
        streak: p.streak || 0,
        cash: p.cash != null ? p.cash : base.cash,
        tools: p.tools || base.tools,
        exam: p.exam || base.exam
      });
      return base;
    } catch (e) {
      return defaultSave();
    }
  })();

  function persist() {
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(SAVE)); } catch (e) {}
  }

  /* ---------- Ableitungen ---------- */
  const S = (id) => (SAVE.worlds[id] ? SAVE.worlds[id].stages.filter(Boolean).length : 0);
  const stagesDone = (id) => S(id);
  const totalPoints = () => WORLDS.reduce((a, w) => a + SAVE.worlds[w.id].points.reduce((x, y) => x + y, 0), 0);
  const sidePoints = (side) => {
    const ws = WORLDS.filter((w) => w.side === side);
    const raw = ws.reduce((a, w) => a + SAVE.worlds[w.id].points.reduce((x, y) => x + y, 0), 0);
    return Math.round((raw / (ws.length * 30)) * 60);
  };
  function metric(defs) {
    const tw = defs.reduce((a, d) => a + d[1], 0);
    const got = defs.reduce((a, d) => a + d[1] * (S(d[0]) / 3), 0);
    return Math.round(25 + 75 * (got / tw));
  }
  function metrics() {
    return [
      { key: 'liq', label: 'Liquidität', color: '#34d399', v: metric([['W5', 1.2], ['W6', 1.0], ['W8', 0.8], ['W1', 0.4]]) },
      { key: 'rent', label: 'Rentabilität', color: '#fbbf24', v: metric([['W2', 1.2], ['W3', 1.2], ['W8', 0.8], ['W4', 0.6], ['W9', 0.6]]) },
      { key: 'unab', label: 'Unabhängigkeit', color: '#38bdf8', v: metric([['W7', 1.4], ['W6', 1.0], ['W5', 0.7], ['W1', 0.5]]) },
      { key: 'flex', label: 'Flexibilität', color: '#a78bfa', v: metric([['W4', 1.0], ['W8', 1.0], ['W5', 0.8], ['W6', 0.6], ['W9', 0.5]]) }
    ];
  }
  const isUnlocked = (idx) => idx === 0 || S(WORLDS[idx - 1].id) >= 1;
  const examUnlocked = () => WORLDS.every((w) => S(w.id) >= 2);

  /* ---------- State ---------- */
  const APP = {
    view: { name: 'home' },
    SAVE,
    WORLDS,
    S,
    persist,
    metrics,
    sidePoints,
    totalPoints,
    examUnlocked,
    isUnlocked,
    stagePoints: [0, 0, 0]
  };
  window.APP = APP;

  /* ---------- Helfer ---------- */
  const R = (x, d) => (x).toLocaleString('de-DE', { minimumFractionDigits: d === undefined ? 2 : d, maximumFractionDigits: d === undefined ? 2 : d });
  window.R = R;
  window.toast = function (msg) {
    let t = document.getElementById('toast');
    if (!t) return;
    t.textContent = msg;
    t.classList.add('show');
    clearTimeout(window.__tHide);
    window.__tHide = setTimeout(() => t.classList.remove('show'), 2400);
  };
  APP.award = function (worldId, stage, points) {
    const w = SAVE.worlds[worldId];
    const before = w.stages[stage];
    w.points[stage] = Math.max(w.points[stage], Math.round(points));
    w.stages[stage] = true;
    if (!before) {
      SAVE.streak += 1;
      SAVE.cash += Math.round(points * 800);
      (TOOLS[worldId] || []).slice(0, stage === 0 ? 1 : stage === 1 ? 3 : 99).forEach((t) => {
        if (!SAVE.tools.includes(t.id)) SAVE.tools.push(t.id);
      });
    }
    persist();
  };

  /* ---------- Navigation ---------- */
  APP.go = function (view) {
    APP.view = view;
    window.scrollTo({ top: 0, behavior: 'instant' });
    APP.render();
  };

  /* ---------- Shell ---------- */
  function topbar() {
    const ms = metrics();
    return `
    <div class="topbar"><div class="topbar-in">
      <div class="brand" data-nav="home">
        <div class="logo">D</div>
        <div>Delizioso AG<small>CFO-Simulator · Investition &amp; Finanzierung 1</small></div>
      </div>
      <div class="metrics">
        ${ms.map((m) => `
          <div class="metric">
            <div class="m-label"><span>${m.label}</span><span style="color:${m.color}">${m.v}</span></div>
            <div class="m-bar"><div class="m-fill" style="width:${m.v}%;background:${m.color}"></div></div>
          </div>`).join('')}
      </div>
      <span class="chip amber">🔥 ${SAVE.streak}</span>
      <span class="chip mint">💰 ${R(SAVE.cash, 0)} €</span>
    </div></div>`;
  }

  window.buildTopbar = topbar;

  /* ---------- Home ---------- */
  function home() {
    const invPts = sidePoints('INV'), finPts = sidePoints('FIN');
    const done = WORLDS.reduce((a, w) => a + S(w.id), 0);
    const pct = Math.round((done / (WORLDS.length * 3)) * 100);
    return `
    <h1>Willkommen zurück, ${SAVE.playerName}.</h1>
    <p class="muted" style="max-width:760px">Die Delizioso AG wächst. ${WORLDS.length} Spielwelten bilden den kompletten Stoff der Vorlesung ab – von der ersten Fuhrparkentscheidung bis zur grünen Unternehmensanleihe. Wähle eine Welt, spiele die drei Stufen und halte dein Unternehmen liquide, rentabel, unabhängig und flexibel.</p>

    <div class="card" style="margin-top:16px">
      <div class="row" style="justify-content:space-between">
        <div>
          <h2 style="margin-bottom:2px">Klausurpunkte-Konto</h2>
          <div class="small muted">120 Punkte · 120 Minuten · Investition 60 / Finanzierung 60</div>
        </div>
        <div class="row">
          <span class="chip sky">Investition ${invPts} / 60</span>
          <span class="chip mint">Finanzierung ${finPts} / 60</span>
        </div>
      </div>
      <div style="margin-top:14px" class="pbar"><i style="width:${pct}%"></i></div>
      <div class="row small muted" style="margin-top:7px;justify-content:space-between">
        <span>${done} von ${WORLDS.length * 3} Stufen abgeschlossen</span><span>${pct} %</span>
      </div>
    </div>

    <div class="row" style="margin:22px 0 12px">
      <h2 style="margin:0">Die ${WORLDS.length} Spielwelten</h2>
      <div class="spacer"></div>
      <span class="small muted">INVESTITION-Welten → 60 Punkte · FINANZIERUNG-Welten → 60 Punkte</span>
    </div>
    <div class="grid">
      ${WORLDS.map((w, i) => {
        const open = isUnlocked(i);
        const st = S(w.id);
        return `<div class="world-card ${open ? '' : 'locked'}" data-nav="${open ? 'world:' + w.id : 'locked:' + w.id}">
          <span class="side-tag side-${w.side}">${w.side === 'INV' ? 'INVESTITION' : 'FINANZIERUNG'}</span>
          <div class="wc-top">
            <div class="wc-no" style="color:${w.color};border-color:${w.color}55">${w.no}</div>
            <h3>${w.title}</h3>
          </div>
          <div class="tag">${w.icon} ${w.tag}</div>
          <div class="dots">
            <div class="dot ${st > 0 ? 'on' : ''}"></div>
            <div class="dot ${st > 1 ? 'on' : ''}"></div>
            <div class="dot ${st > 2 ? 'on' : ''}"></div>
          </div>
          <div class="tiny muted" style="margin-top:8px">${open ? (st === 3 ? '✓ gemeistert · ' : '') + st + '/3 Stufen' : '🔒 schließe Welt ' + (w.no - 1) + ' ab'}</div>
        </div>`;
      }).join('')}
    </div>

    <div class="card" style="margin-top:18px;border-color:${examUnlocked() ? 'rgba(251,191,36,.45)' : 'var(--line)'}">
      <div class="row" style="justify-content:space-between">
        <div>
          <h2 style="margin-bottom:2px">🎯 Der 120-Minuten-Bosskampf</h2>
          <div class="small muted">Probeklausur-Simulator: 60 Punkte Investition + 60 Punkte Finanzierung, Countdown 120 Minuten.</div>
        </div>
        <button class="btn ${examUnlocked() ? 'primary' : ''}" data-nav="exam" ${examUnlocked() ? '' : 'disabled'}>
          ${examUnlocked() ? 'Prüfung starten' : '🔒 2 Stufen pro Welt nötig'}
        </button>
      </div>
      ${SAVE.exam.taken ? `<div class="small muted" style="margin-top:10px">Bisheriges Ergebnis: <b style="color:var(--amber)">${SAVE.exam.best} / 120 Punkte</b> aus ${SAVE.exam.taken} Versuch(en).</div>` : ''}
    </div>

    <p class="tiny muted" style="margin-top:26px">Datenbasis: Vorlesungsfolien und Übungsblätter zu Investition &amp; Finanzierung 1 (Universität Hamburg) · Alle Rechenkerne sind gegen die Musterlösungen geprüft (122 Testfälle) · Fortschritt wird lokal im Browser gespeichert.</p>`;
  }

  /* ---------- World ---------- */
  function world(id) {
    const w = WORLDS.find((x) => x.id === id);
    const st = SAVE.worlds[id];
    const stages = [
      { n: 1, t: 'Konzept-Minispiel', d: w.concept.intro, pts: st.points[0] },
      { n: 2, t: 'Rechen-Labor · Originalaufgaben', d: w.lab.intro, pts: st.points[1] },
      { n: 3, t: 'Endlos-Trainer (prozedural)', d: w.trainer.intro, pts: st.points[2] }
    ];
    return `
    <div class="row" style="margin-bottom:6px">
      <button class="btn sm ghost" data-nav="home">← Cockpit</button>
      <span class="chip" style="color:${w.color};border-color:${w.color}55">Welt ${w.no} · ${w.side === 'INV' ? 'Investition' : 'Finanzierung'}</span>
    </div>
    <h1>${w.icon} ${w.title}</h1>
    <p class="muted" style="margin-bottom:4px"><b style="color:${w.color}">${w.tag}</b></p>
    <p class="tiny muted">Quellen: ${w.sources}</p>

    <div class="card" style="margin-top:16px">
      <div class="card-head"><span class="icon">🗂️</span><div><h3 style="margin:0">Briefing-Cards</h3><div class="tiny muted">30 Sekunden Theorie – dann wird gespielt.</div></div></div>
      <div class="brief">
        ${w.briefing.map((b) => `<div class="brief-item"><b>${b.h}</b><p>${b.p}</p></div>`).join('')}
      </div>
    </div>

    <div class="row" style="margin:18px 0 10px">
      <h2 style="margin:0">Mastery-Stufen</h2><div class="spacer"></div>
      ${window.SIMULATORS && window.SIMULATORS[id] ? `<button class="btn sm" data-nav="sim:${id}">🔬 Simulator öffnen</button>` : ''}
    </div>
    ${stages.map((s) => `
      <div class="stage-row ${st.stages[s.n - 1] ? 'done' : ''}" data-nav="stage:${id}:${s.n}">
        <div class="stage-num">${st.stages[s.n - 1] ? '✓' : s.n}</div>
        <div style="flex:1">
          <div style="font-weight:700">${s.t}</div>
          <div class="tiny muted">${s.d}</div>
        </div>
        <div class="tiny" style="color:${st.stages[s.n - 1] ? 'var(--mint)' : 'var(--muted)'};white-space:nowrap">${st.stages[s.n - 1] ? s.pts + ' P.' : 'offen'}</div>
      </div>`).join('')}

    <div class="card" style="margin-top:18px">
      <div class="card-head"><span class="icon">🧰</span><div><h3 style="margin:0">Werkzeugkarten</h3><div class="tiny muted">Formeln, die du dir in dieser Welt verdienst.</div></div></div>
      <div class="row">
        ${(TOOLS[w.id] || []).map((t) => `<span class="chip ${SAVE.tools.includes(t.id) ? 'mint' : ''}" style="opacity:${SAVE.tools.includes(t.id) ? 1 : 0.5}">${SAVE.tools.includes(t.id) ? '✓' : '🔒'} ${t.label}</span>`).join('')}
      </div>
    </div>`;
  }

  /* ---------- Render ---------- */
  APP.render = function () {
    const app = document.getElementById('app');
    const v = APP.view;
    let body = '';
    if (v.name === 'home') body = home();
    else if (v.name === 'world') body = world(v.id);
    else if (v.name === 'stage') body = '<div id="stage-root"></div>';
    else if (v.name === 'sim') body = '<div id="stage-root"></div>';
    else if (v.name === 'exam') body = '<div id="stage-root"></div>';
    app.innerHTML = topbar() + `<div class="wrap">${body}</div>`;

    if (v.name === 'stage') window.renderStage(v.id, v.stage, document.getElementById('stage-root'));
    if (v.name === 'sim') window.renderSim(v.id, document.getElementById('stage-root'));
    if (v.name === 'exam') window.renderExam(document.getElementById('stage-root'));
  };

  document.addEventListener('click', function (e) {
    const el = e.target.closest('[data-nav]');
    if (!el) return;
    const nav = el.getAttribute('data-nav');
    if (nav === 'home') return APP.go({ name: 'home' });
    if (nav.startsWith('world:')) return APP.go({ name: 'world', id: nav.split(':')[1] });
    if (nav.startsWith('locked:')) {
      const id = nav.split(':')[1];
      const idx = WORLDS.findIndex((w) => w.id === id);
      if (confirm(`Welt ${WORLDS[idx].no} ist noch gesperrt (schließe Stufe 1 von Welt ${WORLDS[idx].no - 1} ab). Trotzdem öffnen?`))
        return APP.go({ name: 'world', id: id });
      return;
    }
    if (nav.startsWith('stage:')) {
      const p = nav.split(':');
      return APP.go({ name: 'stage', id: p[1], stage: parseInt(p[2], 10) });
    }
    if (nav.startsWith('sim:')) return APP.go({ name: 'sim', id: nav.split(':')[1] });
    if (nav === 'exam') return APP.go({ name: 'exam' });
    if (nav === 'reset') {
      if (confirm('Wirklich den gesamten Spielstand löschen?')) {
        try { localStorage.removeItem(SAVE_KEY); } catch (err) {}
        location.reload();
      }
      return;
    }
  });
})();
