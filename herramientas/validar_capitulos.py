"""Revisa que los capítulos JSON estén bien armados antes de abrir Godot.

Uso:  python3 herramientas/validar_capitulos.py
Comprueba: filas del mapa del mismo largo, que exista "P", que cada letra de la leyenda
esté en el mapa y que todos los diálogos referenciados existan.
"""
import glob, json, os, sys

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "datos", "capitulos")
CLAVES_DIALOGO = ("dialogo", "dialogo_frio", "dialogo_cerrado", "dialogo_listo", "dialogo_falta", "dialogo_hecho")


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
    for nombre, lineas in dialogos.items():
        for l in lineas:
            for o in l.get("opciones", []):
                if "siguiente" in o and o["siguiente"] not in dialogos:
                    errores.append(f"en '{nombre}' una opción lleva a '{o['siguiente']}', que no existe")
    for nombre, a in cap.get("acertijos", {}).items():
        for k in ("dialogo_exito", "dialogo_fallo"):
            if a.get(k) and a[k] not in dialogos:
                errores.append(f"el acertijo '{nombre}' usa el diálogo inexistente '{a[k]}'")
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
