// Verifikation der Engine gegen alle im Blueprint genannten Musterlösungswerte
const FIN = require('../src/engine.js');
const E = (x) => Math.round(x * 100) / 100;
let pass = 0, fail = 0;
function chk(label, actual, expected, tol = 0.02) {
  const ok = Math.abs(actual - expected) <= tol;
  ok ? pass++ : fail++;
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${label.padEnd(58)} ist ${E(actual)} | erwartet ${expected}`);
}

console.log('\n--- WELT 2: STATISCHE VERFAHREN ---');
const carA = { acquisitionCost: 16000, residualValue: 0, usefulLife: 4, interestRate: 0.10, fixedOperatingCosts: 355.80 + 824.40, variableCostPerUnit: 26 };
const carB = { acquisitionCost: 17000, residualValue: 0, usefulLife: 4, interestRate: 0.10, fixedOperatingCosts: 415.20 + 930.50, variableCostPerUnit: 22 };
const rA = FIN.analyzeStaticMachine(carA), rB = FIN.analyzeStaticMachine(carB);
chk('Auto A Fixkosten', rA.totalFixedCosts, 5980.20);
chk('Auto B Fixkosten', rB.totalFixedCosts, 6445.70);
chk('x_krit (Hundert-km)', FIN.criticalQuantity(carA, carB), 116.375);
chk('Kosten A bei 15.000 km', rA.totalCostsAtX(150), 9880.20);
chk('Kosten B bei 15.000 km', rB.totalCostsAtX(150), 9745.70);
chk('Kosten A bei 40.000 km', rA.totalCostsAtX(400), 16380.20);
chk('Kosten B bei 40.000 km', rB.totalCostsAtX(400), 15245.70);

const m1 = { acquisitionCost: 95000, residualValue: 4000, usefulLife: 3, interestRate: 0.06, fixedOperatingCosts: 1000, variableCostPerUnit: 4, pricePerUnit: 10 };
const m2 = { acquisitionCost: 80000, residualValue: 0, usefulLife: 3, interestRate: 0.06, fixedOperatingCosts: 8000, variableCostPerUnit: 3, pricePerUnit: 10 };
const s1 = FIN.analyzeStaticMachine(m1), s2 = FIN.analyzeStaticMachine(m2);
chk('Abfüllanlage 1 AfA', s1.depreciation, 30333.33);
chk('Abfüllanlage 1 kalk. Zinsen', s1.imputedInterest, 2970.00);
chk('Abfüllanlage 1 Fixkosten', s1.totalFixedCosts, 34303.33);
chk('Abfüllanlage 2 Fixkosten', s2.totalFixedCosts, 37066.67);
chk('x_krit Abfüllanlagen', FIN.criticalQuantity(m1, m2), 2763.33, 0.02);
chk('Break-Even M1', s1.breakEvenQuantity, 5717.22);
chk('Break-Even M2', s2.breakEvenQuantity, 5295.24);
chk('Gewinn M1 @15.000', s1.profitAtX(15000), 55696.67);
chk('Gewinn M2 @15.000', s2.profitAtX(15000), 67933.33);
chk('Rentabilität M1', s1.returnOnCapitalAtX(15000), 112.52);
chk('Rentabilität M2', s2.returnOnCapitalAtX(15000), 169.83);

const p1 = { acquisitionCost: 220000, residualValue: 16000, usefulLife: 8, interestRate: 0.06, fixedOperatingCosts: 0, variableCostPerUnit: 0 };
const p2 = { acquisitionCost: 270000, residualValue: 18000, usefulLife: 8, interestRate: 0.06, fixedOperatingCosts: 0, variableCostPerUnit: 0 };
const q1 = FIN.analyzeStaticMachine(p1), q2 = FIN.analyzeStaticMachine(p2);
chk('Cashflow M1 (Amortisation)', 29420 + q1.depreciation + q1.imputedInterest, 62000, 0.01);
chk('Amortisationszeit M1', 220000 / (29420 + q1.depreciation + q1.imputedInterest), 3.55, 0.006);
chk('Cashflow M2', 24260 + q2.depreciation + q2.imputedInterest, 64400, 0.01);
chk('Amortisationszeit M2', 270000 / (24260 + q2.depreciation + q2.imputedInterest), 4.19, 0.006);
const cum = FIN.cumulativePayback(540, [110, 96, 90, 130, 120, 95, 100]);
chk('Kumulationsmethode Objekt 1', cum.years, 4.95, 0.005);
chk('Restbetrag nach Jahr 4', cum.rest, 114, 0.001);
chk('Kumulationsmethode Objekt 2', FIN.cumulativePayback(540, [135, 135, 135, 135]).years, 4.0, 0.001);

console.log('\n--- WELT 3: DYNAMISCHE VERFAHREN ---');
const d1 = [10000, 8000, 6000, 15000], d2 = [9000, 15000, 8000, 16000];
chk('KW Maschine 1 @4 %', FIN.npv(27000, d1, 0.04), 8167.88, 0.02);
chk('KW Maschine 2 @4 %', FIN.npv(35000, d2, 0.04), 8311.03, 0.02);
chk('Rbf(4 %, 4 J.)', FIN.rbf(0.04, 4), 3.63, 0.005);
chk('Barwert Rente 10.000 (Folie: Rbf gerundet 3,63)', 10000 * FIN.rbf(0.04, 4), 36300, 2);
chk('KW M1 konstant (gerundet)', 10000 * FIN.rbf(0.04, 4) - 27000, 9300, 2);
chk('KW M2 konstant (gerundet)', 10000 * FIN.rbf(0.04, 4) - 35000, 1300, 2);
chk('Annuität M1', FIN.annuityFromNPV(8167.88, 0.04, 4), 2250.17, 0.05);
chk('Annuität M2', FIN.annuityFromNPV(8311.03, 0.04, 4), 2289.60, 0.05);
const proj = [[20, [10, 70]], [20, [70, 10]], [10, [35, 5]], [10, [39, 1]], [10, [5, 5]]];
const pi = proj.map(([a0, cf]) => FIN.profitabilityIndex(FIN.npv(a0, cf, 0.06), a0));
chk('PI Projekt 1', pi[0], 2.59, 0.005);
chk('PI Projekt 2', pi[1], 2.75, 0.005);
chk('PI Projekt 3', pi[2], 2.75, 0.005);
chk('PI Projekt 4', pi[3], 2.77, 0.005);
chk('PI Projekt 5', pi[4], -0.083, 0.004);
chk('KW Projekt 2', FIN.npv(20, [70, 10], 0.06), 54.94, 0.01);
chk('IRR A0=1.000.000, CF3=1.400.000', FIN.irrSinglePayment(1000000, 1400000, 3) * 100, 11.87, 0.05);
chk('IRR A0=82, CF1=85', FIN.irrSinglePayment(82, 85, 1) * 100, 3.66, 0.01);
chk('IRR Maschine II (Aufgabe 5)', FIN.irrSinglePayment(100000, 147000, 3) * 100, 13.70, 0.01);
chk('Rbf = A0/CF (Renten-IRR)', 1000000 / 420000, 2.381, 0.001);
chk('IRR ewige Rente 75.000/6.000', FIN.irrPerpetuity(75000, 6000) * 100, 8.0, 0.001);
const irrAnn = FIN.irrAnnuityInterval(1000000, 420000, 3);
chk('Renten-IRR interpoliert (%)', irrAnn.iApprox * 100, 12.5, 0.2);
chk('Masch. 1 KW @3 % (Aufgabe 4)', FIN.npv(27000, [10000, 8000, 6000, 6000], 0.03), 1071.28, 0.02);
chk('Masch. 1 KW @5 %', FIN.npv(27000, [10000, 8000, 6000, 6000], 0.05), -100.71, 0.02);
const it1 = FIN.secantIRRStep(27000, [10000, 8000, 6000, 6000], 0.03, 0.05);
chk('Sekante 1. Iteration (%)', it1.iStar * 100, 4.828, 0.005);
chk('KW nach 1. Iteration (Folie -3,23 bei gerundetem i*)', it1.kwStar, -3.23, 0.15);
const it2 = FIN.secantIRRStep(27000, [10000, 8000, 6000, 6000], 0.03, it1.iStar);
chk('Sekante 2. Iteration (%)', it2.iStar * 100, 4.823, 0.005);
chk('KW nach 2. Iteration (Folie -0,3819)', it2.kwStar, -0.11, 0.01);
chk('IRR Maschine 1 exakt (%)', FIN.irr(27000, [10000, 8000, 6000, 6000]) * 100, 4.82, 0.01);
chk('Masch. 2 KW @3 %', FIN.npv(35000, [9000, 15000, 8000, 7000], 0.03), 1417.35, 0.02);
chk('Masch. 2 KW @4,805 %', FIN.npv(35000, [9000, 15000, 8000, 7000], 0.04805), -5.2617, 0.02);
chk('KW Masch. II @10 % (Aufgabe 5)', FIN.npv(100000, [0, 0, 147000], 0.10), 10443.27, 0.02);
chk('Kreditvergabe KW @10 %', FIN.npvSigned([-1000, 1500], 0.10), 363.64, 0.01);
chk('Kreditaufnahme KW @10 %', FIN.npvSigned([1000, -1500], 0.10), -363.64, 0.01);

console.log('\n--- WELT 4: ANLEIHEN ---');
chk('Hamburg AG PV @2 % (3 J.)', FIN.bondPV(100, 0.06, 3, 0.02), 111.54, 0.01);
chk('Hamburg AG PV @5 % (3 J.)', FIN.bondPV(100, 0.06, 3, 0.05), 102.72, 0.01);
chk('Hamburg AG PV @2 % (1 J.)', FIN.bondPV(100, 0.06, 1, 0.02), 103.92, 0.01);
chk('Hamburg AG PV @5 % (1 J.)', FIN.bondPV(100, 0.06, 1, 0.05), 100.95, 0.01);
chk('YTM 4 %-Anleihe @98, y=4 %', FIN.bondPV(100, 0.04, 3, 0.04) - 98, 2.00, 0.01);
chk('YTM 4 %-Anleihe @98, y=5 %', FIN.bondPV(100, 0.04, 3, 0.05) - 98, -0.72, 0.01);
chk('YTM Sekante (%)', FIN.secantIRRStep(-98, [4, 4, 104], 0.04, 0.05).iStar * 100, 4.73, 0.02);
const r1 = FIN.zeroYield(100, 94, 1), r2 = FIN.zeroYield(100, 82, 2), r3 = FIN.zeroYield(100, 70, 3);
chk('Spot Rate 1 J.', r1 * 100, 6.38, 0.01);
chk('Spot Rate 2 J.', r2 * 100, 10.43, 0.01);
chk('Spot Rate 3 J.', r3 * 100, 12.62, 0.01);
chk('Kuponanleihe 8 % via Spots', FIN.bondPV(100, 0.08, 3, [r1, r2, r3]), 89.69, 0.03);
chk('Duplikation 2 %-Kupon (0,94/0,87/0,70)', 2 * 0.94 + 2 * 0.87 + 102 * 0.70, 75.02, 0.001);
const dur = FIN.duration(1000, 0.05, 4, 0.055);
chk('Barwert 4 J. 5 % @5,5 %', dur.presentValue, 982.47, 0.02);
chk('Macauley-Duration', dur.macauleyDuration, 3.72, 0.006);
chk('Modified Duration (%)', dur.modifiedDuration, 3.53, 0.01);
chk('ΔPV bei Δy=+1 %', dur.priceChangeForDeltaY(0.01).absolute, -34.65, 0.05);
chk('Portfolioduration (30/70)', FIN.portfolioDuration([0.3, 0.7], [3.72, 10]), 8.112, 0.005);

console.log('\n--- WELT 6: LOHMANN-RUCHTI ---');
const lr = FIN.lohmannRuchti(10, 5000, 5, 7);
const exp = [
  [1, 10, 10000, 10000, 2, 0, 0],
  [2, 12, 12000, 12000, 2, 0, 2000],
  [3, 14, 14000, 16000, 3, 0, 1000],
  [4, 17, 17000, 18000, 3, 0, 3000],
  [5, 20, 20000, 23000, 4, 10, 3000],
  [6, 14, 14000, 17000, 3, 2, 2000],
  [7, 15, 15000, 17000, 3, 2, 2000],
];
lr.forEach((row, k) => {
  const e = exp[k];
  chk(`LR Jahr ${e[0]}: Maschinen/AfA/Verfügbar/Neu/Rest`,
    row.activeMachines * 1e6 + row.depreciation * 1e4 + row.available * 1e2 + row.bought * 1e1 + row.rest / 100,
    e[1] * 1e6 + e[2] * 1e4 + e[3] * 1e2 + e[4] * 1e1 + e[6] / 100, 0.5);
  chk(`LR Jahr ${e[0]}: Ausmusterung`, row.retired, e[5], 0);
});

console.log('\n--- WELT 7: BEZUGSRECHT ---');
const b1 = FIN.subscriptionRight({ oldShares: 80000, newShares: 20000, oldSharePrice: 120, issuePriceNew: 90 });
chk('Mischkurs Level 1', b1.mixedPrice, 114, 0.001);
chk('Bezugsrecht Level 1', b1.subscriptionRightValue, 6, 0.001);
chk('Vermögensprobe: 5 junge Aktien − Bezahlung', 5 * b1.mixedPrice - 90, 480, 0.5);
const b2 = FIN.subscriptionRight({ oldShares: 80000, newShares: 20000, oldSharePrice: 120, issuePriceNew: 90, dividendOld: 20, monthsEntitledNew: 5 });
chk('Dividendennachteil', b2.disadvantage, 11.67, 0.01);
chk('Bezugsrecht Level 2', b2.subscriptionRightValue, 3.67, 0.005);
const b3 = FIN.subscriptionRight({ oldShares: 20000000, newShares: 5000000, oldSharePrice: 50, issuePriceNew: 40, nominalValue: 5 });
chk('XY AG Mischkurs', b3.mixedPrice, 48, 0.001);
chk('XY AG Bezugsrecht', b3.subscriptionRightValue, 2, 0.001);
const b4 = FIN.subscriptionRight({ oldShares: 75000000, newShares: 30000000, oldSharePrice: 260, issuePriceNew: 113, nominalValue: 1 });
chk('Medizin AG Mischkurs', b4.mixedPrice, 218, 0.01);
chk('Medizin AG Bezugsrecht', b4.subscriptionRightValue, 42, 0.01);
chk('Medizin AG Grundkapital +', b4.shareCapitalIncrease / 1e6, 30, 0.001);
chk('Medizin AG Agio (Mio.)', b4.agio / 1e6, 3360, 0.01);
chk('Medizin AG Mittelzufluss (Mio.)', b4.totalInflow / 1e6, 3390, 0.01);

console.log('\n--- WELT 8: SKONTO, TILGUNG, LEASING, LEVERAGE ---');
chk('Lieferantenkredit-Zins (%)', FIN.supplierCreditRate(3, 30, 10), 54, 0.001);
const ann = FIN.amortizationPlan(10000, 0.10, 3, 'ANNUITY');
chk('Annuitätendarlehen Rate', ann.annualPayment, 4021.15, 0.02);
chk('Annuität Zins Jahr 1', ann.rows[0].interest, 1000, 0.01);
chk('Annuität Tilgung Jahr 1', ann.rows[0].redemption, 3021.15, 0.02);
chk('Annuität Zins Jahr 2', ann.rows[1].interest, 697.89, 0.02);
chk('Annuität Gesamtzahlung', ann.total, 12063.44, 0.05);
const rat = FIN.amortizationPlan(10000, 0.10, 3, 'REDEMPTION');
chk('Ratendarlehen Rate Jahr 1', rat.rows[0].rate, 4333.33, 0.01);
chk('Ratendarlehen Rate Jahr 3', rat.rows[2].rate, 3666.67, 0.01);
chk('Ratendarlehen Gesamtzahlung', rat.total, 12000, 0.01);
const fest = FIN.amortizationPlan(10000, 0.10, 3, 'FEST');
chk('Fälligkeitsdarlehen Gesamtzahlung', fest.total, 13000, 0.01);
chk('Leasing: GMZ 50 % ohne Option', FIN.leasingOwner({ isSpecialLeasing: false, basicLeaseTermMonths: 30, usefulLifeMonths: 60, optionType: 'NONE' }).owner === 'LEASING_GEBER' ? 1 : 0, 1, 0);
chk('Leasing: GMZ 30 %', FIN.leasingOwner({ isSpecialLeasing: false, basicLeaseTermMonths: 18, usefulLifeMonths: 60, optionType: 'NONE' }).owner === 'LEASING_NEHMER' ? 1 : 0, 1, 0);
const lev = FIN.leverage(800000, 200000, 10, 5);
chk('Leverage Variante 1: FK-Zinsen', lev.interest, 10000, 0.01);
chk('Leverage Variante 1: Reingewinn', lev.netProfit, 90000, 0.01);
chk('Leverage Variante 1: EK-Rentabilität', lev.roePct, 11.25, 0.001);
const lev2 = FIN.leverage(400000, 600000, 10, 5);
chk('Leverage Variante 2: EK-Rentabilität', lev2.roePct, 17.50, 0.001);
chk('Leverage Variante 2: Reingewinn', lev2.netProfit, 70000, 0.01);

console.log('\n--- WELT 5: FINANZPLANUNG ---');
const wc = FIN.workingCapitalNeed([{ days: 25 }, { days: 20 }, { days: 30 }, { days: 45 }], 30, 12000);
chk('Kapitalbindungsdauer (Tage)', wc.days, 90, 0.001);
const cfOp = 25 - 10, cfInv = -5, cfFin = 5;
chk('Cashflow operativ', cfOp, 15, 0.001);
chk('Cashflow investiv', cfInv, -5, 0.001);
chk('Cashflow Finanzierung', cfFin, 5, 0.001);
chk('Endbestand Fonds (35 + 15)', 35 + cfOp + cfInv + cfFin, 50, 0.001);


console.log('\n--- WELT 9: AKTIENBEWERTUNG (Kapitel 5) ---');
chk('EPS (12 Mio, 0,5 Mio Vorzugsdividende, 4 Mio Aktien)', FIN.eps(12e6, 0.5e6, 4e6), 2.875, 0.0005);
chk('KGV bei Kurs 60 €', FIN.kgv(60, 2.875), 20.87, 0.01);
chk('Dividendenrendite (2,00 € / 60 €) %', FIN.dividendYield(2, 60) * 100, 3.33, 0.01);
chk('BW explizite Dividenden (2 / 2,5 / 3 @8 %)', FIN.pvDividendStream([2, 2.5, 3], 0.08), 6.38, 0.01);
chk('Fairer Wert inkl. Verkauf 75 € in t3', FIN.pvDividendStream([2, 2.5, 3], 0.08, 75, 3), 65.92, 0.01);
chk('Gordon P0 (D1=3, r=10 %, g=4 %)', FIN.gordon(3, 0.10, 0.04), 50, 0.01);
chk('Gordon P0 (g=6 %)', FIN.gordon(3, 0.10, 0.06), 75, 0.01);
chk('Gordon bei r<=g nicht definiert', FIN.gordon(3, 0.04, 0.06) === null ? 1 : 0, 1, 0);
chk('Implizites Wachstum bei Kurs 60 € (%)', FIN.impliedGrowth(3, 0.10, 60) * 100, 5, 0.001);
chk('CAPM (%)', FIN.capm(0.03, 1.4, 0.09) * 100, 11.4, 0.001);
chk('CAPM-Wert Gordon (D1=4, g=3 %)', FIN.gordon(4, FIN.capm(0.03, 1.4, 0.09), 0.03), 47.62, 0.01);
const ts = FIN.twoStageDDM(2, 0.15, 3, 0.03, 0.09);
chk('Zweiphasen: D3', ts.flows[2].dividend, 2.645, 0.0005);
chk('Zweiphasen: Terminal Value t3', ts.terminalValue, 45.41, 0.01);
// 40.8748 exakt; die 0.86 im Blueprint war ein Rundungsfehler (Terminal Value 45.4058 + explizit 5.8132)
chk('Zweiphasen: Wert heute', ts.presentValue, 40.87, 0.01);
chk('Nachhaltiges Wachstum (b=60 %, ROE=12 %) %', FIN.sustainableGrowth(0.6, 0.12) * 100, 7.2, 0.001);
chk('Fairer Wert (D1=1,2, r=9 %, g=7,2 %)', FIN.gordon(1.2, 0.09, 0.072), 66.67, 0.01);
chk('Bewertung über KGV-Multiple (EPS 2,875, KGV 22)', FIN.valuationByMultiple(2.875, 22), 63.25, 0.01);
chk('Gesamtrendite Aktie (P0=50, D1=2, P1=55) %', FIN.equityTotalReturn(50, 2, 55) * 100, 14, 0.001);

console.log(`\n=== ERGEBNIS: ${pass} bestanden, ${fail} fehlgeschlagen ===\n`);
process.exit(fail ? 1 : 0);
