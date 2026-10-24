# Actualizador integrado de El Camino (desde 0.11)

## Uso en Android

En Ajustes pulsa **Buscar actualizaciones**. Si hay una versión posterior, el juego muestra su nombre y tamaño y ofrece **Descargar actualización**. La descarga se guarda en archivos privados del juego y se puede cancelar. Al terminar se comprueban tamaño y SHA-256 antes de habilitar **Instalar actualización**.

Android puede pedir que permitas a El Camino instalar aplicaciones. Concede el permiso, vuelve al juego y pulsa Instalar. Android muestra la confirmación «Actualizar»: no se desinstala la aplicación. Si cancelas la instalación, puedes intentarlo otra vez. La descarga verificada se conserva incluso al reiniciar el juego.

El juego guarda el progreso antes de abrir el instalador desde una partida. Desde la pantalla inicial conserva el guardado existente, sin sobrescribirlo con el mapa de demostración. Android exige mismo paquete y firma para reemplazar la aplicación; un APK de otro paquete o con un código inesperado se rechaza antes de abrir el instalador.

La 0.11 contiene por primera vez el actualizador. Para pasar de la 0.10 a la 0.11 hay que abrir manualmente el APK nuevo una vez y elegir Actualizar. Las versiones posteriores se podrán iniciar desde Ajustes.

## Entrega de prueba 0.12

La 0.12 activa la lectura en voz alta al abrirla por primera vez, tanto en instalaciones nuevas como al actualizar. La marca `lectura_por_defecto_v12` se guarda en ajustes: si después el jugador apaga la lectura, los siguientes inicios respetan esa elección. Conserva los demás ajustes y el progreso. Incluye un candil dorado sobre un camino como nuevo icono, con variantes normal y adaptativa para Android. Sus recursos originales se regeneran con `python3 herramientas/generar_icono.py`.

## Publicar una entrega

El repositorio `JEDS2024/EL-CAMINO` ya es público. En `project.godot` está configurado:

```text
https://github.com/JEDS2024/EL-CAMINO/releases/latest/download/actualizacion.json
```

No basta con subir el código: cada release publicada debe incluir **el APK y actualizacion.json como archivos adjuntos**. No necesita credenciales dentro del juego. Antes de publicar una release nueva comprueba que tiene ambos archivos. GitHub no usa borradores ni prereleases como `latest`.

1. Aumentar `version/code` y `version/name` en `export_presets.cfg`, y `actualizaciones/version_code` y `application/config/version` en `project.godot`. No cambiar `com.jader.elcamino` ni la clave de firma de las instalaciones existentes.
2. Exportar el APK. Por ejemplo, para la entrega 0.12:

```bash
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ANDROID_HOME=~/Android/Sdk \
  ~/Juegos/herramientas/godot --headless --path . --export-debug Android builds/ElCamino-v0.12.apk
python3 herramientas/verificar_actualizacion.py builds/ElCamino-v0.11.apk builds/ElCamino-v0.12.apk
python3 herramientas/preparar_actualizacion.py builds/ElCamino-v0.12.apk \
  --url https://github.com/JEDS2024/EL-CAMINO/releases/download/v0.12/ElCamino-v0.12.apk
```

3. En GitHub → Releases → Create a new release, elegir etiqueta `v0.12` y el commit de esta entrega. Adjuntar `builds/ElCamino-v0.12.apk` y `builds/actualizacion.json`, y publicar como release normal.
4. Para la siguiente entrega repetir con código 13 y versión/etiqueta `0.13`/`v0.13`. Desde 0.11 se ofrecerá esa nueva versión.

Las herramientas no publican archivos ni cambian la visibilidad del repositorio. Los APK actuales usan la misma firma de prueba de Godot; `verificar_actualizacion.py` comprueba paquete, firma y aumento de código. Antes de una distribución definitiva hay que planificar la clave de publicación: cambiar de firma sin una rotación válida impide actualizar las instalaciones anteriores.

## Implementación

- `scripts/actualizaciones/actualizador.gd`: servicio persistente de consulta y descarga, cancelación, progreso, integridad y recuperación tras reiniciar.
- `scripts/actualizaciones/android.gd`: acceso al instalador nativo con `AndroidRuntime`/`JavaClassWrapper` y `FileProvider`, ya incluidos en Godot 4.7. No requiere un plugin externo ni activar Gradle.
- `scripts/ui/panel_actualizaciones.gd`: botones y estado dentro del área desplazable de Ajustes. Cerrar Ajustes no corta una descarga activa.
- `permissions/internet` y `android.permission.REQUEST_INSTALL_PACKAGES` en la exportación Android. No se solicita acceso general al almacenamiento.
- Todas las URL y redirecciones deben usar HTTPS, con validación TLS normal. Manifiestos limitados a 64 KiB y APK a 250 MiB; se rechazan versiones inválidas, archivos truncados y huellas incorrectas.
- La huella verifica integridad; Android comprueba la firma al instalar. No se promete instalación silenciosa.

En PC se puede consultar la versión publicada, pero los botones de descarga e instalación de APK se muestran solo en Android.

## Pruebas

```bash
XDG_DATA_HOME=/tmp/lumbral-actualizador ~/Juegos/herramientas/godot --headless --path . res://pruebas/actualizador.tscn
python3 herramientas/probar_actualizador.py
XDG_DATA_HOME=/tmp/lumbral-ajustes ~/Juegos/herramientas/godot --headless --path . res://pruebas/ajustes.tscn
```

La segunda prueba levanta un servidor HTTPS local y comprueba consulta, redirección de descarga, escritura y verificación real. El certificado de prueba solo se configura en esa prueba, nunca en producción. Las pruebas automatizadas no aceptan la instalación de un APK en un teléfono.

La prueba final de dispositivo consiste en guardar una partida en 0.11, publicar una entrega posterior firmada igual, buscarla, cancelar y reintentar, aceptar el permiso, instalar y comprobar que conserva partida y ajustes. No se ha confirmado aún ese último paso en un dispositivo conectado.

## Referencias

- [Integración con APIs Android en Godot](https://docs.godotengine.org/en/stable/tutorials/platform/android/javaclasswrapper_and_androidruntimeplugin.html)
- [Paquete, firma y versión en actualizaciones Android](https://developer.android.com/google/play/app-updates)
- [FileProvider](https://developer.android.com/reference/androidx/core/content/FileProvider)
- [Permiso para solicitar instalación](https://developer.android.com/reference/android/content/pm/PackageManager#canRequestPackageInstalls())
