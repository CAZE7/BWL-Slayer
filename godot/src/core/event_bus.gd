extends Node

## Zentraler Signal-Verteiler.
##
## Bewusst als Autoload: Simulation, UI und Advisor kommunizieren ausschließlich
## über Events. Das hält die Simulationslogik frei von UI-Abhängigkeiten und
## macht den Ablauf deterministisch testbar.
##
## Wichtig: kein `class_name` – ein Klassenname, der einem Autoload-Singleton
## entspricht, verhindert den Projektstart ("hides an autoload singleton").

# --- Simulation ---
signal simulation_ticked(day: int, tick: int)
signal simulation_paused_changed(paused: bool)
signal simulation_speed_changed(speed: float)
signal day_passed(day: int, report: Dictionary)

# --- Produktion & Logistik ---
signal machine_state_changed(machine_id: String, state: Dictionary)
signal production_completed(machine_id: String, output: Dictionary)
signal delivery_ordered(order: Dictionary)
signal delivery_arrived(order: Dictionary)
signal delivery_installed(order: Dictionary)
signal truck_moved(truck_id: String, position: Vector3)
signal order_received(order: Dictionary)
signal order_completed(order: Dictionary)

# --- Wirtschaft ---
signal economy_changed(state: Dictionary)
signal cash_changed(cash: float, delta: float)
signal investment_committed(order: Dictionary)
signal health_changed(status: String, reasons: PackedStringArray)

# --- Lernen / Aufgaben ---
signal mission_offered(mission_id: String)
signal mission_started(mission_id: String)
signal mission_completed(mission_id: String, result: Dictionary)
signal task_feedback(task_id: String, correct: bool, explanation: String)
signal learning_progress_changed(world_id: String, stage_index: int, solved: bool)

# --- Progression ---
signal company_expanded(building_id: String)
signal department_unlocked(department_id: String)
signal reputation_changed(reputation: float)
signal rank_changed(rank_id: String)

# --- Advisor ---
signal advisor_message_added(entry: Dictionary)
signal advisor_analysis_changed(analysis: Dictionary)

# --- UI ---
signal notification(posted: Dictionary)
signal screen_changed(screen_id: String)
signal settings_changed(settings: Dictionary)
signal save_completed(slot_id: String)
signal save_failed(reason: String)


## Sendet eine benutzerdefinierte Benachrichtigung an die UI.
func notify(title: String, body: String, kind: String = "info") -> void:
	notification.emit({"title": title, "body": body, "kind": kind})
