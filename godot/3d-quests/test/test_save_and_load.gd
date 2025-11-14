extends GutTest

var SaveAndLoad = preload("res://scripts/save_and_load.gd")
var save_and_load

func before_each():
	save_and_load = SaveAndLoad.new()
	add_child(save_and_load)
	await get_tree().process_frame

func after_each():
	save_and_load.queue_free()

func test_initial_object_count():
	assert_eq(save_and_load.get_children().size(), 0, "number of objects should start at 0")
