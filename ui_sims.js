/* ============================================================
   src/ui_sims.js – Interaktive Simulatoren (pro Welt)
   ============================================================ */
(function () {
  'use strict';
  const R = window.R;
  const SIMS = {};

  /* ---------- SVG-Helfer ---------- */
  function chart(opts) {
    const w = opts.w || 620, h = opts.h || 260, pad = { l: 52, r: 14, t: 14, b: 28 };
    const { xmin, xmax, ymin, ymax } = opts;
    const x = (v) => pad.l + ((v - xmin) / (xmax - xmin)) * (w - pad.l - pad.r);
    const y = (v) => h - pad.b - ((v - ymin) / (ymax - ymin)) * (h - pad.t - pad.b);
    let s = `<svg viewBox="0 0 ${w} ${h}" style="width:100%;height:auto;overflow:visible">`;
    // grid
    for (let k = 0; k <= 4; k++) {
      const yy = ymin + ((ymax - ymin) * k) / 4;
      s += `<line x1="${pad.l}" y1="${y(yy)}" x2="${w - pad.r}" y2="${y(yy)}" stroke="#1e2b44" stroke-width="1"/>`;
      s += `<text x="${pad.l - 6}" y="${y(yy) + 3}" text-anchor="end">${opts.yfmt ? opts.yfmt(yy) : R(yy, 0)}</text>`;
    }
    for (let k = 0; k <= 4; k++) {
      const xx = xmin + ((xmax - xmin) * k) / 4;
      s += `<text x="${x(xx)}" y="${h - pad.b + 15}" text-anchor="middle">${opts.xfmt ? opts.xfmt(xx) : R(xx, 0)}</text>`;
    }
    if (ymin < 0 && ymax > 0) s += `<line x1="${pad.l}" y1="${y(0)}" x2="${w - pad.r}" y2="${y(0)}" stroke="#41597d" stroke-width="1.2"/>`;
    (opts.series || []).forEach((se) => {
      const pts = se.points.map((p) => `${x(p[0])},${y(p[1])}`).join(' ');
      s += `<polyline points="${pts}" fill="none" stroke="${se.color}" stroke-width="${se.width || 2.2}" ${se.dash ? 'stroke-dasharray="5 4"' : ''}/>`;
      if (se.area) {
        const first = se.points[0], last = se.points[se.points.length - 1];
        s += `<polygon points="${x(first[0])},${y(0)} ${pts} ${x(last[0])},${y(0)}" fill="${se.color}" opacity="0.08"/>`;
      }
    });
    (opts.markers || []).forEach((m) => {
      s += `<line x1="${x(m.x)}" y1="${pad.t}" x2="${x(m.x)}" y2="${h - pad.b}" stroke="${m.color || '#8fa1bd'}" stroke-width="1" stroke-dasharray="3 3"/>`;
      s += `<circle cx="${x(m.x)}" cy="${y(m.y)}" r="4" fill="${m.color || '#8fa1bd'}"/>`;
      if (m.label) s += `<text x="${x(m.x) + 6}" y="${y(m.y) - 7}" fill="${m.color || '#c3d1e6'}">${m.label}</text>`;
    });
    s += '</svg>';
    return s;
  }

  function simShell(worldId, title, sub) {
    const w = APP.WORLDS.find((x) => x.id === worldId);
    return `<div class="row" style="margin-bottom:6px">
        <button class="btn sm ghost" data-nav="world:${worldId}">← ${w.title}</button>
        <span class="chip" style="color:${w.color};border-color:${w.color}55">Simulator</span>
      </div>
      <h1 style="margin-top:10px">🔬 ${title}</h1>
      <p class="muted small">${sub}</p>
      <div id="simbody" style="margin-top:14px"></div>`;
  }

  window.renderSim = function (worldId, root) {
    const sim = SIMS[worldId];
    root.innerHTML = simShell(worldId, sim.title, sim.sub);
    sim.run(document.getElementById('simbody'));
  };

  /* ============================================================
     W1 – Zeitstrahl-Diskontierer
     ============================================================ */
  SIMS.W1 = {
    title: 'Zeitstrahl-Diskontierer',
    sub: 'Ziehe den Zinsregler und beobachte, wie aus einer Zahlungsreihe ein Barwert wird.',
    run: function (mount) {
      const flows = [-27000, 10000, 8000, 6000, 15000];
      let i = 0.04;
      function draw() {
        const pv = flows.map((f, t) => f * FIN.df(i, t));
        const bar = flows.map((f, t) => Math.abs(pv[t]) / 15000);
        mount.innerHTML = `
        <div class="card">
          <div class="slider-row">
            <div class="s-label"><span>Kalkulationszins i</span><span class="s-value">${R(i * 100, 1)} %</span></div>
            <input type="range" id="i" min="0" max="15" step="0.1" value="${i * 100}">
          </div>
          <div class="table-wrap"><table>
            <thead><tr><th>t</th>${flows.map((_, t) => `<th>t=${t}</th>`).join('')}<th>Summe</th></tr></thead>
            <tbody>
              <tr><td>Zahlung</td>${flows.map((f) => `<td>${R(f, 0)} €</td>`).join('')}<td>—</td></tr>
              <tr class="hl"><td>Barwert</td>${pv.map((v) => `<td>${R(v, 2)} €</td>`).join('')}<td><b>${R(pv.reduce((a, b) => a + b, 0), 2)} €</b></td></tr>
              <tr><td>Gewicht</td>${bar.map((b) => `<td>${Math.round(b * 100)} %</td>`).join('')}<td></td></tr>
            </tbody>
          </table></div>
          <div class="feedback ${pv.reduce((a, b) => a + b, 0) > 0 ? 'good' : 'warn'}" style="margin-top:14px">
            <b>Kapitalwert = ${R(pv.reduce((a, b) => a + b, 0), 2)} €</b>
            ${pv.reduce((a, b) => a + b, 0) > 0 ? 'Die Investition ist bei diesem Zins vorteilhaft.' : 'Bei diesem Zins ist die Investition nachteilig – der IRR liegt darunter.'}
          </div>
        </div>`;
        document.getElementById('i').oninput = (e) => { i = parseFloat(e.target.value) / 100; draw(); };
      }
      draw();
    }
  };

  /* ============================================================
     W2 – Fuhrpark-Kostenvergleich
     ============================================================ */
  const carA = { name: 'Modell A', fix: 5980.2, var100: 26 };
  const carB = { name: 'Modell B', fix: 6445.7, var100: 22 };
  SIMS.W2 = {
    title: 'Fuhrpark-Kostenvergleich',
    sub: 'Aufgabe 1 als Tachometer: Bei welcher Kilometerleistung kippt die Entscheidung?',
    run: function (mount) {
      let km = 15000;
      function draw() {
        const kA = carA.fix + carA.var100 * (km / 100);
        const kB = carB.fix + carB.var100 * (km / 100);
        const ptsA = [], ptsB = [];
        for (let x = 0; x <= 50000; x += 1000) {
          ptsA.push([x, carA.fix + carA.var100 * (x / 100)]);
          ptsB.push([x, carB.fix + carB.var100 * (x / 100)]);
        }
        const xk = (carB.fix - carA.fix) / (carA.var100 - carB.var100);
        mount.innerHTML = `
        <div class="card">
          <div class="slider-row">
            <div class="s-label"><span>Jahresfahrleistung</span><span class="s-value">${R(km, 0)} km</span></div>
            <input type="range" id="km" min="0" max="50000" step="500" value="${km}">
          </div>
          ${chart({
            xmin: 0, xmax: 50000, ymin: 4000, ymax: 20000,
            xfmt: (v) => R(v / 1000, 0) + 't km', yfmt: (v) => R(v, 0),
            series: [
              { points: ptsA, color: '#38bdf8' },
              { points: ptsB, color: '#f472b6' }
            ],
            markers: [
              { x: xk, y: carA.fix + carA.var100 * (xk / 100), color: '#fbbf24', label: 'x_krit = ' + R(xk * 100, 0) + ' km' },
              { x: km, y: kA, color: '#38bdf8' }, { x: km, y: kB, color: '#f472b6' }
            ]
          })}
          <div class="legend" style="margin-top:6px"><span><i style="background:#38bdf8"></i>Modell A</span><span><i style="background:#f472b6"></i>Modell B</span><span><i style="background:#fbbf24"></i>kritische Menge</span></div>
          <div class="tiles" style="margin-top:14px">
            <div class="tile"><div class="t-label">Kosten A</div><div class="t-value" style="color:#38bdf8">${R(kA, 2)} €</div></div>
            <div class="tile"><div class="t-label">Kosten B</div><div class="t-value" style="color:#f472b6">${R(kB, 2)} €</div></div>
            <div class="tile"><div class="t-label">Vorteil</div><div class="t-value" style="color:var(--mint)">${R(Math.abs(kA - kB), 2)} €</div></div>
          </div>
          <div class="feedback ${kA < kB ? 'good' : 'warn'}" style="margin-top:12px">
            <b>${kA < kB ? 'Modell A ist günstiger' : 'Modell B ist günstiger'}</b>
            Kritische Menge: x_krit = (6.445,70 − 5.980,20)/(26 − 22) = 116,375 Hundert-km = 11.637,5 km.
          </div>
        </div>`;
        document.getElementById('km').oninput = (e) => { km = parseFloat(e.target.value); draw(); };
      }
      draw();
    }
  };

  /* ============================================================
     W3 – Kapitalwertkurve & Sekante
     ============================================================ */
  SIMS.W3 = {
    title: 'Kapitalwertkurve & Sekanten-Scharfschütze',
    sub: 'Der IRR ist die Nullstelle der Kapitalwertkurve – hier siehst du beides gleichzeitig.',
    run: function (mount) {
      const flows = [10000, 8000, 6000, 6000];
      const a0 = 27000;
      let i1 = 0.03, i2 = 0.05;
      function draw() {
        const pts = [];
        for (let k = 0; k <= 200; k++) {
          const i = (k / 200) * 0.15;
          pts.push([i, FIN.npv(a0, flows, i)]);
        }
        const kw1 = FIN.npv(a0, flows, i1), kw2 = FIN.npv(a0, flows, i2);
        const it = FIN.secantIRRStep(a0, flows, i1, i2);
        const irr = FIN.irr(a0, flows);
        mount.innerHTML = `
        <div class="card">
          <div class="tiny muted">Zahlungsreihe: −27.000 €, dann 10.000 / 8.000 / 6.000 / 6.000 €</div>
          ${chart({
            xmin: 0, xmax: 0.15, ymin: -6000, ymax: 3500,
            xfmt: (v) => R(v * 100, 1) + ' %', yfmt: (v) => R(v, 0),
            series: [{ points: pts, color: '#a78bfa', width: 2.6 }],
            markers: [
              { x: irr, y: 0, color: '#34d399', label: 'IRR = ' + R(irr * 100, 2) + ' %' },
              { x: i1, y: kw1, color: '#38bdf8' }, { x: i2, y: kw2, color: '#f472b6' },
              { x: it.iStar, y: it.kwStar, color: '#fbbf24', label: 'i* = ' + R(it.iStar * 100, 2) + ' %' }
            ]
          })}
          <div class="row" style="gap:18px;margin-top:10px">
            <div style="flex:1">
              <div class="s-label"><span>Testzins i₁</span><span class="s-value">${R(i1 * 100, 2)} % → KW ${R(kw1, 2)} €</span></div>
              <input type="range" id="i1" min="0" max="10" step="0.05" value="${i1 * 100}">
            </div>
            <div style="flex:1">
              <div class="s-label"><span>Testzins i₂</span><span class="s-value">${R(i2 * 100, 2)} % → KW ${R(kw2, 2)} €</span></div>
              <input type="range" id="i2" min="0" max="10" step="0.05" value="${i2 * 100}">
            </div>
          </div>
          <div class="feedback ${kw1 * kw2 < 0 ? 'good' : 'warn'}" style="margin-top:12px">
            <b>${kw1 * kw2 < 0 ? 'Vorzeichenwechsel vorhanden – Sekante anwendbar' : 'Kein Vorzeichenwechsel: wähle zwei Zinsen links und rechts der Nullstelle'}</b>
            Strahlensatz: i* = ${R(i1 * 100, 2)} % + ${R(kw1, 2)} · (${R(i2 * 100, 2)} − ${R(i1 * 100, 2)}) / (${R(kw1, 2)} − (${R(kw2, 2)})) = <b>${R(it.iStar * 100, 3)} %</b>
          </div>
        </div>`;
        document.getElementById('i1').oninput = (e) => { i1 = parseFloat(e.target.value) / 100; draw(); };
        document.getElementById('i2').oninput = (e) => { i2 = parseFloat(e.target.value) / 100; draw(); };
      }
      draw();
    }
  };

  /* ============================================================
     W4 – Bond-Terminal & Duration-Wippe
     ============================================================ */
  SIMS.W4 = {
    title: 'Bond-Terminal & Duration-Wippe',
    sub: 'Preis, Notierungsart und Zinssensitivität in Echtzeit.',
    run: function (mount) {
      let fv = 1000, coupon = 0.05, mat = 4, y = 0.055;
      function draw() {
        const d = FIN.duration(fv, coupon, mat, y);
        const pvCurve = [];
        for (let k = 0; k <= 120; k++) {
          const yy = (k / 120) * 0.12;
          pvCurve.push([yy, FIN.bondPV(fv, coupon, mat, yy)]);
        }
        const chg = d.priceChangeForDeltaY(0.01);
        mount.innerHTML = `
        <div class="card">
          <div class="row" style="gap:16px;flex-wrap:wrap">
            <div style="flex:1;min-width:200px"><div class="s-label"><span>Kupon</span><span class="s-value">${R(coupon * 100, 2)} %</span></div>
              <input type="range" id="c" min="0" max="12" step="0.25" value="${coupon * 100}"></div>
            <div style="flex:1;min-width:200px"><div class="s-label"><span>Restlaufzeit</span><span class="s-value">${mat} Jahre</span></div>
              <input type="range" id="m" min="1" max="10" step="1" value="${mat}"></div>
            <div style="flex:1;min-width:200px"><div class="s-label"><span>Marktzins y</span><span class="s-value">${R(y * 100, 2)} %</span></div>
              <input type="range" id="y" min="0" max="12" step="0.05" value="${y * 100}"></div>
          </div>
          ${chart({ xmin: 0, xmax: 0.12, ymin: Math.min.apply(null, pvCurve.map((p) => p[1])) * 0.97, ymax: Math.max.apply(null, pvCurve.map((p) => p[1])) * 1.02,
            xfmt: (v) => R(v * 100, 0) + ' %', yfmt: (v) => R(v, 0),
            series: [{ points: pvCurve, color: '#fbbf24', width: 2.4 }],
            markers: [{ x: y, y: d.presentValue, color: '#34d399', label: 'PV = ' + R(d.presentValue, 2) + ' €' }] })}
          <div class="tiles" style="margin-top:12px">
            <div class="tile"><div class="t-label">Barwert</div><div class="t-value">${R(d.presentValue, 2)} €</div></div>
            <div class="tile"><div class="t-label">Notierung</div><div class="t-value" style="font-size:15px">${coupon > y ? 'über pari' : coupon < y ? 'unter pari' : 'zu pari'}</div></div>
            <div class="tile"><div class="t-label">Macauley-Duration</div><div class="t-value">${R(d.macauleyDuration, 2)} J.</div></div>
            <div class="tile"><div class="t-label">Modified Duration</div><div class="t-value">${R(d.modifiedDuration, 2)}</div></div>
          </div>
          <div class="table-wrap" style="margin-top:14px"><table>
            <thead><tr><th>t</th><th>Cashflow</th><th>Barwert</th><th>Gewicht</th><th>t · Gewicht</th></tr></thead>
            <tbody>${d.legs.map((l) => `<tr><td>${l.t}</td><td>${R(l.cf, 2)} €</td><td>${R(l.pvCf, 2)} €</td><td>${R(l.weight * 100, 1)} %</td><td>${R(l.t * l.weight, 3)}</td></tr>`).join('')}
            <tr class="hl"><td>Σ</td><td>—</td><td><b>${R(d.presentValue, 2)} €</b></td><td>100 %</td><td><b>D = ${R(d.macauleyDuration, 3)}</b></td></tr></tbody>
          </table></div>
          <div class="feedback warn" style="margin-top:12px"><b>Marktzins +1 Prozentpunkt</b>
            ΔPV/PV = −MD · Δy = −${R(d.modifiedDuration, 2)} % → ${R(chg.relative * 100, 2)} % bzw. <b>${R(chg.absolute, 2)} €</b>
            <div class="tiny muted" style="margin-top:4px">Konvexitätseffekt: die lineare Näherung überschätzt den Kursrückgang bei großen Zinsänderungen leicht.</div>
          </div>
        </div>`;
        const b = (id, fn) => (document.getElementById(id).oninput = (e) => { fn(parseFloat(e.target.value)); draw(); });
        b('c', (v) => (coupon = v / 100));
        b('m', (v) => (mat = v));
        b('y', (v) => (y = v / 100));
      }
      draw();
    }
  };

  /* ============================================================
     W5 – Du-Pont-Reaktor
     ============================================================ */
  SIMS.W5 = {
    title: 'Du-Pont-Reaktor',
    sub: 'Zwei Stellschrauben, ein ROI – und die Liquiditätsampel daneben.',
    run: function (mount) {
      let turnover = 2000000, margin = 60000, capital = 1000000;
      function draw() {
        const roi = (margin / turnover) * (turnover / capital) * 100;
        const ur = (margin / turnover) * 100;
        const ku = turnover / capital;
        mount.innerHTML = `
        <div class="card">
          <div class="row" style="gap:16px;flex-wrap:wrap">
            <div style="flex:1;min-width:210px"><div class="s-label"><span>Umsatz</span><span class="s-value">${R(turnover / 1000, 0)} T€</span></div>
              <input type="range" id="u" min="500000" max="5000000" step="50000" value="${turnover}"></div>
            <div style="flex:1;min-width:210px"><div class="s-label"><span>Gewinn + FK-Zinsen</span><span class="s-value">${R(margin / 1000, 0)} T€</span></div>
              <input type="range" id="g" min="10000" max="400000" step="5000" value="${margin}"></div>
            <div style="flex:1;min-width:210px"><div class="s-label"><span>Ø Gesamtkapital</span><span class="s-value">${R(capital / 1000, 0)} T€</span></div>
              <input type="range" id="k" min="300000" max="3000000" step="50000" value="${capital}"></div>
          </div>
          <div class="tiles" style="margin-top:14px">
            <div class="tile"><div class="t-label">Umsatzrendite</div><div class="t-value" style="color:#38bdf8">${R(ur, 2)} %</div></div>
            <div class="tile"><div class="t-label">Kapitalumschlag</div><div class="t-value" style="color:#a78bfa">${R(ku, 2)} ×</div></div>
            <div class="tile"><div class="t-label">ROI</div><div class="t-value" style="color:${roi > 10 ? 'var(--mint)' : 'var(--amber)'}">${R(roi, 2)} %</div></div>
          </div>
          <div class="given" style="margin-top:14px">ROI = Umsatzrendite × Kapitalumschlag = ${R(ur, 2)} % × ${R(ku, 2)} = ${R(roi, 2)} %</div>
          <div class="tiny muted">Zum Vergleich: Bei 6 % Marktzins für Fremdkapital muss der ROI dauerhaft darüber liegen, sonst arbeitet die Delizioso AG gegen ihre Kapitalkosten.</div>
        </div>`;
        const b = (id, fn) => (document.getElementById(id).oninput = (e) => { fn(parseFloat(e.target.value)); draw(); });
        b('u', (v) => (turnover = v));
        b('g', (v) => (margin = v));
        b('k', (v) => (capital = v));
      }
      draw();
    }
  };

  /* ============================================================
     W6 – Lohmann-Ruchti-Fabrik
     ============================================================ */
  SIMS.W6 = {
    title: 'Lohmann-Ruchti-Maschinenfabrik',
    sub: 'Jahr für Jahr reinvestieren – und zuschauen, wie die Kapazität fast explodiert.',
    run: function (mount) {
      const rows = FIN.lohmannRuchti(10, 5000, 5, 10);
      let year = 1;
      function draw() {
        const shown = rows.slice(0, year);
        const peak = Math.max.apply(null, rows.map((r) => r.activeMachines));
        mount.innerHTML = `
        <div class="card">
          <div class="row" style="justify-content:space-between;margin-bottom:10px">
            <span class="chip amber">Jahr ${year}</span>
            <div class="row">
              <button class="btn sm" id="prev" ${year === 1 ? 'disabled' : ''}>←</button>
              <button class="btn sm primary" id="next" ${year === rows.length ? 'disabled' : ''}>Jahr +1 →</button>
              <button class="btn sm ghost" id="reset">Reset</button>
            </div>
          </div>
          ${chart({ xmin: 0.5, xmax: rows.length + 0.5, ymin: 0, ymax: peak + 3,
            xfmt: (v) => 'J' + Math.round(v), yfmt: (v) => R(v, 0),
            series: [{ points: shown.map((r) => [r.year, r.activeMachines]), color: '#4ade80', width: 2.4, area: true }],
            markers: [{ x: year, y: shown[shown.length - 1].activeMachines, color: '#fbbf24', label: shown[shown.length - 1].activeMachines + ' Maschinen' }] })}
          <div class="table-wrap" style="margin-top:12px"><table>
            <thead><tr><th>Jahr</th><th>Aktiv</th><th>AfA</th><th>Verfügbar</th><th>Neukauf</th><th>Ausmusterung</th><th>Rest</th></tr></thead>
            <tbody>${shown.map((r) => `<tr class="${r.year === year ? 'hl' : ''}"><td>${r.year}</td><td>${r.activeMachines}</td><td>${R(r.depreciation, 0)} €</td><td>${R(r.available, 0)} €</td><td style="color:var(--mint)">+${r.bought}</td><td style="color:var(--red)">${r.retired ? '−' + r.retired : '–'}</td><td>${R(r.rest, 0)} €</td></tr>`).join('')}</tbody>
          </table></div>
          <div class="feedback good" style="margin-top:12px"><b>Kapazitätserweiterungseffekt</b>
            Von 10 auf ${peak} Maschinen – ohne einen Cent Außenfinanzierung. Ab Jahr 6 beginnt die Ausmusterung der Erstausstattung, der Bestand fällt wieder.</div>
          <div class="small muted" style="margin-top:10px">Grenzen in der Praxis: fehlende Teilbarkeit vernetzter Fertigungsstufen, steigende Wiederbeschaffungspreise, technischer Fortschritt, zusätzlicher Finanzierungsbedarf für das Umlaufvermögen, ausbleibende Nachfrage.</div>
        </div>`;
        document.getElementById('next').onclick = () => { year = Math.min(rows.length, year + 1); draw(); };
        document.getElementById('prev').onclick = () => { year = Math.max(1, year - 1); draw(); };
        document.getElementById('reset').onclick = () => { year = 1; draw(); };
      }
      draw();
    }
  };

  /* ============================================================
     W7 – Bezugsrechts-Waage
     ============================================================ */
  SIMS.W7 = {
    title: 'Bezugsrechts-Waage',
    sub: 'Verwässerung ist kein Verlust – wenn das Bezugsrecht stimmt.',
    run: function (mount) {
      let ka = 120, kn = 90, ratio = 4, d = 0, tn = 12;
      function draw() {
        const res = FIN.subscriptionRight({
          oldShares: ratio * 1000, newShares: 1000, oldSharePrice: ka, issuePriceNew: kn,
          dividendOld: d > 0 ? d : null, monthsEntitledNew: d > 0 ? tn : null
        });
        const br = res.subscriptionRightValue;
        const nachKauf = (ratio + 1) * res.mixedPrice - kn;
        const nachVerkauf = ratio * res.mixedPrice + ratio * br;
        mount.innerHTML = `
        <div class="card">
          <div class="row" style="gap:16px;flex-wrap:wrap">
            <div style="flex:1;min-width:190px"><div class="s-label"><span>Kurs alte Aktie K_a</span><span class="s-value">${R(ka, 2)} €</span></div>
              <input type="range" id="ka" min="20" max="300" step="1" value="${ka}"></div>
            <div style="flex:1;min-width:190px"><div class="s-label"><span>Bezugskurs K_n</span><span class="s-value">${R(kn, 2)} €</span></div>
              <input type="range" id="kn" min="5" max="290" step="1" value="${kn}"></div>
            <div style="flex:1;min-width:190px"><div class="s-label"><span>Bezugsverhältnis a : n</span><span class="s-value">${ratio} : 1</span></div>
              <input type="range" id="r" min="1" max="10" step="1" value="${ratio}"></div>
            <div style="flex:1;min-width:190px"><div class="s-label"><span>Dividende d (0 = kein Nachteil)</span><span class="s-value">${R(d, 2)} €</span></div>
              <input type="range" id="d" min="0" max="30" step="1" value="${d}"></div>
            <div style="flex:1;min-width:190px"><div class="s-label"><span>Dividendenberechtigte Monate t_n</span><span class="s-value">${tn} / 12</span></div>
              <input type="range" id="tn" min="0" max="12" step="1" value="${tn}"></div>
          </div>
          <div class="tiles" style="margin-top:14px">
            <div class="tile"><div class="t-label">Mischkurs</div><div class="t-value">${R(res.mixedPrice, 2)} €</div></div>
            <div class="tile"><div class="t-label">Dividendennachteil</div><div class="t-value">${R(res.disadvantage, 2)} €</div></div>
            <div class="tile"><div class="t-label">Bezugsrecht</div><div class="t-value" style="color:var(--mint)">${R(br, 2)} €</div></div>
            <div class="tile"><div class="t-label">Kurs nach Emission (theor.)</div><div class="t-value">${R(res.mixedPrice, 2)} €</div></div>
          </div>
          <div class="given" style="margin-top:12px">BR = (K_a − (K_n + d_nt)) / (a/n + 1) = (${R(ka, 2)} − (${R(kn, 2)} + ${R(res.disadvantage, 2)})) / (${ratio} + 1) = ${R(br, 2)} €</div>
          <div class="table-wrap"><table>
            <thead><tr><th>Aktionär</th><th>Aktion</th><th>Depotwert</th><th>Barvermögen</th><th>Gesamt</th></tr></thead>
            <tbody>
              <tr><td>A (Bezug)</td><td>${ratio} Altaktien + 1 junge zu ${R(kn, 2)} €</td><td>${R((ratio + 1) * res.mixedPrice, 2)} €</td><td>−${R(kn, 2)} €</td><td><b>${R(nachKauf, 2)} €</b></td></tr>
              <tr><td>B (Verkauf)</td><td>${ratio} Altaktien, ${ratio} BR verkauft</td><td>${R(ratio * res.mixedPrice, 2)} €</td><td>+${R(ratio * br, 2)} €</td><td><b>${R(nachVerkauf, 2)} €</b></td></tr>
              <tr class="hl"><td>Start</td><td>${ratio} Altaktien</td><td>—</td><td>—</td><td><b>${R(ratio * ka, 2)} €</b></td></tr>
            </tbody>
          </table></div>
          <div class="feedback good" style="margin-top:10px"><b>Vermögensneutralität bestätigt</b>
            ${R(nachKauf, 2)} € = ${R(nachVerkauf, 2)} € = ${R(ratio * ka, 2)} € – wer nicht zeichnet, verkauft seine Bezugsrechte und bleibt gleichgestellt.</div>
        </div>`;
        const b = (id, fn) => (document.getElementById(id).oninput = (e) => { fn(parseFloat(e.target.value)); draw(); });
        b('ka', (v) => (ka = v));
        b('kn', (v) => (kn = v));
        b('r', (v) => (ratio = v));
        b('d', (v) => (d = v));
        b('tn', (v) => (tn = v));
      }
      draw();
    }
  };

  /* ============================================================
     W8 – Leverage-Regler & Tilgungsplan
     ============================================================ */
  SIMS.W8 = {
    title: 'Leverage-Regler & Tilgungs-Architekt',
    sub: 'Der Hebel hebt – oder erdrückt. Und drei Darlehen im Vergleich.',
    run: function (mount) {
      let fkShare = 0.2, rg = 10, rf = 5, plan = 'ANNUITY';
      function draw() {
        const total = 1000000;
        const lev = FIN.leverage(total * (1 - fkShare), total * fkShare, rg, rf);
        const curve = [];
        for (let k = 0; k <= 90; k += 2) {
          const s = k / 100;
          curve.push([s, rg + (s / (1 - s)) * (rg - rf)]);
        }
        const plans = FIN.amortizationPlan(10000, 0.1, 3, plan);
        mount.innerHTML = `
        <div class="card">
          <div class="row" style="gap:16px;flex-wrap:wrap">
            <div style="flex:1;min-width:200px"><div class="s-label"><span>Fremdkapitalquote</span><span class="s-value">${R(fkShare * 100, 0)} %</span></div>
              <input type="range" id="fk" min="0" max="90" step="1" value="${fkShare * 100}"></div>
            <div style="flex:1;min-width:200px"><div class="s-label"><span>Gesamtkapitalrendite r_g</span><span class="s-value">${R(rg, 1)} %</span></div>
              <input type="range" id="rg" min="0" max="20" step="0.5" value="${rg}"></div>
            <div style="flex:1;min-width:200px"><div class="s-label"><span>Fremdkapitalzins r_f</span><span class="s-value">${R(rf, 1)} %</span></div>
              <input type="range" id="rf" min="0" max="15" step="0.5" value="${rf}"></div>
          </div>
          ${chart({ xmin: 0, xmax: 0.9, ymin: Math.min(-10, Math.min.apply(null, curve.map((p) => p[1]))), ymax: Math.max(30, Math.max.apply(null, curve.map((p) => p[1])) + 5),
            xfmt: (v) => R(v * 100, 0) + ' %', yfmt: (v) => R(v, 0) + ' %',
            series: [{ points: curve, color: lev.positive ? '#34d399' : '#f87171', width: 2.4 }],
            markers: [{ x: fkShare, y: lev.roePct, color: '#fbbf24', label: 'r_e = ' + R(lev.roePct, 2) + ' %' }] })}
          <div class="tiles" style="margin-top:12px">
            <div class="tile"><div class="t-label">EK</div><div class="t-value">${R(total * (1 - fkShare), 0)} €</div></div>
            <div class="tile"><div class="t-label">FK</div><div class="t-value">${R(total * fkShare, 0)} €</div></div>
            <div class="tile"><div class="t-label">FK-Zinsen</div><div class="t-value">${R(lev.interest, 0)} €</div></div>
            <div class="tile"><div class="t-label">Reingewinn</div><div class="t-value">${R(lev.netProfit, 0)} €</div></div>
            <div class="tile"><div class="t-label">EK-Rentabilität</div><div class="t-value" style="color:${lev.positive ? 'var(--mint)' : 'var(--red)'}">${R(lev.roePct, 2)} %</div></div>
          </div>
          <div class="feedback ${lev.positive ? 'good' : 'bad'}" style="margin-top:10px">
            <b>${lev.positive ? 'Positiver Leverage-Effekt' : 'Negativer Leverage-Effekt'}</b>
            ${lev.positive ? 'r_g > r_f: Jede zusätzliche Fremdkapital-Einheit hebt die Eigenkapitalrentabilität über die Gesamtkapitalrendite.' : 'r_g < r_f: Der Hebel wirkt gegen dich – die EK-Rentabilität sinkt unter die Gesamtkapitalrendite, die Bonität leidet.'}
          </div>
        </div>
        <div class="card">
          <div class="row" style="justify-content:space-between;margin-bottom:10px">
            <h3 style="margin:0">Tilgungs-Architekt · 10.000 €, 10 %, 3 Jahre</h3>
            <select id="plan" style="width:auto">
              <option value="ANNUITY" ${plan === 'ANNUITY' ? 'selected' : ''}>Annuitätendarlehen</option>
              <option value="REDEMPTION" ${plan === 'REDEMPTION' ? 'selected' : ''}>Abzahlungsdarlehen</option>
              <option value="FEST" ${plan === 'FEST' ? 'selected' : ''}>Festdarlehen</option>
            </select>
          </div>
          <div class="table-wrap"><table>
            <thead><tr><th>Jahr</th><th>Restschuld Beginn</th><th>Zinsen</th><th>Tilgung</th><th>Rate</th></tr></thead>
            <tbody>${plans.rows.map((r) => `<tr><td>${r.t}</td><td>${R(r.restStart, 2)} €</td><td>${R(r.interest, 2)} €</td><td>${R(r.redemption, 2)} €</td><td><b>${R(r.rate, 2)} €</b></td></tr>`).join('')}
            <tr class="hl"><td>Σ</td><td>—</td><td>${R(plans.rows.reduce((a, r) => a + r.interest, 0), 2)} €</td><td>10.000,00 €</td><td><b>${R(plans.total, 2)} €</b></td></tr></tbody>
          </table></div>
          <div class="tiny muted" style="margin-top:8px">Annuität: konstante Rate, fallende Zinsen, steigende Tilgung. Abzahlung: konstante Tilgung, fallende Rate – deshalb die niedrigste Gesamtzahlung. Festdarlehen: geringe Belastung während der Laufzeit, dafür Endtilgung und die höchste Gesamtzahlung.</div>
        </div>`;
        const b = (id, fn) => (document.getElementById(id).oninput = (e) => { fn(parseFloat(e.target.value)); draw(); });
        b('fk', (v) => (fkShare = v / 100));
        b('rg', (v) => (rg = v));
        b('rf', (v) => (rf = v));
        document.getElementById('plan').onchange = (e) => { plan = e.target.value; draw(); };
      }
      draw();
    }
  };


  /* ============================================================
     W9 – Aktien-Bewertungsterminal (Kapitel 5)
     ============================================================ */
  SIMS.W9 = {
    title: 'Aktien-Bewertungsterminal',
    sub: 'Vom CAPM-Zins zum fairen Wert: Gordon-Growth in Echtzeit, mit Marktpreis-Abgleich.',
    run: function (mount) {
      let d1 = 3.0, g = 0.04, rf = 0.03, beta = 1.4, rm = 0.09, price = 60, eps = 2.875;
      function draw() {
        const r = FIN.capm(rf, beta, rm);
        const p0 = FIN.gordon(d1, r, g);
        const implied = p0 ? FIN.impliedGrowth(d1, r, price) : null;
        const curve = [];
        const rMin = Math.max(0.02, g + 0.005);
        for (let k = 0; k <= 160; k++) {
          const rr = rMin + (k / 160) * (0.25 - rMin);
          curve.push([rr, FIN.gordon(d1, rr, g)]);
        }
        const ymax = Math.min(Math.max.apply(null, curve.map((p) => p[1])) || 200, 300);
        const pts = curve.filter((p) => p[1] <= ymax);
        const fair = p0 != null && price < p0;
        mount.innerHTML = `
        <div class="card">
          <div class="row" style="gap:16px;flex-wrap:wrap">
            <div style="flex:1;min-width:170px"><div class="s-label"><span>Dividende D₁</span><span class="s-value">${R(d1, 2)} €</span></div>
              <input type="range" id="d1" min="0.5" max="8" step="0.1" value="${d1}"></div>
            <div style="flex:1;min-width:170px"><div class="s-label"><span>Wachstum g</span><span class="s-value">${R(g * 100, 1)} %</span></div>
              <input type="range" id="g" min="0" max="8" step="0.25" value="${g * 100}"></div>
            <div style="flex:1;min-width:170px"><div class="s-label"><span>Börsenkurs</span><span class="s-value">${R(price, 2)} €</span></div>
              <input type="range" id="px" min="10" max="150" step="1" value="${price}"></div>
          </div>
          <div class="row" style="gap:16px;flex-wrap:wrap;margin-top:12px">
            <div style="flex:1;min-width:150px"><div class="s-label"><span>r_f</span><span class="s-value">${R(rf * 100, 1)} %</span></div>
              <input type="range" id="rf" min="0" max="6" step="0.1" value="${rf * 100}"></div>
            <div style="flex:1;min-width:150px"><div class="s-label"><span>Beta β</span><span class="s-value">${R(beta, 1)}</span></div>
              <input type="range" id="beta" min="0.3" max="2.5" step="0.1" value="${beta}"></div>
            <div style="flex:1;min-width:150px"><div class="s-label"><span>Marktrendite r_m</span><span class="s-value">${R(rm * 100, 1)} %</span></div>
              <input type="range" id="rm" min="4" max="15" step="0.5" value="${rm * 100}"></div>
          </div>
          ${p0 ? chart({
            xmin: rMin, xmax: 0.25, ymin: 0, ymax: ymax,
            xfmt: (v) => R(v * 100, 0) + ' %', yfmt: (v) => R(v, 0) + ' €',
            series: [{ points: pts, color: '#c084fc', width: 2.4 }],
            markers: [
              { x: r, y: p0, color: '#34d399', label: 'P₀ = ' + R(p0, 2) + ' €' },
              { x: r, y: 0, color: '#8fa1bd' }
            ]
          }) : '<div class="feedback bad"><b>r ≤ g</b>Das Gordon-Modell ist hier nicht definiert – der Nenner (r − g) wird null oder negativ.</div>'}
          <div class="tiles" style="margin-top:12px">
            <div class="tile"><div class="t-label">CAPM-Zins r</div><div class="t-value" style="color:#38bdf8">${R(r * 100, 2)} %</div></div>
            <div class="tile"><div class="t-label">Fairer Wert</div><div class="t-value" style="color:#c084fc">${p0 ? R(p0, 2) + ' €' : '–'}</div></div>
            <div class="tile"><div class="t-label">Implizites g im Kurs</div><div class="t-value">${implied != null ? R(implied * 100, 2) + ' %' : '–'}</div></div>
            <div class="tile"><div class="t-label">KGV bei EPS ${R(eps, 2)} €</div><div class="t-value">${p0 ? R(p0 / eps, 1) + ' ×' : '–'}</div></div>
          </div>
          <div class="given" style="margin-top:12px">r = ${R(rf * 100, 1)} % + ${R(beta, 1)} · (${R(rm * 100, 1)} % − ${R(rf * 100, 1)} %) = ${R(r * 100, 2)} % · P₀ = ${R(d1, 2)} / (${R(r * 100, 2)} % − ${R(g * 100, 1)} %) = ${p0 ? R(p0, 2) : '–'} €</div>
          <div class="feedback ${fair ? 'good' : 'warn'}" style="margin-top:10px">
            <b>${fair ? 'Rechnerisch unterbewertet' : 'Rechnerisch überbewertet oder fair bewertet'}</b>
            Modellwert ${p0 ? R(p0, 2) : '–'} € vs. Marktpreis ${R(price, 2)} €.
            <div class="tiny muted" style="margin-top:4px">Vorsicht: Das Modell hängt extrem an g. Schon 2 Prozentpunkte mehr Wachstum verdoppeln den Wert oft – deshalb ist die Sensitivitätsanalyse (Kurve oben) in der Klausur der eigentliche Prüfstein.</div>
          </div>
        </div>`;
        const b = (id, fn) => (document.getElementById(id).oninput = (e) => { fn(parseFloat(e.target.value)); draw(); });
        b('d1', (v) => (d1 = v));
        b('g', (v) => (g = v / 100));
        b('px', (v) => (price = v));
        b('rf', (v) => (rf = v / 100));
        b('beta', (v) => (beta = v));
        b('rm', (v) => (rm = v / 100));
      }
      draw();
    }
  };

  window.SIMULATORS = SIMS;
})();
