/* ============================================================
   Delizioso AG – CFO-Simulator
   src/engine.js  –  Finanzmathematische Engine (Investition & Finanzierung 1, UHH)
   Reine, deterministische Funktionen. 1:1 portierbar nach TypeScript.
   ============================================================ */
(function () {
  'use strict';

  const FIN = {};

  /* ---------- Helfer ---------- */
  FIN.round = function (x, d) {
    d = d === undefined ? 2 : d;
    const f = Math.pow(10, d);
    return Math.round((x + Number.EPSILON * Math.sign(x)) * f) / f;
  };
  // Kaufmännisch auf 2 Nachkommastellen (halb auf), für Anzeige
  FIN.eur = function (x, d) {
    d = d === undefined ? 2 : d;
    return x.toLocaleString('de-DE', { minimumFractionDigits: d, maximumFractionDigits: d });
  };
  FIN.pct = function (x, d) {
    d = d === undefined ? 2 : d;
    return x.toLocaleString('de-DE', { minimumFractionDigits: d, maximumFractionDigits: d }) + ' %';
  };

  /* ============================================================
     1. STATISCHE INVESTITIONSRECHNUNG (Kapitel 2)
     ============================================================ */
  FIN.analyzeStaticMachine = function (m) {
    const depreciation = (m.acquisitionCost - m.residualValue) / m.usefulLife;
    const averageBoundCapital = (m.acquisitionCost + m.residualValue) / 2;
    const imputedInterest = averageBoundCapital * m.interestRate;
    const totalFixedCosts = m.fixedOperatingCosts + depreciation + imputedInterest;
    const p = m.pricePerUnit || 0;
    const db = p - m.variableCostPerUnit;

    const totalCostsAtX = (x) => m.variableCostPerUnit * x + totalFixedCosts;
    const profitAtX = (x) => db * x - totalFixedCosts;
    const returnOnCapitalAtX = (x) => (profitAtX(x) / averageBoundCapital) * 100;
    const breakEvenQuantity = db > 0 ? totalFixedCosts / db : null;
    const annualCashflowAtX = (x) => profitAtX(x) + depreciation + imputedInterest;
    const paybackPeriodAtX = (x) => {
      const cf = annualCashflowAtX(x);
      return cf > 0 ? m.acquisitionCost / cf : Infinity;
    };
    // Deckungsbeitragsquote & Sicherheitskoeffizient (bei gegebener Menge)
    const marginRatio = (x) => (p > 0 ? db / p : null);
    const safetyCoefficient = (x) => {
      const be = breakEvenQuantity;
      return be && x ? (x - be) / x : null;
    };

    return {
      depreciation,
      averageBoundCapital,
      imputedInterest,
      totalFixedCosts,
      contributionMarginPerUnit: db,
      totalCostsAtX,
      profitAtX,
      returnOnCapitalAtX,
      breakEvenQuantity,
      annualCashflowAtX,
      paybackPeriodAtX,
      marginRatio,
      safetyCoefficient,
    };
  };

  /** Kritische Menge im Kosten- (COST) oder Gewinnvergleich (PROFIT) */
  FIN.criticalQuantity = function (m1, m2, mode) {
    mode = mode || 'COST';
    const r1 = FIN.analyzeStaticMachine(m1);
    const r2 = FIN.analyzeStaticMachine(m2);
    let denom, num;
    if (mode === 'COST') {
      denom = m1.variableCostPerUnit - m2.variableCostPerUnit;
      num = r2.totalFixedCosts - r1.totalFixedCosts;
    } else {
      denom =
        (m2.pricePerUnit || 0) - m2.variableCostPerUnit - ((m1.pricePerUnit || 0) - m1.variableCostPerUnit);
      num = r2.totalFixedCosts - r1.totalFixedCosts;
    }
    if (denom === 0) return null;
    return num / denom;
  };

  /** Kumulationsmethode: exakte Amortisationsdauer bei ungleichen Rückflüssen */
  FIN.cumulativePayback = function (a0, cashflows) {
    let cumulative = 0;
    const target = Math.abs(a0);
    for (let t = 0; t < cashflows.length; t++) {
      const next = cumulative + cashflows[t];
      if (next >= target) {
        const rest = target - cumulative;
        return { years: t + rest / cashflows[t], fullYears: t, rest, inflow: cashflows[t], cumulativeBefore: cumulative };
      }
      cumulative = next;
    }
    return null;
  };

  /* ============================================================
     2. DYNAMISCHE INVESTITIONSRECHNUNG (Kapitel 3)
     ============================================================ */
  FIN.df = (i, t) => Math.pow(1 + i, -t); // Werkzeug I: Abzinsungsfaktor
  FIN.rbf = (i, n) => (i === 0 ? n : (1 - Math.pow(1 + i, -n)) / i); // Werkzeug II
  FIN.anf = (i, n) => (i === 0 ? 1 / n : i / (1 - Math.pow(1 + i, -n))); // Werkzeug III

  /** Kapitalwert klassisch: KW = -|A0| + Σ CF_t·(1+i)^-t   (CF in t=1..n) */
  FIN.npv = (a0, flows, i) => -Math.abs(a0) + FIN.pvFlows(flows, i);
  /** Barwert einer Zahlungsreihe ab t=1 */
  FIN.pvFlows = (flows, i, start) => {
    start = start || 1;
    let s = 0;
    for (let k = 0; k < flows.length; k++) s += flows[k] * FIN.df(i, start + k);
    return s;
  };
  /** Kapitalwert mit vorzeichenbehafteten Zahlungen inkl. t=0 (für Kreditvergabe/-aufnahme) */
  FIN.npvSigned = (flows, i) => {
    let s = 0;
    for (let k = 0; k < flows.length; k++) s += flows[k] * FIN.df(i, k);
    return s;
  };
  FIN.annuityFromNPV = (npv, i, n) => npv * FIN.anf(i, n);
  FIN.profitabilityIndex = (npv, a0) => npv / Math.abs(a0);
  /** alternativ: PI über Barwert (Kriterium > 1) */
  FIN.profitabilityIndexPV = (a0, flows, i) => FIN.pvFlows(flows, i) / Math.abs(a0);
  FIN.dynamicPayback = (a0, flows, i) => FIN.cumulativePayback(a0, flows.map((cf, k) => cf * FIN.df(i, k + 1)));

  /** Sekanten-/Strahlensatz-Iteration */
  FIN.secantIRRStep = function (a0, flows, i1, i2) {
    const kw1 = FIN.npv(a0, flows, i1);
    const kw2 = FIN.npv(a0, flows, i2);
    const iStar = i1 + kw1 * ((i2 - i1) / (kw1 - kw2));
    const kwStar = FIN.npv(a0, flows, iStar);
    return { iStar, kw1, kw2, kwStar };
  };

  /** Exakter IRR per Bisektion (nur für Vorzeichenwechsel-Reihen) */
  FIN.irr = function (a0, flows) {
    const f = (i) => FIN.npv(a0, flows, i);
    let lo = -0.9999, hi = 10;
    if (f(lo) * f(hi) > 0) return null;
    for (let k = 0; k < 200; k++) {
      const mid = (lo + hi) / 2;
      if (f(lo) * f(mid) <= 0) hi = mid;
      else lo = mid;
    }
    return (lo + hi) / 2;
  };

  /** Sonderfall 1: eine Aus- und eine Einzahlung → i = (CF_t/|A0|)^(1/t) - 1 */
  FIN.irrSinglePayment = (a0, cf, t) => Math.pow(cf / Math.abs(a0), 1 / t) - 1;
  /** Sonderfall 2: Rente → Rbf = |A0|/CF, Bracketing + lineare Interpolation */
  FIN.irrAnnuityInterval = function (a0, cf, n) {
    const target = Math.abs(a0) / cf;
    let prev = null;
    for (let i = 0.0; i <= 1.0; i += 0.0001) {
      const v = FIN.rbf(i, n);
      if (v <= target) {
        if (!prev) return { rbf: target, lower: null, upper: null, iApprox: i };
        // Strahlensatz auf KW(i) = Rbf(i,n) - Zielwert (nicht auf Rbf selbst!)
        const kw1 = prev.v - target;
        const kw2 = v - target;
        const iStar = prev.i + kw1 * ((i - prev.i) / (kw1 - kw2));
        return { rbf: target, lower: prev, upper: { i: i, v: v }, iApprox: iStar };
      }
      prev = { i: i, v: v };
    }
    return null;
  };
  /** Sonderfall 3: ewige Rente → i = CF/|A0| */
  FIN.irrPerpetuity = (a0, cf) => cf / Math.abs(a0);

  /* ============================================================
     3. ANLEIHEN, ZINSSTRUKTUR & DURATION (Kapitel 4)
     ============================================================ */
  /** Barwert Kuponanleihe; y = Zahl (flache Struktur) oder Vektor (Spot Rates) */
  FIN.bondPV = function (faceValue, couponRate, maturity, y) {
    const coupon = faceValue * couponRate;
    let pv = 0;
    for (let t = 1; t <= maturity; t++) {
      const cf = t === maturity ? coupon + faceValue : coupon;
      const r = Array.isArray(y) ? y[t - 1] : y;
      pv += cf / Math.pow(1 + r, t);
    }
    return pv;
  };
  /** Zerobond-Rendite (Kassazins) ytm_0,T = (FV/PV)^(1/T) - 1 */
  FIN.zeroYield = (faceValue, price, maturity) => Math.pow(faceValue / price, 1 / maturity) - 1;

  /** Macauley- & Modified Duration inkl. Kursänderung */
  FIN.duration = function (faceValue, couponRate, maturity, y) {
    const coupon = faceValue * couponRate;
    let pvSum = 0, weighted = 0;
    const legs = [];
    for (let t = 1; t <= maturity; t++) {
      const cf = t === maturity ? coupon + faceValue : coupon;
      const pvCf = cf / Math.pow(1 + y, t);
      pvSum += pvCf;
      weighted += t * pvCf;
      legs.push({ t, cf, pvCf, weight: 0 });
    }
    legs.forEach((l) => (l.weight = l.pvCf / pvSum));
    const macauleyDuration = weighted / pvSum;
    const modifiedDuration = macauleyDuration / (1 + y);
    return {
      presentValue: pvSum,
      legs,
      macauleyDuration,
      modifiedDuration,
      priceChangeForDeltaY: function (deltaY) {
        const relative = -modifiedDuration * deltaY;
        return { relative, absolute: relative * pvSum };
      },
    };
  };
  /** Portfolioduration = Σ w_i · D_i */
  FIN.portfolioDuration = (weights, durations) => weights.reduce((s, w, k) => s + w * durations[k], 0);

  /* ============================================================
     4. FINANZIERUNG: LOHMANN-RUCHTI, BEZUGSRECHT, SKONTO, LEASING, LEVERAGE
     ============================================================ */
  /** Lohmann-Ruchti-Simulator (Kohortenmodell, Folie 65) */
  FIN.lohmannRuchti = function (initialMachines, costPerMachine, usefulLife, years) {
    initialMachines = initialMachines || 10;
    costPerMachine = costPerMachine || 5000;
    usefulLife = usefulLife || 5;
    years = years || 7;
    const cohorts = [initialMachines];
    const rows = [];
    let carried = 0;
    for (let y = 1; y <= years; y++) {
      const active = cohorts.reduce((a, b) => a + b, 0);
      const afa = active * (costPerMachine / usefulLife);
      const available = afa + carried;
      const bought = Math.floor(available / costPerMachine + 1e-9);
      const invested = bought * costPerMachine;
      const rest = available - invested;
      const retireIdx = y - usefulLife;
      const retired = retireIdx >= 0 ? cohorts[retireIdx] || 0 : 0;
      rows.push({
        year: y,
        activeMachines: active,
        depreciation: afa,
        available,
        bought,
        invested,
        retired,
        rest,
        availableBefore: available,
      });
      if (retireIdx >= 0) cohorts[retireIdx] = 0;
      cohorts.push(bought);
      carried = rest;
    }
    return rows;
  };

  /** Bezugsrecht & Kapitalerhöhung */
  FIN.subscriptionRight = function (p) {
    const ratio = p.oldShares / p.newShares; // a/n
    let disadvantage = 0;
    if (p.dividendOld != null && p.monthsEntitledNew != null) {
      disadvantage = p.dividendOld * (1 - p.monthsEntitledNew / 12);
    }
    const br = (p.oldSharePrice - (p.issuePriceNew + disadvantage)) / (ratio + 1);
    const mixedPrice =
      (p.oldShares * p.oldSharePrice + p.newShares * p.issuePriceNew) / (p.oldShares + p.newShares);
    const nominal = p.nominalValue == null ? 1 : p.nominalValue;
    const shareCapitalIncrease = p.newShares * nominal;
    const agio = p.newShares * (p.issuePriceNew - nominal);
    return {
      ratio,
      disadvantage,
      subscriptionRightValue: br,
      mixedPrice,
      shareCapitalIncrease,
      agio,
      totalInflow: shareCapitalIncrease + agio,
      wealthCheck: { withExercise: p.oldSharePrice - br, withSale: p.oldSharePrice - br },
    };
  };

  /** Lieferantenkredit: Jahreszins nach 360-Tage-Überschlagsformel */
  FIN.supplierCreditRate = (skontoPct, targetDays, skontoDays) =>
    (skontoPct / (targetDays - skontoDays)) * 360;

  /** Leasing-Bilanzierung nach Folie 175 */
  FIN.leasingOwner = function (input) {
    if (input.isSpecialLeasing) return { owner: 'LEASING_NEHMER', reason: 'Spezial-Leasing → immer Leasingnehmer' };
    const ratio = input.basicLeaseTermMonths / input.usefulLifeMonths;
    if (ratio < 0.4) return { owner: 'LEASING_NEHMER', reason: 'GMZ < 40 % der BGND → Zurechnung Leasingnehmer' };
    if (ratio > 0.9) return { owner: 'LEASING_NEHMER', reason: 'GMZ > 90 % der BGND → Zurechnung Leasingnehmer' };
    if (input.optionType === 'NONE')
      return { owner: 'LEASING_GEBER', reason: '40–90 % und keine Option → Leasinggeber' };
    if (input.optionType === 'PURCHASE')
      return input.optionPriceBelowBookValue
        ? { owner: 'LEASING_NEHMER', reason: 'Kaufoption unter Restbuchwert → Leasingnehmer' }
        : { owner: 'LEASING_GEBER', reason: 'Kaufoption ≥ Restbuchwert → Leasinggeber' };
    return input.extensionRentBelowDepreciation
      ? { owner: 'LEASING_NEHMER', reason: 'Anschlussmiete < lin. Wertverzehr → Leasingnehmer' }
      : { owner: 'LEASING_GEBER', reason: 'Anschlussmiete ≥ lin. Wertverzehr → Leasinggeber' };
  };

  /** Leverage-Effekt: r_e = r_g + FK/EK · (r_g − r_f) */
  FIN.leverage = function (equity, debt, rgPct, rfPct) {
    const ratio = debt / equity;
    const roePct = rgPct + ratio * (rgPct - rfPct);
    const totalCapital = equity + debt;
    const ebit = totalCapital * (rgPct / 100);
    const interest = debt * (rfPct / 100);
    return {
      leverageRatio: ratio,
      roePct,
      ebit,
      interest,
      netProfit: ebit - interest,
      positive: rgPct > rfPct,
      roeDirect: (ebit - interest) / equity * 100,
    };
  };

  /** Tilgungspläne (Folie 148) */
  FIN.amortizationPlan = function (principal, rate, years, type) {
    const rows = [];
    let rest = principal;
    if (type === 'ANNUITY') {
      const ann = principal * FIN.anf(rate, years);
      for (let t = 1; t <= years; t++) {
        const interest = rest * rate;
        const redemption = ann - interest;
        rest -= redemption;
        rows.push({ t, restStart: rest + redemption, interest, redemption, rate: ann, restEnd: rest });
      }
      return { rows, annualPayment: ann, total: ann * years };
    }
    const linear = principal / years;
    for (let t = 1; t <= years; t++) {
      const interest = rest * rate;
      if (type === 'REDEMPTION') {
        rest -= linear;
        rows.push({ t, restStart: rest + linear, interest, redemption: linear, rate: interest + linear, restEnd: rest });
      } else {
        // FEST / Fälligkeitsdarlehen
        const redemption = t === years ? principal : 0;
        rest -= redemption;
        rows.push({ t, restStart: rest + redemption, interest, redemption, rate: interest + redemption, restEnd: rest });
      }
    }
    const total = rows.reduce((s, r) => s + r.rate, 0);
    return { rows, total };
  };

  /** Kapitalbedarf Umlaufvermögen: Kapitalbindungsdauer × Tageskosten */
  FIN.workingCapitalNeed = function (phases, payableDays, costPerDay) {
    const days = phases.reduce((s, p) => s + p.days, 0) - payableDays;
    return { days, need: days * costPerDay };
  };

  /* ============================================================
     5. AKTIEN & AKTIENBEWERTUNG (Kapitel 5 – Erweiterungs-Slot)
     ============================================================ */

  /** Ergebnis je Aktie: (Jahresüberschuss − Vorzugsdividende) / Anzahl Stammaktien */
  FIN.eps = function (netIncome, preferredDividendTotal, commonShares) {
    return (netIncome - (preferredDividendTotal || 0)) / commonShares;
  };
  /** Kurs-Gewinn-Verhältnis */
  FIN.kgv = (price, eps) => (eps === 0 ? null : price / eps);
  /** Dividendenrendite */
  FIN.dividendYield = (dividend, price) => (price === 0 ? null : dividend / price);
  /** Gesamtrendite einer Aktie: (D1 + P1 − P0)/P0 */
  FIN.equityTotalReturn = (p0, d1, p1) => (d1 + p1 - p0) / p0;
  /** CAPM: r = r_f + β · (r_m − r_f) */
  FIN.capm = (rf, beta, rm) => rf + beta * (rm - rf);
  /** Gordon-Growth: P0 = D1/(r − g),  gültig für r > g */
  FIN.gordon = function (d1, r, g) {
    if (r <= g) return null;
    return d1 / (r - g);
  };
  /** Implizite Wachstumsrate bei gegebenem Kurs: g = r − D1/P0 */
  FIN.impliedGrowth = (d1, r, p0) => r - d1 / p0;
  /** Nachhaltige Wachstumsrate: g = Thesaurierungsquote · Eigenkapitalrendite */
  FIN.sustainableGrowth = (retentionRatio, roe) => retentionRatio * roe;
  /** Barwert expliziter Dividenden + Verkaufserlös in t=n */
  FIN.pvDividendStream = function (dividends, r, salePrice, saleAt) {
    let pv = 0;
    dividends.forEach((d, k) => (pv += d * FIN.df(r, k + 1)));
    if (salePrice && saleAt) pv += salePrice * FIN.df(r, saleAt);
    return pv;
  };
  /**
   * Zweiphasiges Dividendendiskontierungsmodell:
   * Wachstum g1 für n Jahre, danach ewiges Wachstum g2.
   */
  FIN.twoStageDDM = function (d1, g1, n, g2, r) {
    if (r <= g2) return null;
    const flows = [];
    let d = d1;
    for (let t = 1; t <= n; t++) {
      flows.push({ t: t, dividend: d });
      d = d * (1 + g1);
    }
    const dNext = flows[n - 1].dividend * (1 + g2); // Dividende in t = n+1 (Wachstum g2!)
    const terminal = dNext / (r - g2);
    let pv = 0;
    flows.forEach((f) => (pv += f.dividend / Math.pow(1 + r, f.t)));
    pv += terminal / Math.pow(1 + r, n);
    return { flows: flows, terminalValue: terminal, presentValue: pv, pvExplicit: pv - terminal / Math.pow(1 + r, n) };
  };
  /** Bewertung über ein konstantes KGV (Comparables-Ansatz) */
  FIN.valuationByMultiple = (eps, multiple) => eps * multiple;

  if (typeof window !== 'undefined') window.FIN = FIN;
  if (typeof module !== 'undefined' && module.exports) module.exports = FIN;
})();
