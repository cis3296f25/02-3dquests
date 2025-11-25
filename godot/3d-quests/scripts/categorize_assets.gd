# Utility class that scans the Godot project file system for GLB assets and categorizes
# them based on keywords in their file names.
# It can be used retrieve lists of asset file paths by category.
class_name AssetCategorizer extends RefCounted

# Configuration setup

# Define the categories and the keywords associated with them.
# Asset filenames must contain one of these keywords (case-insensitive) to be categorized.
const CATEGORY_KEYWORDS: Dictionary = {
	"Roof": ["roof"],
	"Wall": ["wall"],
	"Floor": ["floor","tile"],
	"Props": [ "barrel", "crate", "box"],
	"Nature": ["tree", "bush", "plant", "flower", "grass"]
}

# File extensions to search for. No need for non glb files
const TARGET_EXTENSIONS: Array[String] = ["glb", "gltf"]

# Dictionary to store the categorized results:
# Example dictionary entry-> { "CategoryName": ["res://path/to/asset.glb", "res://path/to/anotherAsset.glb"], ... }
var categorized_assets: Dictionary = {}

# Initialization and resetting previous categorization before (re)categorizing by calling scan_directory.
## Run this to do all of the categorizing
## @param start_path: The root path to begin scanning from.
func scan_and_categorize(start_path: String) -> void:
	# Clear the previous results and prepare result dictionary with category keys
	categorized_assets.clear()
	for category in CATEGORY_KEYWORDS:
		categorized_assets[category] = []
	
	# Created other category for file names not matching any keywords
	categorized_assets["Other"] = []
	#print("Scanning assets from: " + start_path)
	
	#starts scanning directories
	var result_count = scan_directory(start_path)
	#print("Scanning complete. Found and categorized %d files." % result_count)
	
	# output for debugging purposes
	for category in categorized_assets.keys():
		print("- %s (%d assets)" % [category, categorized_assets[category].size()])

## Recursively scans a directory and look for the correct file extensions.
## Then calls categorize_file to place it in categories
## Call this to do all of the categorizing
## @param path: The path to the directory to be scanned.
## @return: The number of files found and categorized in this branch.
func scan_directory(path: String) -> int:
	var dir_access: DirAccess = DirAccess.open(path)
	if dir_access == null:
		push_error("Failed to open directory: " + path) 
		return 0

	var files_categorized = 0
	dir_access.list_dir_begin()
	var file_name = dir_access.get_next()
	
	while file_name != "":
		if dir_access.current_is_dir():
			if file_name != "." and file_name != "..":
				# Is directory, use recursion
				files_categorized += scan_directory(path.path_join(file_name))
		else:
			# Is file, check if it has the extension we are searching for
			var full_path = path.path_join(file_name)
			if TARGET_EXTENSIONS.has(file_name.get_extension().to_lower()):
				categorize_file(full_path, file_name)
				files_categorized += 1
				
		file_name = dir_access.get_next()
		
	dir_access.list_dir_end()
	return files_categorized

## Assigns a file to a category based on its filename keywords.
## @param full_path: The full path to the file
## @param file_name: The filename
func categorize_file(full_path: String, file_name: String) -> void:
	# Removes the extension from the file name
	var base_name = file_name.get_file().get_basename().to_lower()
	var is_categorized = false
	
	for category in CATEGORY_KEYWORDS:
		var keywords = CATEGORY_KEYWORDS[category]
		
		# Check for every keyword: Does the lowercased filename contains keyword?
		for keyword in keywords:
			if base_name.contains(keyword.to_lower()):
				# Add path to the list of files in the correct category
				categorized_assets[category].append(full_path)
				## No need to check other keywords for this category if found
				is_categorized = true
				break
		


	if not is_categorized:
		# No matching keyword was found in any category, so put in "Other" category.
		categorized_assets["Other"].append(full_path)



## Retrieves the list of asset paths for a specific category.
## Call this to get all of the file paths to the category
## @param category_name: The string name of the category.
## @return: An Array of asset paths (Strings), or an empty Array if the category is not found.
func get_assets_by_category(category_name: String):
	if categorized_assets.has(category_name):
		return categorized_assets[category_name]
	else:
		push_error("Category '%s' not found or scanning has not been performed yet." % category_name)
		return []

## Retrieves all assets regardless of category.
## @return: A Dictionary where keys are the categories and values are the Arrays of asset paths.
func get_all_categorized_assets():
	return categorized_assets.duplicate()

## Saves the assets to a json file
## @param path: Path where the file should be saved
func save_to_json(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(categorized_assets, "\t"))
		file.close()
	else:
		push_error("Failed to save asset JSON to: %s" % path)
