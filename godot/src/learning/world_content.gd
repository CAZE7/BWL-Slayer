class_name WorldContent
extends RefCounted

## Eine Spielwelt mit ihren drei Stufen.
##
## Jede Welt verbindet Fachthema, Konzept-Minispiel, Originalaufgaben
## und Endlos-Trainer. Der Inhalt stammt unverändert aus dem bestehenden
## Lerncontent (siehe `tools/export_content.cjs`).

var id: String = ""
var no: int = 0
var side: String = "INV"
var title: String = ""
var tag: String = ""
var icon: String = ""
var color: String = "#d9a441"
var sources: String = ""
var briefing: Array = []
var concept_items: Array[ConceptItem] = []
var lab_tasks: Array[LabTask] = []
var stage_titles: Array = []
var stage_intros: Array = []
var has_trainer: bool = false
var trainer_params: Dictionary = {}
var concept_intro: String = ""
var lab_intro: String = ""


func side_label() -> String:
	return "Investition" if side == "INV" else "Finanzierung"


## Die Titel der drei Mastery-Stufen.
func get_stage_titles() -> Array:
	if stage_titles.size() == 3:
		return stage_titles
	return ["Konzept-Minispiel", "Rechen-Labor · Originalaufgaben", "Endlos-Trainer"]


## Der Trainer dieser Welt.
func get_trainer() -> EndlessTrainer:
	return EndlessTrainer.new(self)
