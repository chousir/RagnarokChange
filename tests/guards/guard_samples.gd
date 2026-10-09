class_name GuardSamples
extends RefCounted
## Throwaway sample files for the guard self-tests. Samples live under
## user://test_tmp so the real project scans never see them.


## Creates an empty folder for one test and returns its absolute path.
static func make_root(label: String) -> String:
	var root: String = ProjectSettings.globalize_path("user://test_tmp/guards_%s_%d" % [label, Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(root)
	return root


static func write(root: String, relative_path: String, content: String) -> void:
	var path: String = root.path_join(relative_path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()


static func remove_tree(root: String) -> void:
	if not DirAccess.dir_exists_absolute(root):
		return
	for sub: String in DirAccess.get_directories_at(root):
		remove_tree(root.path_join(sub))
	for file: String in DirAccess.get_files_at(root):
		DirAccess.remove_absolute(root.path_join(file))
	DirAccess.remove_absolute(root)
