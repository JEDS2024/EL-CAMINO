"""Comprueba si un APK nuevo puede actualizar otro sin desinstalarlo.

No necesita claves privadas. Usa aapt y apksigner del SDK Android local.
"""
import argparse
import pathlib
import re
import subprocess


def informacion(apk, herramientas):
    paquete = subprocess.check_output(
        [str(herramientas / "aapt"), "dump", "badging", str(apk)], text=True)
    firma = subprocess.check_output(
        [str(herramientas / "apksigner"), "verify", "--print-certs", str(apk)], text=True)
    datos = re.search(r"package: name='([^']+)' versionCode='(\d+)'", paquete)
    certificados = set(re.findall(r"Signer #\d+ certificate SHA-256 digest: (\w+)", firma))
    if not datos or not certificados:
        raise ValueError("No se pudo leer el paquete o su firma.")
    return datos[1], int(datos[2]), certificados


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("anterior", type=pathlib.Path)
    parser.add_argument("nuevo", type=pathlib.Path)
    parser.add_argument("--sdk", type=pathlib.Path, default=pathlib.Path.home() / "Android/Sdk")
    args = parser.parse_args()
    versiones = [p for p in (args.sdk / "build-tools").iterdir()
                 if (p / "aapt").exists() and (p / "apksigner").exists()]
    if not versiones:
        parser.error("Faltan aapt y apksigner en el SDK Android.")
    herramientas = max(versiones, key=lambda p: tuple(int(n) for n in re.findall(r"\d+", p.name)))
    anterior = informacion(args.anterior, herramientas)
    nuevo = informacion(args.nuevo, herramientas)
    errores = []
    if anterior[0] != nuevo[0]:
        errores.append("El identificador del paquete cambió.")
    if anterior[2] != nuevo[2]:
        errores.append("La firma cambió: no es una actualización compatible.")
    if nuevo[1] <= anterior[1]:
        errores.append("Aumenta version/code para publicar una versión nueva.")
    for error in errores:
        print("ERROR:", error)
    if errores:
        return 1
    print(f"ACTUALIZACIÓN COMPATIBLE: {nuevo[0]}, código {anterior[1]} → {nuevo[1]}; misma firma.")
    print("Android puede instalarla encima de la anterior conservando sus datos.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
