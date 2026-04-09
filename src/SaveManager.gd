extends Node

const SAVE_DIR = "user://saves/"

var is_loading_mode: bool = false 
var current_slot: int = 1 

func _ready() -> void:
	_ensure_save_dir_exists()

func _ensure_save_dir_exists() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

func get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_slot_" + str(slot) + ".dat"

func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func write_save(slot: int, data: Dictionary) -> void:
	var path = get_save_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file:
		file.store_var(data)
		file.close()
		print("Save slot ", slot, ": ", data)
	else:
		push_error("Failed to write save: ", path)

func load_save(slot: int) -> Dictionary:
	var path = get_save_path(slot)
	
	if not save_exists(slot):
		return {"max_level": 0} 

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			return data
	
	return {"max_level": 0}

func delete_save(slot: int) -> void:
	if save_exists(slot):
		DirAccess.remove_absolute(get_save_path(slot))
		print("Slot ", slot, " deleted.")

func unlock_next_level(completed_index: int) -> void:
	var data = load_save(current_slot)
	var current_max = data.get("max_level", 0)
	
	if current_max <= completed_index:
		data["max_level"] = completed_index + 1
		write_save(current_slot, data)
