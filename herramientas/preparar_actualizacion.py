"""Genera actualizacion.json a partir de un APK firmado y su URL pública definitiva."""
import argparse
import hashlib
import json
import pathlib
import re
import subprocess
from urllib.parse import urlsplit


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("apk", type=pathlib.Path)
    p.add_argument("--url", required=True, help="URL HTTPS pública del APK en la release")
    p.add_argument("--salida", type=pathlib.Path, default=pathlib.Path("builds/actualizacion.json"))
    p.add_argument("--sdk", type=pathlib.Path, default=pathlib.Path.home() / "Android/Sdk")
    args = p.parse_args()
    url = urlsplit(args.url)
    if url.scheme != "https" or not url.hostname or url.username or url.password or any(c.isspace() for c in args.url):
        p.error("La URL debe ser HTTPS pública, sin credenciales ni espacios.")
    versiones = [d for d in (args.sdk / "build-tools").iterdir() if (d / "apksigner").exists()]
    tools = max(versiones, key=lambda d: tuple(int(x) for x in re.findall(r"\d+", d.name)))
    subprocess.run([str(tools / "apksigner"), "verify", str(args.apk)], check=True)
    paquete = subprocess.check_output([str(tools / "aapt"), "dump", "badging", str(args.apk)], text=True)
    datos = re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", paquete)
    if not datos or datos[1] != "com.jader.elcamino":
        p.error("El APK no pertenece a El Camino.")
    with args.apk.open("rb") as f:
        sha256 = hashlib.file_digest(f, "sha256").hexdigest()
    manifiesto = {"package": datos[1], "version_code": int(datos[2]), "version_name": datos[3],
                  "apk_url": args.url, "sha256": sha256, "size": args.apk.stat().st_size}
    args.salida.parent.mkdir(parents=True, exist_ok=True)
    args.salida.write_text(json.dumps(manifiesto, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("Manifiesto generado:", args.salida)
    print("Adjunta este JSON y el APK a la misma release pública. No publica nada automáticamente.")


if __name__ == "__main__":
    main()
