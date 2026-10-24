"""Graba la narración del juego con una voz neuronal en español (Kokoro-82M, sin internet).

Cada frase que el juego lee en voz alta se guarda en assets/voz/<clave>.ogg, donde la clave son
los primeros 16 caracteres del SHA-1 del texto tal como lo lee el juego (ver CajaDialogo.hablar).
Así, si cambias un texto, basta con volver a correr este script: graba solo lo nuevo y borra lo
que ya no se usa. Si cambias VOZ, vuelve a grabar todo.

Preparación (una vez), fuera del proyecto (modelo y voces con licencia Apache 2.0):
    mkdir -p ~/Juegos/herramientas/voces/kokoro && cd ~/Juegos/herramientas/voces/kokoro
    uv venv --python 3.12 .venv
    uv pip install --python .venv/bin/python "kokoro>=0.9.4" soundfile --extra-index-url https://download.pytorch.org/whl/cpu
Uso:
    ~/Juegos/herramientas/voces/kokoro/.venv/bin/python herramientas/generar_voces.py
"""
import glob, hashlib, json, os, re, subprocess, sys, tempfile

import numpy as np
import soundfile as sf
from kokoro import KPipeline

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DESTINO = os.path.join(RAIZ, "assets", "voz")
VOZ = "ef_dora"  # voz femenina en español de Kokoro
VELOCIDAD = 0.95
MARCA = "VOZ.txt"  # qué voz grabó lo que hay en assets/voz

# igual que CajaDialogo._quita_citas: las referencias bíblicas entre paréntesis no se leen
QUITA_CITAS = re.compile(r"\s*\([^)]*\d[^)]*\)")
# textos fijos del código que también se leen
FIJOS = ["Hola. Esta es la voz que lee las historias de El Camino.", "La llama arde tranquila.",
         "La pareja entra en el arca.",
         # ayudas por tipo de misión (main.gd, ayuda_de) y el minijuego de la honda
         "Sigue el rombo dorado. Pica bloques del montón con «Picar» y ponlos en la silueta azul con «Poner».",
         "Sigue el rombo dorado y pulsa el botón junto a cada lugar, en el orden correcto.",
         "Sigue el rombo dorado y, cuando estés cerca, pulsa el botón grande de la derecha.",
         "Un marcador blanco va y viene por la barra. Pulsa «¡Lanzar!» justo cuando pase por la zona dorada.",
         "¡La piedra dio en la frente del filisteo!",
         "¡Casi! Espera a que el marcador pase por lo dorado y vuelve a intentarlo."]
ORDINALES = {"1": "primera de", "2": "segunda de", "3": "tercera de"}


def clave(texto):
    return hashlib.sha1(texto.strip().encode("utf-8")).hexdigest()[:16]


def frase_linea(l):
    frase = QUITA_CITAS.sub("", l.get("texto", ""))
    quien = l.get("quien", "")
    return (quien + ": " + frase) if quien else frase


def pronunciacion(texto):
    """Ajustes solo para el audio: citas bíblicas legibles y pausas tras el nombre de quien habla."""
    texto = re.sub(r"\b([123]) (Samuel|Reyes|Crónicas|Corintios|Pedro|Juan|Tesalonicenses|Timoteo)",
                   lambda m: ORDINALES[m.group(1)] + " " + m.group(2), texto)
    texto = re.sub(r"(\d+):(\d+)-(\d+)", r"capítulo \1, versículos \2 al \3", texto)
    texto = re.sub(r"(\d+):(\d+)", r"capítulo \1, versículo \2", texto)
    for comilla in "«»“”":
        texto = texto.replace(comilla, "")
    texto = texto.replace("...", ",")
    return texto


def frases_del_juego():
    frases = list(FIJOS)
    for ruta in sorted(glob.glob(os.path.join(RAIZ, "datos", "capitulos", "*.json"))):
        with open(ruta, encoding="utf-8") as f:
            cap = json.load(f)
        lineas = cap.get("intro", []) + cap.get("epilogo", [])
        for v in cap.get("dialogos", {}).values():
            lineas += v
        for v in cap.get("final", {}).values():
            lineas += v
        frases += [frase_linea(l) for l in lineas]
        frases += [frase_linea({"texto": t}) for t in cap.get("aldeanos_frases", [])]
        frases += [o["ayuda"] for o in cap.get("objetivos", []) if o.get("ayuda")]
        rep = cap.get("repaso", {})
        if rep:
            frases.append("%s. %s" % (rep.get("versiculo", ""), rep.get("cita", "")))
            frases += [p.get("pregunta", "") for p in rep.get("preguntas", [])]
    vistas, unicas = set(), []
    for f in frases:
        if f.strip() and f.strip() not in vistas:
            vistas.add(f.strip())
            unicas.append(f.strip())
    return unicas


def main():
    os.makedirs(DESTINO, exist_ok=True)
    frases = frases_del_juego()
    necesarias = {clave(f): f for f in frases}
    marca = os.path.join(DESTINO, MARCA)
    actual = open(marca).read().strip() if os.path.exists(marca) else ""
    if actual != f"kokoro {VOZ} {VELOCIDAD}":
        for ruta in glob.glob(os.path.join(DESTINO, "*.ogg*")):
            os.remove(ruta)  # otra voz: se graba todo de nuevo
        with open(marca, "w") as f:
            f.write(f"kokoro {VOZ} {VELOCIDAD}\n")
    voz = KPipeline(lang_code="e", repo_id="hexgrad/Kokoro-82M")
    nuevas = 0
    for k, f in necesarias.items():
        destino = os.path.join(DESTINO, k + ".ogg")
        if os.path.exists(destino):
            continue
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            ruta_wav = tmp.name
        partes = [audio for _, _, audio in voz(pronunciacion(f), voice=VOZ, speed=VELOCIDAD)]
        sf.write(ruta_wav, np.concatenate(partes), 24000)
        # recorta silencios, limpia graves, comprime suave y empareja volumen; mono, Vorbis de baja tasa
        filtro = ("silenceremove=1:0:-50dB,areverse,silenceremove=1:0:-50dB,areverse,highpass=f=70,"
                  "acompressor=threshold=-20dB:ratio=2:attack=10:release=150,loudnorm=I=-16:TP=-1.5,aresample=24000")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", ruta_wav, "-af", filtro,
                        "-ac", "1", "-c:a", "libvorbis", "-q:a", "1", destino], check=True)
        os.remove(ruta_wav)
        nuevas += 1
        print("·", f[:70])
    sobrantes = 0
    for ruta in glob.glob(os.path.join(DESTINO, "*.ogg")):
        if os.path.basename(ruta)[:-4] not in necesarias:
            os.remove(ruta)
            if os.path.exists(ruta + ".import"):
                os.remove(ruta + ".import")
            sobrantes += 1
    total = sum(os.path.getsize(r) for r in glob.glob(os.path.join(DESTINO, "*.ogg")))
    print(f"{len(necesarias)} frases, {nuevas} grabadas ahora, {sobrantes} borradas; {total / 1e6:.1f} MB en assets/voz")


if __name__ == "__main__":
    sys.exit(main())
