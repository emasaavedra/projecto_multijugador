class_name Items
extends RefCounted

## Ítems de las cajas. El servidor elige cuál según la posición en la carrera:
## los que van adelante reciben ítems débiles y los de atrás los más fuertes,
## así quien se queda atrás (por ejemplo, por pisar un pepino) siempre puede alcanzar.

enum Tipo { NINGUNO, CHURU, TRIPLE_CHURU, BIP, PEPINO, LANA, MANCHA, RAYITO }

## PRUEBAS: si no es NINGUNO, todas las cajas dan este ítem. Volver a Tipo.NINGUNO antes de commitear.
const ITEM_DE_PRUEBA: Tipo = Tipo.NINGUNO

const ICONOS: Dictionary = {
	Tipo.CHURU: preload("res://assets/items/churu.png"),
	Tipo.TRIPLE_CHURU: preload("res://assets/items/triple_churu.png"),
	Tipo.BIP: preload("res://assets/items/bip.png"),
	Tipo.PEPINO: preload("res://assets/items/pepino.png"),
	Tipo.LANA: preload("res://assets/items/lana.png"),
	Tipo.MANCHA: preload("res://assets/items/milk-cat-cat.png"),
	Tipo.RAYITO: preload("res://assets/items/gato_estatica.png")
}

## Cuántas veces se puede usar cada ítem
const USOS: Dictionary = {
	Tipo.CHURU: 1,
	Tipo.TRIPLE_CHURU: 3,
	Tipo.BIP: 1,
	Tipo.PEPINO: 1,
	Tipo.LANA: 1,
	Tipo.MANCHA: 1,
	Tipo.RAYITO: 1
}

## Probabilidad relativa de cada ítem para [primer lugar, mitad, último lugar]
const PESOS: Dictionary = {
	Tipo.CHURU: [45.0, 35.0, 15.0],
	Tipo.TRIPLE_CHURU: [0.0, 25.0, 35.0],
	Tipo.BIP: [0.0, 10.0, 35.0],
	Tipo.PEPINO: [55.0, 30.0, 15.0],
	Tipo.LANA: [30.0, 40.0, 25.0],
	Tipo.MANCHA: [100.0, 20.0, 30.0],
	Tipo.RAYITO: []
}


## posicion: 0 = primer lugar. total: cantidad de jugadores.
static func sortear(posicion: int, total: int, rng: RandomNumberGenerator) -> Tipo:
	if ITEM_DE_PRUEBA != Tipo.NINGUNO:
		return ITEM_DE_PRUEBA
	# 0.0 = va primero, 1.0 = va último. Jugando solo se usa la mitad para ver de todo.
	var avance: float = 0.5 if total <= 1 else float(posicion) / float(total - 1)
	var pesos: Dictionary = {}
	var suma: float = 0.0
	for tipo: int in PESOS:
		var valores: Array = PESOS[tipo]
		var peso: float
		if avance < 0.5:
			peso = lerpf(valores[0], valores[1], avance * 2.0)
		else:
			peso = lerpf(valores[1], valores[2], (avance - 0.5) * 2.0)
		pesos[tipo] = peso
		suma += peso
	var tirada: float = rng.randf() * suma
	for tipo: int in pesos:
		tirada -= pesos[tipo]
		if tirada <= 0.0:
			return tipo as Tipo
	return Tipo.CHURU
