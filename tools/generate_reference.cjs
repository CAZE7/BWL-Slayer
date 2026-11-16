/**
 * Erzeugt die Referenzwerte-Tabelle aus dem JavaScript-Original.
 *
 * Diese Datei ist die *Brücke* zwischen den beiden Engines:
 *   - src/engine.js            (JavaScript, unverändert, verifiziert)
 *   - godot/src/engine/bwl_engine.gd (GDScript-Port)
 *
 * Der Test `tools/verify_engine_parity.cjs` prüft, dass der GDScript-Port
 * exakt dieselben Werte liefert wie das JS-Original. Damit ist die
 * Kontrolle über den Port formal abgesichert.
 *
 * Aufruf:  node tools/generate_reference.cjs
 */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const FIN = require(path.join(root, 'src/engine.js'));

const rows = [];
const push = (label, value) => rows.push({ label, value });

// --- WELT 2: statische Verfahren ---------------------------------
const carA = { acquisitionCost: 16000, residualValue: 0, usefulLife: 4, interestRate: 0.10, fixedOperatingCosts: 355.80 + 824.40, variableCostPerUnit: 26 };
const carB = { acquisitionCost: 17000, residualValue: 0, usefulLife: 4, interestRate: 0.10, fixedOperatingCosts: 415.20 + 930.50, variableCostPerUnit: 22 };
const rA = FIN.analyzeStaticMachine(carA);
const rB = FIN.analyzeStaticMachine(carB);
push('auto_a_fixkosten', rA.totalFixedCosts);
push('auto_b_fixkosten', rB.totalFixedCosts);
push('auto_xkrit', FIN.criticalQuantity(carA, carB));
push('auto_a_kosten_15000km', rA.totalCostsAtX(150));
push('auto_b_kosten_15000km', rB.totalCostsAtX(150));
push('auto_a_kosten_40000km', rA.totalCostsAtX(400));
push('auto_b_kosten_40000km', rB.totalCostsAtX(400));

const m1 = { acquisitionCost: 95000, residualValue: 4000, usefulLife: 3, interestRate: 0.06, fixedOperatingCosts: 1000, variableCostPerUnit: 4, pricePerUnit: 10 };
const m2 = { acquisitionCost: 80000, residualValue: 0, usefulLife: 3, interestRate: 0.06, fixedOperatingCosts: 8000, variableCostPerUnit: 3, pricePerUnit: 10 };
push('abfuell_afa_1', FIN.analyzeStaticMachine(m1).depreciation);
push('abfuell_zinsen_1', FIN.analyzeStaticMachine(m1).imputedInterest);
push('abfuell_fixkosten_1', FIN.analyzeStaticMachine(m1).totalFixedCosts);
push('abfuell_fixkosten_2', FIN.analyzeStaticMachine(m2).totalFixedCosts);
push('abfuell_xkrit', FIN.criticalQuantity(m1, m2));
push('abfuell_rentabilitaet_1', (FIN.analyzeStaticMachine(m1).profitAtX(2000) / FIN.analyzeStaticMachine(m1).averageBoundCapital) * 100);
const cum = FIN.cumulativePayback(95000, [20000, 25000, 30000, 30000]);
push('abfuell_kumulation_jahre', cum ? cum.years : null);

// --- WELT 3: dynamische Verfahren --------------------------------
push('df_10_2', FIN.df(0.10, 2));
push('rbf_10_10', FIN.rbf(0.10, 10));
push('anf_10_10', FIN.anf(0.10, 10));
const flows = [3000, 4000, 5000, 6000];
const kw = FIN.npv(20000, flows, 0.10);
push('kapitalwert', kw);
push('annuitaet', FIN.annuityFromNPV(kw, 0.10, 4));
push('pi_kapitalwert', FIN.profitabilityIndex(kw, 20000));
push('pi_barwert', FIN.profitabilityIndexPV(20000, flows, 0.10));
push('sekante_i', FIN.secantIRRStep(20000, flows, 0, 0.30).iStar);
push('irr_bisektion', FIN.irr(20000, flows));
push('irr_einzahlung', FIN.irrSinglePayment(1000, 1500, 2));
push('irr_ewige_rente', FIN.irrPerpetuity(1000, 100));
const annInt = FIN.irrAnnuityInterval(10000, 2000, 5);
push('renten_irr_approx', annInt ? annInt.iApprox : null);

// --- WELT 4: Anleihen & Duration ---------------------------------
push('bond_barwert', FIN.bondPV(1000, 0.06, 5, 0.07));
push('kassazinssatz', FIN.zeroYield(1000, 950, 5));
const dur = FIN.duration(1000, 0.05, 5, 0.06);
push('macauley_duration', dur.macauleyDuration);
push('modified_duration', dur.modifiedDuration);
push('portfolioduration', FIN.portfolioDuration([0.6, 0.4], [3.72, 15.0]));

// --- WELT 6-8: Finanzierung --------------------------------------
const lr = FIN.lohmannRuchti(10, 5000, 5, 7);
push('lr_rest_jahr1', lr[0].rest);
push('lr_gekauft_jahr7', lr[6].bought);
push('lr_aktiv_jahr7', lr[6].activeMachines);
const br = FIN.subscriptionRight({ oldShares: 100, newShares: 50, oldSharePrice: 100, issuePriceNew: 80, dividendOld: 4, monthsEntitledNew: 5 });
push('bezugsrechtswert', br.subscriptionRightValue);
push('mischkurs', br.mixedPrice);
push('kapitalerhoehung', br.shareCapitalIncrease);
push('agio', br.agio);
push('skontozins', FIN.supplierCreditRate(4, 60, 30));
const lev = FIN.leverage(800000, 200000, 10, 5);
push('leverage_roe', lev.roePct);
push('leverage_gewinn', lev.netProfit);
push('leverage2_roe', FIN.leverage(400000, 600000, 10, 5).roePct);
push('annuitaet_plan', FIN.amortizationPlan(10000, 0.05, 5, 'ANNUITY').annualPayment);
const wc = FIN.workingCapitalNeed([{ days: 25 }, { days: 20 }, { days: 30 }, { days: 45 }], 30, 12000);
push('kapitalbindungsdauer', wc.days);
push('kapitalbedarf', wc.need);

// --- WELT 9: Aktienbewertung --------------------------------------
push('eps', FIN.eps(12e6, 0.5e6, 4e6));
push('kgv', FIN.kgv(60, 2.875));
push('dividendenrendite_prozent', FIN.dividendYield(2, 60) * 100);
push('barwert_dividenden', FIN.pvDividendStream([2, 2.5, 3], 0.08));
push('fairer_wert_mit_verkauf', FIN.pvDividendStream([2, 2.5, 3], 0.08, 75, 3));
push('gordon_p0', FIN.gordon(3, 0.10, 0.04));
push('implizites_wachstum_prozent', FIN.impliedGrowth(3, 0.10, 60) * 100);
push('capm_prozent', FIN.capm(0.03, 1.4, 0.09) * 100);
push('capm_gordon', FIN.gordon(4, FIN.capm(0.03, 1.4, 0.09), 0.03));
const ts = FIN.twoStageDDM(2, 0.15, 3, 0.03, 0.09);
push('zweiphasen_d3', ts.flows[2].dividend);
push('zweiphasen_terminal', ts.terminalValue);
push('zweiphasen_wert', ts.presentValue);
push('nachhaltiges_wachstum_prozent', FIN.sustainableGrowth(0.6, 0.12) * 100);
push('bewertung_kgv_multiple', FIN.valuationByMultiple(2.875, 22));
push('gesamtrendite_prozent', FIN.equityTotalReturn(50, 2, 55) * 100);

const out = {
  generated_from: 'src/engine.js',
  tolerance: 0.01,
  values: rows,
};
const target = path.join(root, 'godot/content/reference_values.json');
fs.mkdirSync(path.dirname(target), { recursive: true });
fs.writeFileSync(target, JSON.stringify(out, null, 1), 'utf8');
console.log(`geschrieben: ${target} (${rows.length} Referenzwerte)`);
