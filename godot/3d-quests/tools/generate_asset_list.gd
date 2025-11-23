@tool
extends EditorScript

func _run():
	var ac = AssetCategorizer.new()
	ac.scan_and_categorize("res://assets")
	ac.save_to_json("res://assets/asset_list.json")
	print("Generated asset_list.json!")
