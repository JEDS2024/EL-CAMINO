extends SceneTree
## Comprueba que cada frase que el juego lee en voz alta tenga su grabación en assets/voz.
## Uso: godot --headless --path . -s res://pruebas/voces.gd


func _init() -> void:
	var quita := RegEx.create_from_string("\\s*\\([^)]*\\d[^)]*\\)")
	var faltan := 0
	var total := 0
	for archivo in DirAccess.get_files_at("res://datos/capitulos"):
		if not archivo.ends_with(".json"):
			continue
		var cap: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://datos/capitulos/" + archivo))
		var lineas: Array = cap.get("intro", []) + cap.get("epilogo", [])
		for v in cap.get("dialogos", {}).values():
			lineas += v
		for v in cap.get("final", {}).values():
			lineas += v
		for t in cap.get("aldeanos_frases", []):
			lineas.append({"texto": t})
		var frases: Array = []
		for l in lineas:
			var frase: String = quita.sub(String(l.get("texto", "")), "", true)
			var quien := String(l.get("quien", ""))
			frases.append(quien + ": " + frase if quien != "" else frase)
		for o in cap.get("objetivos", []):
			if o.has("ayuda"):
				frases.append(String(o["ayuda"]))
		var rep: Dictionary = cap.get("repaso", {})
		if not rep.is_empty():
			frases.append("%s. %s" % [rep.get("versiculo", ""), rep.get("cita", "")])
			for p in rep.get("preguntas", []):
				frases.append(String(p.get("pregunta", "")))
		for f in frases:
			if String(f).strip_edges() == "":
				continue
			total += 1
			if not ResourceLoader.exists("res://assets/voz/%s.ogg" % String(f).strip_edges().sha1_text().substr(0, 16)):
				faltan += 1
				print("  sin grabación: ", String(f).left(70))
	print("VOCES: %d frases, %d sin grabación" % [total, faltan])
	quit(1 if faltan else 0)
