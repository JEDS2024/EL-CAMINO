"""Genera todo el arte pixel de El Camino (texturas, sprites, íconos).

Uso:  python herramientas/generar_arte.py      (requiere Pillow)
Todo es arte original generado por código: se puede regenerar o retocar luego a mano.
"""
import os, random
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
R = random.Random(7)


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def var(c, d):
    return tuple(max(0, min(255, v + d)) for v in c[:3]) + (c[3],)


def guardar(img, carpeta, nombre):
    os.makedirs(os.path.join(RAIZ, carpeta), exist_ok=True)
    img.save(os.path.join(RAIZ, carpeta, nombre))


def lienzo(w=16, h=16, color=(0, 0, 0, 0)):
    return Image.new("RGBA", (w, h), color)


# ------------------------------------------------------------------ texturas de mundo
def ruido(base, amp, w=16, h=16, prob=1.0):
    im = lienzo(w, h, base)
    px = im.load()
    for y in range(h):
        for x in range(w):
            if R.random() < prob:
                px[x, y] = var(base, R.randint(-amp, amp))
    return im


def pasto():
    im = ruido(hexc("4f7a3a"), 10)
    px = im.load()
    for _ in range(22):
        x, y = R.randrange(16), R.randrange(1, 16)
        px[x, y] = hexc("6d9a45"); px[x, y - 1] = hexc("86b558")
    for _ in range(6):
        px[R.randrange(16), R.randrange(16)] = hexc("3b5c2c")
    if R.random() < 1:
        px[3, 11] = hexc("e8d36a"); px[12, 4] = hexc("d98bb8")
    return im


def camino():
    im = ruido(hexc("9b7b55"), 9)
    px = im.load()
    for _ in range(10):
        x, y = R.randrange(15), R.randrange(15)
        px[x, y] = hexc("b8996e"); px[x + 1, y] = hexc("7e6244")
    return im


def arena():
    im = ruido(hexc("d6bf86"), 8)
    px = im.load()
    for y in (4, 11):
        for x in range(16):
            if (x + y) % 5 < 3: px[x, y] = hexc("c4ab72")
    return im


def adoquin():
    im = lienzo(16, 16, hexc("6b6660"))
    px = im.load()
    piedras = [(0, 0, 7, 5), (8, 0, 15, 5), (0, 6, 4, 10), (5, 6, 11, 10), (12, 6, 15, 10), (0, 11, 7, 15), (8, 11, 15, 15)]
    for (a, b, c, d) in piedras:
        tono = var(hexc("8f8a82"), R.randint(-12, 12))
        for y in range(b, d):
            for x in range(a, c):
                px[x, y] = var(tono, R.randint(-5, 5))
        for x in range(a, c): px[x, b] = var(tono, 18)
    return im


def madera():
    im = lienzo(16, 16)
    px = im.load()
    for y in range(16):
        tabla = y // 4
        base = var(hexc("8a5a34"), [0, -10, 6, -4][tabla])
        for x in range(16):
            c = var(base, R.randint(-6, 6))
            if y % 4 == 3: c = hexc("5a3a22")
            if (x + tabla * 5) % 16 == 0: c = hexc("5a3a22")
            px[x, y] = c
    px[4, 1] = px[11, 9] = hexc("4a2e1a")
    return im


def muro():
    im = lienzo(16, 16, hexc("4d4a52"))
    px = im.load()
    for fila in range(4):
        off = 0 if fila % 2 == 0 else 4
        for b in range(-1, 3):
            x0 = b * 8 + off
            tono = var(hexc("7b7682"), R.randint(-14, 10))
            for y in range(fila * 4, fila * 4 + 3):
                for x in range(x0, x0 + 7):
                    if 0 <= x < 16: px[x, y] = var(tono, R.randint(-4, 4))
            for x in range(x0, x0 + 7):
                if 0 <= x < 16: px[x, fila * 4] = var(tono, 14)
    return im


def pared_casa():
    im = ruido(hexc("d9c9a8"), 6)
    px = im.load()
    viga = hexc("6b4527")
    for y in range(16):
        px[0, y] = px[15, y] = viga
    for x in range(16):
        px[x, 0] = px[x, 15] = viga
    for i in range(16):
        if 0 < i < 15:
            px[i, i] = viga
    # ventana
    for y in range(5, 10):
        for x in range(9, 13):
            px[x, y] = hexc("3a3048") if not (x == 11 or y == 7) else viga
    return im


def tejado():
    im = lienzo(16, 16)
    px = im.load()
    for y in range(16):
        for x in range(16):
            fila = y // 4
            col = (x + (2 if fila % 2 else 0)) // 4
            base = hexc("9c4a32") if (fila + col) % 3 else hexc("8a3f2b")
            c = var(base, R.randint(-6, 6))
            if y % 4 == 3: c = hexc("5e2a1e")
            if (x + (2 if fila % 2 else 0)) % 4 == 0: c = var(c, -18)
            px[x, y] = c
    return im


def agua():
    im = ruido(hexc("2f5d86"), 6)
    px = im.load()
    for _ in range(9):
        x, y = R.randrange(13), R.randrange(16)
        for k in range(3): px[x + k, y] = hexc("6fa4cf")
    return im


def roca():
    im = ruido(hexc("7d776f"), 14)
    px = im.load()
    for _ in range(5):
        x, y = R.randrange(15), R.randrange(15)
        px[x, y] = hexc("5c5750"); px[x + 1, y + 1] = hexc("a19a90")
    return im


def piedra_oscura():
    im = ruido(hexc("3d3a44"), 8)
    px = im.load()
    for _ in range(6):
        x, y = R.randrange(16), R.randrange(16)
        px[x, y] = hexc("6b5f8a")
    return im


def cebada():
    im = ruido(hexc("b8953e"), 10)
    px = im.load()
    for _ in range(30):
        x, y = R.randrange(16), R.randrange(2, 16)
        px[x, y] = hexc("d9b85a"); px[x, y - 1] = hexc("e8cf7a")
        if y > 2: px[x, y - 2] = hexc("f0dc8c")
    for _ in range(6):
        px[R.randrange(16), R.randrange(16)] = hexc("8a6a2a")
    return im


def tela():
    im = lienzo(16, 16)
    px = im.load()
    for y in range(16):
        for x in range(16):
            franja = (x // 4) % 2
            base = hexc("6a4a3a") if franja else hexc("a88a6a")
            px[x, y] = var(base, R.randint(-6, 6))
    return im


# ------------------------------------------------------------------ sprites de decorado
def arbol():
    im = lienzo(32, 48)
    px = im.load()
    for y in range(30, 48):
        for x in range(14, 18):
            px[x, y] = var(hexc("5b3a24"), R.randint(-8, 8))
    for y in range(0, 36):
        for x in range(32):
            cx, cy = 16, 18
            d = ((x - cx) / 15.5) ** 2 + ((y - cy) / 18) ** 2
            borde = d + R.uniform(-0.12, 0.12)
            if borde < 1:
                luz = (cx - x) * 0.6 + (cy - y) * 0.8
                base = hexc("3f6b34") if luz < 4 else hexc("5a8a40")
                if luz > 10: base = hexc("79a852")
                if R.random() < 0.12: base = hexc("2c4d26")
                px[x, y] = var(base, R.randint(-6, 6))
    for _ in range(6):
        x, y = R.randrange(6, 26), R.randrange(6, 28)
        if px[x, y][3]: px[x, y] = hexc("c9a24a")  # aceitunas / frutos
    return im


def arbusto(oscuro=False):
    im = lienzo(16, 16)
    px = im.load()
    for y in range(16):
        for x in range(16):
            d = ((x - 7.5) / 7.8) ** 2 + ((y - 10) / 6.8) ** 2 + R.uniform(-0.15, 0.15)
            if d < 1 and y > 2:
                base = hexc("4a7a38") if y > 8 else hexc("68a04a")
                if oscuro: base = var(base, -6)
                px[x, y] = var(base, R.randint(-8, 8))
    return im


def lampara(encendida):
    im = lienzo(16, 24)
    px = im.load()
    for y in range(10, 24):
        for x in range(7, 9):
            px[x, y] = hexc("4a3020")
    for x in range(4, 12):
        px[x, 23] = hexc("4a3020")
    for y in range(3, 10):
        for x in range(4, 12):
            borde = x in (4, 11) or y in (3, 9)
            if borde:
                px[x, y] = hexc("2d2a30")
            else:
                px[x, y] = hexc("ffd36b") if encendida else hexc("3b3a45")
    if encendida:
        px[7, 5] = px[8, 5] = hexc("fff3c4")
        px[7, 6] = px[8, 6] = hexc("ffffff")
    for x in range(5, 11):
        px[x, 2] = hexc("2d2a30")
    return im


def arco(abierto):
    im = lienzo(32, 32)
    px = im.load()
    for y in range(32):
        for x in range(32):
            dx = x - 15.5
            dentro_arco = (dx * dx + (y - 12) ** 2) < 100 or (abs(dx) < 10 and y >= 12)
            interior = (dx * dx + (y - 13) ** 2) < 49 or (abs(dx) < 7 and y >= 13)
            if dentro_arco and not interior:
                px[x, y] = var(hexc("8a8478"), R.randint(-10, 10))
            elif interior:
                if abierto:
                    t = (y / 32)
                    px[x, y] = (255, int(200 + 40 * (1 - t)), int(120 + 80 * (1 - t)), 200)
                else:
                    px[x, y] = (20, 18, 30, 230)
    return im


# ------------------------------------------------------------------ íconos y objetos
FORMAS = {
    "fe": [
        "......XX......",
        "......XX......",
        "......XX......",
        "..XXXXXXXXXX..",
        "..XXXXXXXXXX..",
        "......XX......",
        "......XX......",
        "......XX......",
        "......XX......",
        "......XX......",
        "......XX......",
    ],
    "esperanza": [
        "......XX......",
        ".....X..X.....",
        "......XX......",
        "......XX......",
        "...XXXXXXXX...",
        "......XX......",
        "......XX......",
        ".X....XX....X.",
        ".XX...XX...XX.",
        "..XX..XX..XX..",
        "...XXXXXXXX...",
    ],
    "amor": [
        "..XXX....XXX..",
        ".XXXXX..XXXXX.",
        "XXXXXXXXXXXXXX",
        "XXXXXXXXXXXXXX",
        "XXXXXXXXXXXXXX",
        ".XXXXXXXXXXXX.",
        "..XXXXXXXXXX..",
        "...XXXXXXXX...",
        ".....XXXX.....",
        "......XX......",
    ],
    "perdon": [
        "........XX....",
        ".......XXXX...",
        "......XXXXX.X.",
        "XX...XXXXXXXX.",
        ".XXXXXXXXXXX..",
        "..XXXXXXXXX...",
        "...XXXXXXX....",
        ".....XX.......",
        "....XX........",
    ],
    "luz": [
        "......XX......",
        ".....XXXX.....",
        "....XXXXXX....",
        "....XXXXXX....",
        "...XXXXXXXX...",
        "...XXXXXXXX...",
        "....XXXXXX....",
        ".....XXXX.....",
        "..XXXXXXXXXX..",
        "..XXXXXXXXXX..",
    ],
}
COLORES_SIMB = {"fe": "f2e6b8", "esperanza": "8fd3ff", "amor": "ff6f7d", "perdon": "f4f4ff", "luz": "ffd36b"}


def icono(nombre, color=None):
    forma = FORMAS[nombre]
    im = lienzo(16, 16)
    px = im.load()
    c = hexc(color or COLORES_SIMB[nombre])
    oy = (16 - len(forma)) // 2
    for y, fila in enumerate(forma):
        for x, ch in enumerate(fila):
            if ch == "X":
                px[x + 1, y + oy] = c
    # contorno oscuro
    base = im.copy()
    bp = base.load()
    for y in range(16):
        for x in range(16):
            if bp[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if 0 <= x + dx < 16 and 0 <= y + dy < 16 and bp[x + dx, y + dy][3] and bp[x + dx, y + dy][:3] != (30, 22, 40):
                        px[x, y] = hexc("1e1628")
                        break
    return im


def objeto_copa():  # copa de plata (Génesis 44:2)
    im = lienzo(16, 16)
    px = im.load()
    plata, sombra, brillo = hexc("c8ccd8"), hexc("8a90a0"), hexc("ffffff")
    for y in range(3, 8):
        for x in range(4 + (y - 3) // 2, 12 - (y - 3) // 2):
            px[x, y] = plata if x < 9 else sombra
    for y in range(8, 12):
        px[7, y] = plata; px[8, y] = sombra
    for x in range(5, 11):
        px[x, 12] = plata if x < 8 else sombra
    px[5, 4] = brillo
    return im


def objeto_espiga():  # espigas de cebada (Rut 2)
    im = lienzo(16, 16)
    px = im.load()
    for y in range(6, 15):
        px[8, y] = hexc("8a7a3a")
    for y in range(1, 8):
        for dx in (-1, 1):
            if y % 2 == 0:
                px[8 + dx, y] = hexc("e8cf7a"); px[8 + 2 * dx, y + 1] = hexc("c9a84a")
        px[8, y] = hexc("f0dc8c")
    return im


def objeto_piedra():  # piedra lisa del arroyo (1 Samuel 17:40)
    im = lienzo(16, 16)
    px = im.load()
    for y in range(16):
        for x in range(16):
            d = ((x - 7.5) / 5.5) ** 2 + ((y - 8.5) / 4.2) ** 2
            if d < 1:
                px[x, y] = hexc("b8b2a8") if (x + y) < 15 else hexc("8a847a")
    px[5, 6] = px[6, 6] = hexc("e8e4dc")
    return im


def objeto_pergamino():  # rollo de las Escrituras
    im = lienzo(16, 16)
    px = im.load()
    for y in range(3, 13):
        for x in range(4, 12):
            px[x, y] = hexc("e8dcb8")
        px[3, y] = px[12, y] = hexc("8a5a34")
    for y in (5, 7, 9):
        for x in range(5, 11):
            px[x, y] = hexc("6a5a4a") if x % 3 else hexc("e8dcb8")
    return im


def objeto_arpa():  # arpa de David (1 Samuel 16:23)
    im = lienzo(16, 16)
    px = im.load()
    madera = hexc("a86b30")
    for y in range(2, 15):
        px[3, y] = madera
    for x in range(3, 13):
        px[x, 2] = madera
    for k in range(10):
        px[12 - k // 2, 3 + k] = madera
    for x in (5, 7, 9):
        for y in range(3, 3 + (x - 2)):
            px[x, y] = hexc("f0dc8c")
    return im


def objeto_hilo():
    im = lienzo(16, 16)
    px = im.load()
    for y in range(4, 13):
        for x in range(4, 12):
            px[x, y] = hexc("c2263a") if (y % 2 == 0) else hexc("e03b4f")
    for x in range(3, 13):
        px[x, 3] = px[x, 13] = hexc("8a5a34")
    for k in range(5):
        px[12 + k // 2, 8 + k] = hexc("e03b4f") if 12 + k // 2 < 16 and 8 + k < 16 else (0, 0, 0, 0)
    return im


def objeto_pieza():
    im = lienzo(16, 16)
    px = im.load()
    for y in range(5, 13):
        for x in range(3, 13):
            if x - 3 + (12 - y) < 14:
                px[x, y] = var(hexc("a59d8f"), R.randint(-10, 10))
    for x in range(4, 12):
        px[x, 8] = hexc("5ea8d6")
    return im


def objeto_pan():
    im = lienzo(16, 16)
    px = im.load()
    for y in range(6, 13):
        for x in range(2, 14):
            d = ((x - 7.5) / 6) ** 2 + ((y - 9.5) / 3.6) ** 2
            if d < 1:
                px[x, y] = hexc("d89a4e") if y > 7 else hexc("eab56a")
    for x in (5, 8, 11):
        px[x, 8] = hexc("a86b30")
    return im


# ------------------------------------------------------------------ personajes
# Hoja de 3 columnas (quieto, paso1, paso2) x 4 filas (frente, espalda, izquierda, derecha) de 16x24.
def personaje(p):
    W, H = 16, 24
    hoja = lienzo(W * 3, H * 4)
    for fila, dirn in enumerate(("frente", "espalda", "izq", "der")):
        for col in range(3):
            im = lienzo(W, H)
            dibujar(im.load(), dirn, col, p)
            hoja.paste(im, (col * W, fila * H))
    return hoja


def rect(px, x0, y0, x1, y1, c):
    for y in range(y0, y1):
        for x in range(x0, x1):
            if 0 <= x < 16 and 0 <= y < 24:
                px[x, y] = c


def dibujar(px, d, f, p):
    piel, pelo, tunica, manto = hexc(p["piel"]), hexc(p["pelo"]), hexc(p["tunica"]), hexc(p.get("manto", p["tunica"]))
    oscuro = var(tunica, -35)
    nino = p.get("nino", False)
    top = 6 if nino else 1
    lado = d in ("izq", "der")
    # piernas
    pierna = hexc(p.get("pantalon", "4a3a2e"))
    sandalia = hexc("3a2618")
    paso = [0, 1, -1][f]
    if lado:
        rect(px, 6 + paso, 19, 8 + paso, 23, pierna); rect(px, 8 - paso, 19, 10 - paso, 23, var(pierna, -15))
        rect(px, 6 + paso, 23, 9 + paso, 24, sandalia)
    else:
        rect(px, 5, 19 - (1 if paso == 1 else 0), 7, 23, pierna); rect(px, 9, 19 - (1 if paso == -1 else 0), 11, 23, pierna)
        rect(px, 5, 23, 7, 24, sandalia); rect(px, 9, 23, 11, 24, sandalia)
    # cuerpo / túnica
    cy0 = top + 8
    rect(px, 4, cy0, 12, 20, tunica)
    rect(px, 4, cy0 + 5, 12, cy0 + 6, hexc(p.get("cinto", "6b4527")))
    rect(px, 4, 19, 12, 20, oscuro)
    if p.get("delantal"):
        rect(px, 5, cy0 + 6, 11, 19, hexc("e8e0cc"))
    if p.get("manto"):
        if d == "espalda":
            rect(px, 3, cy0, 13, 19, manto)
        elif lado:
            x0 = 9 if d == "izq" else 3
            rect(px, x0, cy0, x0 + 4, 19, manto)
        else:
            rect(px, 3, cy0, 5, 19, manto); rect(px, 11, cy0, 13, 19, manto)
    # brazos
    brazo = [0, 1, -1][f]
    if lado:
        bx = 7
        rect(px, bx - brazo, cy0 + 1, bx + 2 - brazo, cy0 + 7, oscuro)
        rect(px, bx - brazo, cy0 + 7, bx + 2 - brazo, cy0 + 8, piel)
    else:
        rect(px, 3, cy0 + 1 + max(0, brazo), 4, cy0 + 7 + max(0, brazo), oscuro)
        rect(px, 12, cy0 + 1 + max(0, -brazo), 13, cy0 + 7 + max(0, -brazo), oscuro)
        rect(px, 3, cy0 + 7 + max(0, brazo), 4, cy0 + 8 + max(0, brazo), piel)
        rect(px, 12, cy0 + 7 + max(0, -brazo), 13, cy0 + 8 + max(0, -brazo), piel)
    # objeto en mano (candil del Caminante / bastón)
    if p.get("candil") and d != "espalda":
        hx = 13 if d in ("frente", "der") else 1
        rect(px, hx, cy0 + 6, hx + 2, cy0 + 9, hexc("ffd36b")); px[hx, cy0 + 5] = hexc("2d2a30")
    if p.get("baston"):
        hx = 2 if d != "izq" else 13
        rect(px, hx, top + 4, hx + 1, 24, hexc("7a5230"))
    # cabeza
    hy = top
    rect(px, 5, hy + 1, 11, hy + 8, piel)
    if p.get("capucha"):
        c = manto
        rect(px, 4, hy, 12, hy + 3, c)
        rect(px, 4, hy, 5, hy + 8, c); rect(px, 11, hy, 12, hy + 8, c)
        if d == "espalda":
            rect(px, 4, hy, 12, hy + 9, c)
        elif lado:
            x0 = 8 if d == "izq" else 4
            rect(px, x0, hy, x0 + 4, hy + 8, c)
    else:
        estilo = p.get("peinado", "corto")
        rect(px, 5, hy, 11, hy + 2, pelo)
        if d == "espalda":
            rect(px, 5, hy, 11, hy + 7 + (3 if estilo == "largo" else 0), pelo)
        elif lado:
            x0 = 8 if d == "izq" else 5
            rect(px, x0, hy, x0 + 3, hy + 5 + (4 if estilo == "largo" else 0), pelo)
        else:
            rect(px, 5, hy, 6, hy + 4 + (5 if estilo == "largo" else 0), pelo)
            rect(px, 10, hy, 11, hy + 4 + (5 if estilo == "largo" else 0), pelo)
        if estilo == "panuelo":
            rect(px, 4, hy, 12, hy + 2, hexc(p.get("panuelo", "c2263a")))
        if estilo == "calvo":
            rect(px, 5, hy, 11, hy + 2, piel)
            if d != "espalda":
                rect(px, 5, hy + 2, 6, hy + 5, pelo); rect(px, 10, hy + 2, 11, hy + 5, pelo)
    # cara
    ojo = hexc("1e1628")
    if d == "frente":
        px[6, hy + 4] = ojo; px[9, hy + 4] = ojo
        if p.get("barba"):
            rect(px, 5, hy + 5, 11, hy + 9, hexc(p["barba"]))
            px[7, hy + 6] = px[8, hy + 6] = var(piel, -30)
        else:
            px[7, hy + 6] = px[8, hy + 6] = var(piel, -40)
    elif d == "izq":
        px[6, hy + 4] = ojo
        if p.get("barba"): rect(px, 5, hy + 5, 9, hy + 9, hexc(p["barba"]))
    elif d == "der":
        px[9, hy + 4] = ojo
        if p.get("barba"): rect(px, 7, hy + 5, 11, hy + 9, hexc(p["barba"]))


PERSONAJES = {
    "ezra": dict(piel="c68b5e", pelo="3a2416", tunica="b5643a", pantalon="4a3a2e", cinto="e0b04a", peinado="corto",
                 manto="7a3b28"),
    "caminante": dict(piel="b07a52", pelo="2b1d14", tunica="8a8a92", manto="5e5d6b", capucha=True, candil=True,
                      barba="3a2a1e"),
    "marta": dict(piel="d39b70", pelo="5a3420", tunica="6a7fb0", delantal=True, peinado="panuelo", panuelo="d9b25a"),
    "simeon": dict(piel="c99470", pelo="e8e4dc", tunica="5d6b4a", barba="efeae0", peinado="calvo", baston=True),
    "tomas": dict(piel="a8714a", pelo="1e1610", tunica="7b4f8f", peinado="corto", barba="1e1610"),
    "lia": dict(piel="c68b5e", pelo="2a1a12", tunica="d0796a", peinado="largo", nino=True),
    "noemi": dict(piel="b9845a", pelo="1a120c", tunica="3f8f86", peinado="panuelo", panuelo="e8e0cc"),
    "jared": dict(piel="9c6844", pelo="241812", tunica="5a4a3a", peinado="corto", barba="241812", manto="3a3028"),
    "abuela": dict(piel="c99470", pelo="d8d4cc", tunica="7a5a8a", peinado="panuelo", panuelo="5a4a6a", baston=True),
    "vigia": dict(piel="8f5a3a", pelo="140e0a", tunica="3a4a6a", manto="2a3048", peinado="corto"),
}


def main():
    tex = {"cebada": cebada, "tela": tela, "pasto": pasto, "camino": camino, "arena": arena, "adoquin": adoquin, "madera": madera, "muro": muro,
           "pared_casa": pared_casa, "tejado": tejado, "agua": agua, "roca": roca, "piedra_oscura": piedra_oscura}
    for n, f in tex.items():
        guardar(f(), "texturas", n + ".png")
    guardar(arbol(), "sprites", "arbol.png")
    guardar(arbusto(), "sprites", "arbusto.png")
    guardar(arbusto(True), "sprites", "arbusto_secreto.png")
    guardar(lampara(False), "sprites", "lampara_apagada.png")
    guardar(lampara(True), "sprites", "lampara_encendida.png")
    guardar(arco(False), "sprites", "arco_cerrado.png")
    guardar(arco(True), "sprites", "arco_abierto.png")
    for n in FORMAS:
        guardar(icono(n), "iconos", n + ".png")
    guardar(objeto_hilo(), "iconos", "hilo.png")
    guardar(objeto_pieza(), "iconos", "pieza.png")
    guardar(objeto_pan(), "iconos", "pan.png")
    for n, f in {"copa": objeto_copa, "espiga": objeto_espiga, "piedra": objeto_piedra,
                 "pergamino": objeto_pergamino, "arpa": objeto_arpa}.items():
        guardar(f(), "iconos", n + ".png")
    # los personajes ahora son modelos 3D (scripts/personaje_3d.gd); ya no se generan sprites
    print("arte generado en", os.path.abspath(RAIZ))


if __name__ == "__main__":
    main()
