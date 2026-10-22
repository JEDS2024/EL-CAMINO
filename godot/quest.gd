extends RefCounted
## Las escenas de enlace son originales; no son citas de los Evangelios.
signal changed
var stage: int = 0
const OBJECTIVES = [
	"Conoce a Miriam, junto al pozo.",
	"Busca la cesta bajo el olivo, al sur de la aldea.",
	"Devuelve la cesta a Miriam.",
	"Encuentra a Jesús, cerca de la orilla.",
	"Ve al sendero del norte para comenzar el viaje.",
	"El camino continúa. Has completado el prototipo.",
]
const GUIDES = ["miriam", "basket", "miriam", "jesus", "path", ""]

func interact(id: String) -> Dictionary:
	var result: Dictionary = {}
	var next_stage := stage
	match id:
		"miriam":
			match stage:
				0:
					next_stage = 1
					result = {"speaker": "Miriam", "lines": ["Dejé mi cesta bajo el olivo, al sur de la aldea.", "¿Podrías traerla? Un poco de ayuda puede cambiar el día de alguien."]}
				1:
					result = {"speaker": "Miriam", "lines": ["La cesta está bajo el olivo. Gracias por ayudarme."]}
				2:
					next_stage = 3
					result = {"speaker": "Miriam", "lines": ["¡Mi cesta! Gracias por detenerte a ayudar.", "Jesús está junto a la orilla, al este. Puedes encontrarlo allí."]}
				_:
					result = {"speaker": "Miriam", "lines": ["Que tengas un buen camino. Gracias por tu ayuda."]}
		"basket":
			if stage == 1:
				next_stage = 2
				result = {"speaker": "La cesta", "lines": ["Recoges la cesta con cuidado. Llévasela a Miriam."]}
			elif stage == 0:
				result = {"speaker": "Una cesta", "lines": ["Una cesta bajo el olivo. Tal vez alguien la esté buscando."]}
		"jesus":
			if stage == 3:
				next_stage = 4
				result = {"speaker": "El encuentro · narración original", "lines": ["Te acercas a Jesús y escuchas. Se abre ante ti un camino de aprendizaje, servicio y esperanza.", "Decides acompañarlo. El sendero del norte será el comienzo de tu viaje."]}
			else:
				result = {"speaker": "Junto a la orilla · narración", "lines": ["El sendero del norte te espera." if stage >= 4 else "Antes de partir, conoce a los habitantes y ayuda a Miriam."]}
		"neighbor":
			result = {"speaker": "Habitante de la aldea", "lines": ["Miriam está junto al pozo. El olivo está al sur y Jesús junto a la orilla, al este."]}
		"path":
			if stage == 4:
				next_stage = 5
				result = {"speaker": "El camino", "lines": ["Dejas la aldea y comienzas a acompañar a Jesús."]}
			else:
				result = {"speaker": "El sendero", "lines": ["Antes de partir, termina tus encuentros en la aldea."]}
	if next_stage != stage:
		stage = next_stage
		changed.emit()
	return result
