# El llamado · prototipo 3D

## Estado

Implementado en Godot 4.7.2. El prototipo anterior de Canvas se conserva como referencia histórica; la versión actual se abre con `project.godot`.

El usuario confirmó aventura cristiana para celulares, vida de Jesús y un discípulo que lo acompaña. Actualizó la dirección visual a **3D de bloques y texturas pixeladas, con Minecraft como referencia estética**, y pidió que el jugador elija **primera o tercera persona**.

## Experiencia implementada

Explorar una aldea de Galilea desde los ojos del discípulo o viendo a su personaje. Se elige perspectiva al comenzar y se cambia durante la partida mediante V o el botón Cámara, conservando la misión. En tercera persona, un SpringArm3D acerca la cámara al encontrar obstáculos. En primera persona se oculta el cuerpo para evitar obstruir la vista.

El mundo usa geometría de cajas y texturas originales generadas de 16 × 16 píxeles, con filtrado de vecino más cercano. Las casas, el pozo y los troncos tienen colisiones; hay límites físicos en la orilla y en el mapa. Es una aldea acotada para probar la aventura.

## Recorrido

1. Elegir cámara y comenzar.
2. Conocer a Miriam junto al pozo.
3. Recoger la cesta bajo el olivo al sur.
4. Entregarla a Miriam.
5. Encontrar a Jesús junto a la orilla, al este.
6. Acercarse al sendero del norte y partir.

La misión de ayuda es una escena de enlace original. La escena de encuentro usa narración original sin atribuir frases inventadas a Jesús. El pasaje bíblico central y la identidad del discípulo siguen pendientes.

## Interacción

Joystick táctil a la izquierda; arrastre para mirar en la zona derecha. Botón contextual para hablar, recoger y partir. En escritorio se usan teclado y ratón. Los diálogos detienen al jugador y liberan el cursor. Solo se interactúa con objetivos cercanos y sin paredes de por medio.

## Validación realizada

- Carga y ejecución con Godot instalado.
- Elección inicial, alternancia de perspectivas y conservación de la misión.
- Cámara de tercera persona ante una pared.
- Movimiento real contra una casa y apoyo en el suelo.
- Entrada táctil simulada de joystick y liberación al soltar.
- Secuencia completa, bloqueos de pasos fuera de orden y comprobación de proximidad.
- Diálogos, desaparición visual y física de la cesta recogida, pantalla final.
- Render de ambas perspectivas y del menú inicial.

Las pruebas automatizadas están en `tests/godot/smoke.gd`. Las capturas se generan con `tests/godot/render_preview.gd` y requieren un entorno gráfico.

## Pendiente

- Prueba en celular físico, rendimiento y exportación Android/iOS.
- Identidad del discípulo, pasaje bíblico concreto, guion y arte definitivo.
- Público, tono y traducción de las futuras citas.
- Guardado de progreso y preferencia de cámara entre sesiones.
