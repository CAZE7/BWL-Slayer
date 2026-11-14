class_name EconomyState
extends RefCounted

## Der Unternehmensfinanzstatus.
##
## Korrekte Trennung von Zahlungsströmen und Kosten:
##   cash               → Zahlungsmittelbestand (Liquidität)
##   fixed_costs_year   → zahlungswirksame Fixkosten p.a.
##   material_costs_year → Materialaufwand p.a.
##   depreciation_year  → AfA (nicht zahlungswirksam)
##   imputed_interest   → kalkulatorische Zinsen (nicht zahlungswirksam)
##   debt               → Fremdkapital (zahlungswirksam: Zins + Tilgung)
##
## Investitionsauszahlungen sind KEIN laufender Aufwand. Sie erhöhen das
## Anlagevermögen und wirken über die Abschreibung auf das Ergebnis.

var cash: float = 50_000.0
var equity: float = 50_000.0
var debt: float = 0.0
var debt_rate: float = 0.06

## Buchwert des Anlagevermögens (Restbuchwerte der Maschinen).
##
## Wird bei einer Investition um den Anschaffungswert erhöht und über die
## Abschreibung reduziert. Der Ausgleich zu Eigenkapital und
## Fremdkapital wird über `balance_check()` geprüft.
var fixed_assets: float = 0.0

## kumulierte Umsatzerlöse
var revenue_total: float = 0.0
## kumulierte zahlungswirksame Kosten
var costs_total: float = 0.0
## Ergebnis des laufenden Geschäftsjahres
var profit_current_year: float = 0.0
var revenue_current_year: float = 0.0
var costs_current_year: float = 0.0

## Zahlungswirksame Fixkosten p.a. (Personal, Wartung, Verwaltung)
var fixed_costs_year: float = 0.0
## Materialaufwand p.a. (zahlungswirksam) – getrennt ausgewiesen, damit
## die GuV zwischen umsatzabhaengigen und unabhaengigen Kosten trennt.
var material_costs_year: float = 0.0
## Abschreibungen p.a. (nicht zahlungswirksam)
var depreciation_year: float = 0.0
## kalkulatorische Zinsen p.a. (nicht zahlungswirksam)
var imputed_interest_year: float = 0.0
## Zinsaufwand auf Fremdkapital p.a. (zahlungswirksam)
var interest_paid_year: float = 0.0
## Tilgung p.a. (zahlungswirksam)
var repayment_year: float = 0.0

## ausstehende Forderungen (Kundenaufträge, noch nicht bezahlt)
var receivables: float = 0.0
## Materialbestand
var inventory_value: float = 0.0

## gezahlte Dividenden (kumuliert)
var dividends_paid: float = 0.0
## im laufenden Jahr gezahlte Dividende
var dividend_current_year: float = 0.0

## Reputation (0..100)
var reputation: float = 12.0


## Umsatz des Geschäftsjahres.
func operating_result() -> float:
	return revenue_current_year - costs_current_year


## Zahlungswirksam verfügbares Ergebnis (Cashflow).
## Gewinn + AfA + kalk. Zinsen (nicht zahlungswirksam) − Zinsen − Tilgung
## Zahlungswirksamer Cashflow des Geschäftsjahres.
##
## `operating_result()` enthält bereits alle Aufwendungen des Jahres –
## auch Abschreibung, kalkulatorische Zinsen und den Zinsaufwand auf
## Fremdkapital. Abschreibung und kalkulatorische Zinsen sind nicht
## zahlungswirksam und werden deshalb wieder herausgerechnet. Der
## Zinsaufwand auf Fremdkapital ist zahlungswirksam und bleibt
## deshalb als Aufwand stehen.
##
## Nicht zahlungswirksam:
##   Abschreibung            (minderst den Gewinn, bewegt keine Kasse)
##   kalkulatorische Zinsen  (minderst den Gewinn, bewegen keine Kasse)
##
## Zahlungswirksam, aber hier nicht enthalten:
##   Tilgung (Finanzierungsentscheidung, eigener Bereich)
func cash_flow() -> float:
	return (
		operating_result()
		+ depreciation_year
		+ imputed_interest_year
	)


## Reiner Zahlungseingang des Jahres aus der operativen Tätigkeit.
##
## Identisch mit `cash_flow()`: Die Tilgung ist eine
## Finanzierungsentscheidung und gehört nicht in den operativen
## Cashflow.
func operating_cash_flow() -> float:
	return cash_flow()


## Liquiditätsgrad II (Kasse / monatliche Fixkosten).
func liquidity_ratio() -> float:
	var monthly := fixed_costs_year / 12.0
	if monthly <= 0.0:
		return 3.0 if cash >= 0.0 else 0.0
	return cash / monthly


## Fremdkapitalquote: FK / (FK + EK)
func debt_ratio() -> float:
	var total := debt + equity
	if total <= 0.0:
		return 0.0
	return debt / total


## Eigenkapitalrentabilität in Prozent.
func roe_percent() -> float:
	if equity <= 0.0:
		return 0.0
	return (operating_result() / equity) * 100.0


## Gesamtkapitalrentabilität in Prozent.
func roic_percent() -> float:
	var total := equity + debt
	if total <= 0.0:
		return 0.0
	return (operating_result() + interest_paid_year) / total * 100.0


## Liquiditätsstatus: healthy / tense / critical
func health_status() -> String:
	var liq := liquidity_ratio()
	var dr := debt_ratio()
	if cash < 0.0 or liq < 0.5 or dr > 0.9:
		return "critical"
	if liq < 2.0 or dr > 0.7:
		return "tense"
	return "healthy"


## Begründungstexte zum aktuellen Zustand.
##
## Die Gründe sind voneinander unabhängig: Eine überzogene Kasse und
## eine hohe Verschuldung können gleichzeitig bestehen. Deshalb wird
## jeder zutreffende Grund einzeln genannt – nicht nur der erste.
func health_reasons() -> PackedStringArray:
	var reasons := PackedStringArray()
	var liq := liquidity_ratio()
	var dr := debt_ratio()
	if cash < 0.0:
		reasons.append("Die Kasse ist überzogen – Liquiditätskrise.")
	if liq < 1.0:
		reasons.append("Liquiditätsgrad %.2f < 1 – die Kasse deckt die Fixkosten nicht." % liq)
	if dr > 0.75:
		reasons.append("Fremdkapitalquote %.0f %% – gefährlich hohe Verschuldung." % (dr * 100.0))
	return reasons


## Summe der Aktiva: Anlagevermögen + Umlaufvermögen.
func total_assets() -> float:
	return fixed_assets + cash + receivables + inventory_value


## Passivseite: Eigenkapital + Fremdkapital.
func total_liabilities_and_equity() -> float:
	return equity + debt


## Bilanzabweichung: Aktiva minus Passivseite.
##
## Idealwert ist 0. Ein positiver Wert bedeutet, es fehlen Aktiva
## (z. B. nicht verbuchte Investitionen); ein negativer Wert bedeutet,
## die Passivseite ist zu hoch.
func balance_check() -> float:
	return total_assets() - total_liabilities_and_equity()


## Investitionsauszahlung: Kapital wird gebunden, Anlagevermögen steigt.
##
## Der Anschaffungswert ist KEIN laufender Aufwand. Er ist eine
## Aktivierung; die Wirkung auf das Ergebnis erfolgt über die
## Abschreibung in den Folgejahren.
func book_investment(amount: float) -> void:
	move_cash(-amount)
	fixed_assets += amount


## Abschreibung auf das Anlagevermögen buchen.
func book_depreciation(amount: float) -> void:
	var applied: float = minf(amount, fixed_assets)
	fixed_assets -= applied


## Eine Zahlung auf das Betriebskonto buchen.
##
## `amount` ist der Betrag; positive Werte sind Einzahlungen, negative
## Werte Auszahlungen. Jede Kassenbewegung laeuft ueber diese Methode,
## damit das Signal `cash_changed` zuverlaessig ankommt und die UI
## sowie der Advisor auf jede relevante Bewegung reagieren koennen.
##
## Die eigene Kasse wird nicht mitveraendert – der Aufrufer bucht
## zusaetzlich, was fachlich zur Bewegung gehoert (z. B. das
## Anlagevermoegen bei einer Investition).
func move_cash(amount: float) -> void:
	if is_zero_approx(amount):
		return
	cash += amount
	EventBus.cash_changed.emit(cash, amount)


## Serialisierbarer Zustand.
func to_dict() -> Dictionary:
	return {
		"cash": cash,
		"equity": equity,
		"debt": debt,
		"fixed_assets": fixed_assets,
		"debt_rate": debt_rate,
		"revenue_total": revenue_total,
		"costs_total": costs_total,
		"profit_current_year": profit_current_year,
		"revenue_current_year": revenue_current_year,
		"costs_current_year": costs_current_year,
		"fixed_costs_year": fixed_costs_year,
		"material_costs_year": material_costs_year,
		"depreciation_year": depreciation_year,
		"imputed_interest_year": imputed_interest_year,
		"interest_paid_year": interest_paid_year,
		"repayment_year": repayment_year,
		"receivables": receivables,
		"inventory_value": inventory_value,
		"dividends_paid": dividends_paid,
		"dividend_current_year": dividend_current_year,
		"reputation": reputation,
	}


## Stellt den Zustand aus einem Save wieder her.
func from_dict(data: Dictionary) -> void:
	cash = float(data.get("cash", 50_000.0))
	equity = float(data.get("equity", 50_000.0))
	debt = float(data.get("debt", 0.0))
	fixed_assets = float(data.get("fixed_assets", 0.0))
	debt_rate = float(data.get("debt_rate", 0.06))
	revenue_total = float(data.get("revenue_total", 0.0))
	costs_total = float(data.get("costs_total", 0.0))
	profit_current_year = float(data.get("profit_current_year", 0.0))
	revenue_current_year = float(data.get("revenue_current_year", 0.0))
	costs_current_year = float(data.get("costs_current_year", 0.0))
	fixed_costs_year = float(data.get("fixed_costs_year", 0.0))
	material_costs_year = float(data.get("material_costs_year", 0.0))
	depreciation_year = float(data.get("depreciation_year", 0.0))
	imputed_interest_year = float(data.get("imputed_interest_year", 0.0))
	interest_paid_year = float(data.get("interest_paid_year", 0.0))
	repayment_year = float(data.get("repayment_year", 0.0))
	receivables = float(data.get("receivables", 0.0))
	inventory_value = float(data.get("inventory_value", 0.0))
	dividends_paid = float(data.get("dividends_paid", 0.0))
	dividend_current_year = float(data.get("dividend_current_year", 0.0))
	reputation = float(data.get("reputation", 12.0))
