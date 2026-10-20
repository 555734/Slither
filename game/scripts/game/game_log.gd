class_name GameLog
extends RefCounted
## MVP の分析用ログ（企画書 11.3）。1行1イベントの JSON を user://mvp_log.jsonl に追記する。

const PATH := "user://mvp_log.jsonl"


static func write(event: Dictionary) -> void:
	var e := event.duplicate()
	e["unix"] = Time.get_unix_time_from_system()
	var f: FileAccess
	if FileAccess.file_exists(PATH):
		f = FileAccess.open(PATH, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
	else:
		f = FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_line(JSON.stringify(e))
	f.close()


static func count_events() -> int:
	if not FileAccess.file_exists(PATH):
		return 0
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return 0
	var c := 0
	while not f.eof_reached():
		if f.get_line().strip_edges() != "":
			c += 1
	return c


static func clear_all() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
