"""Revisa que los capítulos JSON estén bien armados antes de abrir Godot.

Uso:  python3 herramientas/validar_capitulos.py
Comprueba: filas del mapa del mismo largo, que exista "P", que cada letra de la leyenda
esté en el mapa, que se pueda llegar caminando a cada entidad y que todos los diálogos referenciados existan.
"""
import glob, json, os, sys

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "datos", "capitulos")
CLAVES_DIALOGO = ("dialogo", "dialogo_frio", "dialogo_cerrado", "dialogo_listo", "dialogo_falta", "dialogo_hecho")


PISABLES = set(".=,:_%;*bP@+?! ")


def alcanzables(cap):
    """Recorre el mapa desde P y devuelve qué celdas se pueden pisar."""
    filas = cap["mapa"]
    ley = cap.get("leyenda", {})
    def pisable(ch):
        if ch in ley:
            d = ley[ch]
            if d.get("tipo") in ("objeto", "salida"):
                return True
            return d.get("tipo") == "npc" and (d.get("seguir") or "aparece_si" in d)
        return ch in PISABLES
    inicio = next((x, z) for z, f in enumerate(filas) for x, ch in enumerate(f) if ch == "P")
    vistos, pila = {inicio}, [inicio]
    while pila:
        x, z = pila.pop()
        for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, z + dz)
            if 0 <= n[1] < len(filas) and 0 <= n[0] < len(filas[n[1]]) and n not in vistos and pisable(filas[n[1]][n[0]]):
                vistos.add(n)
                pila.append(n)
    return vistos


def revisar(ruta):
    errores = []
    with open(ruta, encoding="utf-8") as f:
        cap = json.load(f)
    dialogos = cap.get("dialogos", {})
    filas = cap["mapa"]
    for i, fila in enumerate(filas):
        if len(fila) != len(filas[0]):
            errores.append(f"la fila {i} del mapa mide {len(fila)} y la primera {len(filas[0])}")
    usados = set("".join(filas))
    if "P" not in usados:
        errores.append("el mapa no tiene 'P' (inicio del jugador)")
    for letra, d in cap.get("leyenda", {}).items():
        if letra not in usados:
            errores.append(f"'{letra}' está en la leyenda pero no en el mapa")
        for k in CLAVES_DIALOGO:
            if k in d and d[k] not in dialogos:
                errores.append(f"'{letra}' usa el diálogo inexistente '{d[k]}'")
        for o in d.get("dialogos", []):
            if o["id"] not in dialogos:
                errores.append(f"'{letra}' usa el diálogo inexistente '{o['id']}'")
    if not errores:
        vistos = alcanzables(cap)
        for z, fila in enumerate(filas):
            for x, ch in enumerate(fila):
                if ch in cap.get("leyenda", {}):
                    vecinos = [(x, z), (x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)]
                    if not any(v in vistos for v in vecinos):
                        errores.append(f"no se puede llegar caminando a '{ch}' (columna {x}, fila {z})")
    for identificador, plano in cap.get("planos", {}).items():
        dialogo = plano.get("dialogo", "")
        if dialogo and dialogo not in dialogos:
            errores.append(f"el plano '{identificador}' usa el diálogo inexistente '{dialogo}'")
        for pieza in plano.get("partes", [plano]):
            if len(pieza.get("desde", [])) != 3 or len(pieza.get("tam", [])) != 3:
                errores.append(f"el plano '{identificador}' necesita vectores desde/tam de tres valores")
    for pieza in cap.get("estructuras", []):
        for parte in pieza.get("partes", [pieza]):
            if len(parte.get("desde", [])) != 3 or len(parte.get("tam", [])) != 3:
                errores.append("una estructura necesita vectores desde/tam de tres valores")
    for nombre, lineas in dialogos.items():
        for l in lineas:
            for o in l.get("opciones", []):
                if "siguiente" in o and o["siguiente"] not in dialogos:
                    errores.append(f"en '{nombre}' una opción lleva a '{o['siguiente']}', que no existe")
    for nombre, a in cap.get("acertijos", {}).items():
        for k in ("dialogo_exito", "dialogo_fallo"):
            if a.get(k) and a[k] not in dialogos:
                errores.append(f"el acertijo '{nombre}' usa el diálogo inexistente '{a[k]}'")
    if cap.get("id") == "cap0_noe":
        # Comprueba que las fuentes del mapa alcancen para construir los tres planos.
        total = {"madera": 0, "brea": 0}
        for plano in cap.get("planos", {}).values():
            for parte in plano.get("partes", [plano]):
                tam = parte["tam"]
                material = parte.get("material", plano.get("material", ""))
                if material in total:
                    total[material] += tam[0] * tam[1] * tam[2]
        fuente = {"madera": 0, "brea": 0}
        for letra, defn in cap.get("leyenda", {}).items():
            if defn.get("tipo") == "monton":
                material = {"tronco": "madera"}.get(defn.get("material"), defn.get("material"))
                if material in fuente:
                    fuente[material] += int(defn.get("bloques", 0)) * sum(fila.count(letra) for fila in filas)
        for material in total:
            if fuente[material] < total[material]:
                errores.append(f"hay {fuente[material]} bloques de {material}, pero los planos requieren {total[material]}")
    return errores


def main():
    total = 0
    for ruta in sorted(glob.glob(os.path.join(RAIZ, "*.json"))):
        errores = revisar(ruta)
        total += len(errores)
        print(("OK   " if not errores else "MAL  ") + os.path.basename(ruta))
        for e in errores:
            print("     - " + e)
    sys.exit(1 if total else 0)


if __name__ == "__main__":
    main()
