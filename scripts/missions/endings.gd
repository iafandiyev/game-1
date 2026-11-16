extends Node

class_name Endings

## Endings - Handles the two possible game endings

signal ending_triggered(ending_id: String)

static var ending_a_data: Dictionary = {
	"id": "ending_a",
	"name": "Escape",
	"description": "Ethan successfully escapes the city.",
	"requirements": ["m15_final_choice:ending_a"],
	"epilogue": """
The helicopter's rotors cut through the smog-choked air as it lifted away from the military base rooftop. 
Ethan looked down at the sprawling ruin below - the city that had been his prison for weeks. 
The viral outbreak had claimed thousands, but he had survived. He had found the truth, 
collected the evidence, and now he was getting out.

As the aircraft banked toward the quarantine perimeter, Ethan clutched the data drive 
containing the research notes and military intelligence. The world needed to know what 
happened here. The experiments, the cover-up, the deliberate release - it all had to be exposed.

The pilot's voice crackled over the intercom: "Clearing the perimeter. You're clear, son."

Ethan exhaled, the first real breath of relief in weeks. He had escaped the nightmare. 
But as the city fell away beneath them, he knew the real work was just beginning. 
The truth was out there, and he was the one who had to deliver it.

THE END - ESCAPE ENDING
"""
}

static var ending_b_data: Dictionary = {
	"id": "ending_b",
	"name": "Sacrifice",
	"description": "Ethan destroys the virus source but remains behind.",
	"requirements": ["m15_final_choice:ending_b"],
	"epilogue": """
The command center's self-destruct sequence counted down. 30 seconds. 
Ethan stood before the viral containment chamber - the source of it all. 
The research notes had been clear: the virus wasn't natural. It was engineered. 
A bioweapon designed to create the perfect soldier, but it had created something far worse.

The military had known. They'd sealed the city not to contain the outbreak, 
but to hide their crime. The "cure" they claimed to be developing was a lie. 
There was no cure - only control.

Ethan's thumb hovered over the detonator. The data drive with the evidence was 
already in the helicopter on the roof, set to auto-launch on a dead man's switch. 
The truth would get out. But the source had to be destroyed.

10 seconds.

He thought of the survivors he'd found, the lives he'd saved, the ones he couldn't. 
He thought of the safehouse, the people waiting for him there. 
He thought of the night sky over the city, and how he'd never see another sunrise.

3... 2... 1...

The explosion vaporized the containment chamber, the research data, the virus samples. 
The military's dark secret burned with it. Somewhere above, a helicopter 
carried the truth to the world.

Ethan didn't survive the blast. But he'd made sure the nightmare ended with him.

THE END - SACRIFICE ENDING
"""
}

static func get_ending(ending_id: String) -> Dictionary:
	match ending_id:
		"ending_a": return ending_a_data
		"ending_b": return ending_b_data
		_: return {}

static func trigger_ending(ending_id: String) -> void:
	var ending = get_ending(ending_id)
	if ending:
		# Show ending cinematic
		_show_ending_cinematic(ending)
		
		# Save completion
		_save_ending(ending_id)

static func _show_ending_cinematic(ending: Dictionary) -> void:
	# Would play ending cutscene
	# For now, just log
	print("ENDING TRIGGERED: " + ending["name"])
	print(ending["epilogue"])

static func _save_ending(ending_id: String) -> void:
	var file = FileAccess.open("user://ending_%s.txt" % ending_id, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"ending": ending_id,
			"timestamp": Time.get_unix_time_from_datetime(Time.get_datetime_now()),
			"play_time": GameManager.play_time
		}))
		file.close()

static func has_seen_ending(ending_id: String) -> bool:
	return FileAccess.file_exists("user://ending_%s.txt" % ending_id)

static func get_seen_endings() -> Array[String]:
	var endings = []
	for ending_id in ["ending_a", "ending_b"]:
		if has_seen_ending(ending_id):
			endings.append(ending_id)
	return endings