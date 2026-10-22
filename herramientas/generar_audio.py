"""Compone la música y los efectos de sonido de El Camino (todo original, sintetizado).

Uso:  python3 herramientas/generar_audio.py     (requiere numpy y ffmpeg con libvorbis)
Cada tema es un bucle perfecto: la reverberación se calcula de forma circular.
"""
import os, subprocess, tempfile, wave
import numpy as np

SR = 22050
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rng = np.random.default_rng(3)


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


# ------------------------------------------------------------------ instrumentos
def arpa(f, dur, vel=0.3):
    t = np.arange(int(dur * SR)) / SR
    onda = np.sin(2 * np.pi * f * t) + 0.45 * np.sin(4 * np.pi * f * t) * np.exp(-t * 3) + 0.2 * np.sin(6 * np.pi * f * t) * np.exp(-t * 6)
    return onda * np.exp(-t * 2.2) * (1 - np.exp(-t * 400)) * vel


def laud(f, dur, vel=0.3):  # pulsado más seco, con un poco de "zumbido"
    t = np.arange(int(dur * SR)) / SR
    onda = sum(np.sin(2 * np.pi * f * k * t) / k ** 1.3 * np.exp(-t * (2 + k * 1.5)) for k in range(1, 7))
    return onda * (1 - np.exp(-t * 600)) * vel


def flauta(f, dur, vel=0.22):
    t = np.arange(int(dur * SR)) / SR
    vib = 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1, t / 0.4)
    fase = 2 * np.pi * f * np.cumsum(1 + vib) / SR
    onda = np.sin(fase) + 0.12 * np.sin(2 * fase) + 0.05 * rng.standard_normal(len(t)) * np.exp(-t * 8)
    env = np.minimum(1, t / 0.08) * np.minimum(1, (dur - t) / 0.15)
    return onda * np.clip(env, 0, 1) * vel


def colchon(fs, dur, vel=0.08):  # acorde suave sostenido
    t = np.arange(int(dur * SR)) / SR
    onda = sum(np.sin(2 * np.pi * f * t + 0.3 * np.sin(2 * np.pi * 0.3 * t)) + 0.3 * np.sin(4 * np.pi * f * t) for f in fs)
    env = np.minimum(1, t / 0.6) * np.minimum(1, (dur - t) / 0.6)
    return onda * np.clip(env, 0, 1) * vel / len(fs)


def tambor(dur=0.5, vel=0.4, agudo=False):  # tambor de marco
    t = np.arange(int(dur * SR)) / SR
    f = (220 if agudo else 85) * np.exp(-t * 8) + (160 if agudo else 55)
    onda = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * (14 if agudo else 7))
    onda += rng.standard_normal(len(t)) * np.exp(-t * 40) * (0.25 if agudo else 0.1)
    return onda * vel


def campana(f, dur, vel=0.18):
    t = np.arange(int(dur * SR)) / SR
    onda = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t * d) for r, a, d in ((1, 1, 1.6), (2.76, 0.4, 3), (5.4, 0.2, 5)))
    return onda * vel


def poner(pista, inicio, señal):
    i = int(inicio * SR) % len(pista)
    fin = i + len(señal)
    if fin <= len(pista):
        pista[i:fin] += señal
    else:  # da la vuelta: el bucle no se corta
        corte = len(pista) - i
        pista[i:] += señal[:corte]
        pista[:fin - len(pista)] += señal[corte:]


def reverb_circular(x, seg=1.6, mezcla=0.28):
    n = len(x)
    t = np.arange(int(seg * SR)) / SR
    ir = rng.standard_normal(len(t)) * np.exp(-t * 3.2)
    ir[0] = 0
    ir_full = np.zeros(n)
    ir_full[:len(ir)] = ir / np.sqrt(np.sum(ir ** 2))
    mojado = np.real(np.fft.ifft(np.fft.fft(x) * np.fft.fft(ir_full)))
    return x * (1 - mezcla) + mojado * mezcla


# ------------------------------------------------------------------ composición
def componer(bpm, raiz, escala, acordes, inst_arpegio, melodia=True, tambores=False, compases=8, campanas=False, semilla=1):
    r = np.random.default_rng(semilla)
    pulso = 60.0 / bpm
    dur = compases * 4 * pulso
    pista = np.zeros(int(dur * SR))
    grados = lambda g, oct=0: raiz + escala[g % len(escala)] + 12 * (g // len(escala) + oct)
    nota_mel = 7
    for c in range(compases):
        acorde = acordes[c % len(acordes)]  # grados de la escala (fundamental)
        triada = [grados(acorde), grados(acorde + 2), grados(acorde + 4)]
        t0 = c * 4 * pulso
        poner(pista, t0, colchon([hz(m - 12) for m in triada], 4 * pulso + 0.3))
        poner(pista, t0, inst_arpegio(hz(triada[0] - 24), 4 * pulso, 0.22))
        patron = [0, 1, 2, 1, 0, 2, 1, 2]
        for k, p in enumerate(patron):
            poner(pista, t0 + k * pulso / 2, inst_arpegio(hz(triada[p]), pulso * 1.6, 0.16 + 0.04 * (k % 4 == 0)))
        if tambores:
            for b in range(4):
                poner(pista, t0 + b * pulso, tambor(vel=0.35 if b % 2 == 0 else 0.0, agudo=False))
                poner(pista, t0 + b * pulso + pulso / 2, tambor(vel=0.12, agudo=True))
        if campanas and c % 2 == 0:
            poner(pista, t0, campana(hz(triada[2] + 12), 3.0))
        if melodia:
            # melodía cantable: notas del acorde en tiempos fuertes, pasos de escala en medio
            ritmo = [2, 1, 1] if c % 2 == 0 else [1, 1, 2]
            b = 0
            for d in ritmo:
                if b == 0:
                    opciones = [acorde, acorde + 2, acorde + 4]
                    nota_mel = min(opciones, key=lambda g: abs(g + 7 - nota_mel) + r.random() * 1.5) + 7
                else:
                    nota_mel += r.choice([-1, 1, 1, 2, -2])
                    nota_mel = int(np.clip(nota_mel, 5, 13))
                poner(pista, t0 + b * pulso, flauta(hz(grados(nota_mel)), d * pulso * 0.95))
                b += d
    pista = reverb_circular(pista)
    return pista / (np.max(np.abs(pista)) + 1e-9) * 0.7


# escalas en semitonos
MAYOR = [0, 2, 4, 5, 7, 9, 11]
MENOR = [0, 2, 3, 5, 7, 8, 10]
DORICA = [0, 2, 3, 5, 7, 9, 10]
FRIGIA_DOM = [0, 1, 4, 5, 7, 8, 10]  # sonido de Oriente Medio

TEMAS = {
    "titulo": dict(bpm=70, raiz=62, escala=MAYOR, acordes=[0, 5, 3, 4], inst_arpegio=arpa, campanas=True, semilla=11),
    "jose": dict(bpm=84, raiz=62, escala=FRIGIA_DOM, acordes=[0, 1, 0, 6], inst_arpegio=laud, tambores=True, semilla=21),
    "rut": dict(bpm=90, raiz=67, escala=MAYOR, acordes=[0, 3, 4, 0, 5, 3, 4, 0], inst_arpegio=arpa, semilla=31),
    "david": dict(bpm=100, raiz=64, escala=DORICA, acordes=[0, 6, 3, 0], inst_arpegio=laud, tambores=True, semilla=41),
    "nehemias": dict(bpm=74, raiz=57, escala=MENOR, acordes=[0, 5, 2, 6], inst_arpegio=arpa, campanas=True, semilla=51),
    "emaus": dict(bpm=66, raiz=65, escala=MAYOR, acordes=[0, 5, 3, 4], inst_arpegio=arpa, semilla=61),
}


# ------------------------------------------------------------------ ambientes (bucles de 24 s)
def _filtro(x, alfa):
    # paso bajo de un polo, vectorizado con la fórmula de suma acumulada aproximada
    y = np.empty_like(x)
    acc = 0.0
    for i in range(0, len(x), 256):
        bloque = x[i:i + 256]
        out = np.empty_like(bloque)
        for k, v in enumerate(bloque):
            acc += alfa * (v - acc)
            out[k] = acc
        y[i:i + 256] = out
    return y


def viento(n, fuerza=0.35):
    base = _filtro(rng.standard_normal(n), 0.02)
    t = np.arange(n) / SR
    rafaga = 0.6 + 0.4 * np.sin(2 * np.pi * t / (n / SR) * 3) * np.sin(2 * np.pi * t / (n / SR) * 2 + 1)
    return base / (np.max(np.abs(base)) + 1e-9) * rafaga * fuerza


def pajaro(dur=0.35, f0=None):
    t = np.arange(int(dur * SR)) / SR
    f0 = f0 or rng.uniform(2600, 4200)
    f = f0 + 900 * np.sin(2 * np.pi * rng.uniform(8, 16) * t)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / dur) ** 2 * 0.12


def grillo(dur=0.6):
    t = np.arange(int(dur * SR)) / SR
    pulso = (np.sin(2 * np.pi * 28 * t) > 0.3).astype(float)
    return np.sin(2 * np.pi * 4300 * t) * pulso * np.sin(np.pi * t / dur) * 0.05


def murmullo(n):
    voces = sum(_filtro(rng.standard_normal(n), a) for a in (0.05, 0.08))
    voces -= _filtro(voces, 0.006)  # quita el retumbo
    t = np.arange(n) / SR
    voces *= 0.7 + 0.3 * np.sin(2 * np.pi * t * 0.35) ** 2
    return voces / (np.max(np.abs(voces)) + 1e-9) * 0.22


def ambiente(tipo, seg=24.0):
    n = int(seg * SR)
    pista = np.zeros(n)
    if tipo in ("campo", "tarde", "ciudad"):
        pista += viento(n, 0.25 if tipo != "ciudad" else 0.12)
    if tipo == "noche":
        pista += viento(n, 0.12)
    if tipo == "ciudad":
        pista += murmullo(n)
    if tipo in ("campo", "ciudad", "tarde"):
        for _ in range(14 if tipo == "campo" else 6):
            t0 = rng.uniform(0, seg)
            for k in range(rng.integers(1, 4)):
                poner(pista, t0 + k * 0.22, pajaro())
    if tipo in ("noche", "tarde"):
        for _ in range(60 if tipo == "noche" else 18):
            poner(pista, rng.uniform(0, seg), grillo())
    return pista / (np.max(np.abs(pista)) + 1e-9) * 0.6


# ------------------------------------------------------------------ efectos
def sfx():
    s = {}
    t = lambda d: np.arange(int(d * SR)) / SR
    s["dialogo"] = np.sin(2 * np.pi * 880 * t(0.04)) * np.exp(-t(0.04) * 60) * 0.25
    s["seleccion"] = np.concatenate([arpa(hz(76), 0.09, 0.4), arpa(hz(83), 0.25, 0.4)])
    sub = np.zeros(int(0.9 * SR))
    for k, m in enumerate([79, 83, 86, 91]):
        poner(sub, k * 0.07, campana(hz(m), 0.6, 0.25))
    s["hallazgo"] = sub
    lam = rng.standard_normal(int(0.5 * SR)) * np.exp(-t(0.5) * 9) * 0.15
    lam = np.convolve(lam, np.ones(30) / 30, mode="same")
    lam2 = np.zeros(int(1.2 * SR))
    poner(lam2, 0, lam)
    poner(lam2, 0.12, campana(hz(81), 1.0, 0.3))
    s["lampara"] = lam2
    ex = np.zeros(int(1.6 * SR))
    for k, m in enumerate([72, 76, 79]):
        poner(ex, k * 0.12, arpa(hz(m), 1.2, 0.35))
    poner(ex, 0.36, colchon([hz(72), hz(76), hz(79), hz(84)], 1.2, 0.5))
    s["exito"] = ex
    fa = np.zeros(int(0.7 * SR))
    poner(fa, 0, arpa(hz(57), 0.4, 0.3))
    poner(fa, 0.18, arpa(hz(53), 0.5, 0.3))
    s["fallo"] = fa
    vi = np.zeros(int(1.0 * SR))
    poner(vi, 0, campana(hz(88), 0.9, 0.22))
    poner(vi, 0.08, campana(hz(93), 0.7, 0.18))
    s["virtud"] = vi
    cap = np.zeros(int(3.0 * SR))
    for k, m in enumerate([67, 72, 76, 79, 84]):
        poner(cap, k * 0.16, arpa(hz(m), 2.0, 0.35))
    poner(cap, 0.8, colchon([hz(60), hz(67), hz(72), hz(76)], 2.0, 0.6))
    poner(cap, 0.8, campana(hz(84), 2.0, 0.25))
    s["capitulo"] = cap
    pi = np.zeros(int(0.8 * SR))
    for k in range(3):
        poner(pi, k * 0.15, tambor(0.4, 0.5))
    s["mecanismo"] = pi
    co = np.zeros(int(0.5 * SR))
    poner(co, 0, arpa(hz(84), 0.4, 0.3))
    poner(co, 0.1, arpa(hz(88), 0.4, 0.3))
    s["correcto"] = co
    return s


def guardar_ogg(nombre, señal):
    os.makedirs(RAIZ, exist_ok=True)
    estereo = np.stack([señal, señal], 1)
    pcm = (np.clip(estereo, -1, 1) * 32767).astype("<i2")
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        ruta_wav = tmp.name
    with wave.open(ruta_wav, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    destino = os.path.join(RAIZ, nombre + ".ogg")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", ruta_wav, "-c:a", "libvorbis", "-q:a", "3", destino], check=True)
    os.remove(ruta_wav)


def main():
    for nombre, cfg in TEMAS.items():
        guardar_ogg("musica_" + nombre, componer(**cfg))
        print("música", nombre)
    for tipo in ("campo", "ciudad", "noche", "tarde"):
        guardar_ogg("amb_" + tipo, ambiente(tipo))
        print("ambiente", tipo)
    for nombre, señal in sfx().items():
        guardar_ogg("sfx_" + nombre, señal / (np.max(np.abs(señal)) + 1e-9) * 0.8)
    print("efectos listos en", os.path.abspath(RAIZ))


if __name__ == "__main__":
    main()
