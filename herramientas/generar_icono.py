"""Icono original de El Camino: un candil que ilumina el sendero, en pixel art.

Genera el SVG editable y los PNG de Android, incluido el icono adaptativo.
Uso: python3 herramientas/generar_icono.py (requiere Pillow).
"""
from pathlib import Path
from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parent.parent
DESTINO = RAIZ / 'assets' / 'iconos'
DESTINO.mkdir(parents=True, exist_ok=True)
formas = []

def rect(caja, color):
    formas.append(('rect', caja, color))

def pol(puntos, color):
    formas.append(('pol', puntos, color))

# Paisaje a contraluz: colores propios, sin recursos de terceros.
rect((0, 0, 64, 64), '#102a35')
rect((4, 4, 60, 60), '#173e49')
rect((8, 8, 56, 56), '#20505a')
rect((12, 12, 52, 48), '#29606a')
rect((18, 16, 46, 43), '#377478')
pol([(0,38),(10,28),(17,35),(24,28),(35,39),(46,29),(53,34),(64,24),(64,64),(0,64)], '#183e47')
pol([(0,45),(13,37),(23,45),(40,40),(53,43),(64,36),(64,64),(0,64)], '#102d36')
pol([(29,38),(35,38),(34,44),(29,48),(32,51),(41,55),(46,64),(18,64),(22,57),(27,54),(23,50),(24,46),(30,42)], '#a1733f')
pol([(31,39),(33,39),(32,44),(27,48),(29,51),(37,55),(41,64),(24,64),(26,58),(31,55),(25,51),(25,47),(31,43)], '#e2b467')
# Luz escalonada detrás de la linterna.
rect((20,23,44,37), '#41746d')
rect((23,20,41,39), '#648966')
rect((25,22,39,37), '#a5a366')
# Asa y carcasa: sombra desplazada a la derecha para dar volumen.
rect((28,11,38,14), '#10212d')
rect((25,14,29,21), '#10212d')
rect((35,14,39,21), '#10212d')
rect((29,10,35,13), '#f5cc7b')
rect((26,13,29,19), '#d4994f')
rect((35,13,38,19), '#91633c')
rect((23,20,43,24), '#10212d')
rect((21,24,25,36), '#10212d')
rect((39,24,43,36), '#10212d')
rect((23,36,43,41), '#10212d')
rect((25,41,41,44), '#10212d')
rect((24,19,40,22), '#e4ad5b')
rect((21,22,43,25), '#9a653c')
rect((24,22,39,24), '#ffe2a0')
rect((24,25,40,36), '#f4b44e')
rect((25,25,28,36), '#ffda75')
rect((36,25,39,36), '#cf8036')
rect((28,25,36,36), '#ffe69c')
rect((30,27,34,35), '#fff6ce')
rect((31,26,33,35), '#ffffff')
rect((22,25,25,36), '#d29a4b')
rect((39,25,42,36), '#865437')
rect((23,36,41,39), '#f7ca79')
rect((25,39,39,42), '#a5703f')
rect((27,39,35,40), '#ffdf98')
# Destellos cuadrados legibles incluso con el icono reducido.
for caja in [(15,21,17,23),(46,18,48,20),(45,32,46,33),(18,32,19,33)]:
    rect(caja, '#e6cd8c')


def dibujar(formas_a_dibujar, transparente=False):
    imagen = Image.new('RGBA', (64,64), (0,0,0,0) if transparente else '#102a35')
    d = ImageDraw.Draw(imagen)
    for tipo, geometria, color in formas_a_dibujar:
        if tipo == 'rect':
            x1,y1,x2,y2 = geometria
            d.rectangle((x1,y1,x2-1,y2-1), fill=color)
        else:
            d.polygon(geometria, fill=color)
    return imagen

principal = dibujar(formas)
principal.resize((1024,1024), Image.Resampling.NEAREST).save(DESTINO/'principal.png')
# Todo el motivo cabe en el círculo seguro de 66/108 del icono adaptativo.
fondo = dibujar(formas[:11]).resize((432,432), Image.Resampling.NEAREST)
fondo.save(DESTINO/'fondo.png')
frente = Image.new('RGBA', (432,432))
motivo = dibujar(formas[11:], True).resize((324,324), Image.Resampling.NEAREST)
frente.alpha_composite(motivo, (54,54))
frente.save(DESTINO/'frente.png')
svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 64 64" shape-rendering="crispEdges">']
for tipo, geometria, color in formas:
    if tipo == 'rect':
        x1,y1,x2,y2 = geometria
        svg.append(f'<rect x="{x1}" y="{y1}" width="{x2-x1}" height="{y2-y1}" fill="{color}"/>')
    else:
        puntos = ' '.join(f'{x},{y}' for x,y in geometria)
        svg.append(f'<polygon points="{puntos}" fill="{color}"/>')
svg.append('</svg>')
(RAIZ/'icon.svg').write_text('\n'.join(svg)+'\n')
print('Iconos generados en', DESTINO)
