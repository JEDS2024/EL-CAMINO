# Actualizar el APK conservando la partida

## Estado de esta versión

La 0.10 corrige Ajustes y puede instalarse encima de la 0.9. No incorpora todavía un descargador ni un instalador dentro del juego. Se puede abrir el APK nuevo desde Descargas y confirmar «Actualizar» en Android, sin desinstalar el anterior.

Se comprobó que los APK locales 0.8 y 0.9 usan `com.jader.elcamino` y el mismo certificado de prueba de Godot. La 0.10 mantiene esa firma e incrementa `version/code` a 10. Android conserva los datos privados de la aplicación al actualizarla; desinstalar sí los elimina.

Para que Android acepte la actualización hay que mantener el identificador y la firma y aumentar el código para cada publicación. Las builds actuales son de prueba. Antes de distribuir una versión pública se debe decidir la clave definitiva: cambiar de certificado sin un mecanismo válido de rotación rompe la compatibilidad con instalaciones anteriores.

## Verificación de cada entrega

```bash
python3 herramientas/verificar_actualizacion.py ../builds/ElCamino-v0.9.apk builds/ElCamino-v0.10.apk
```

La herramienta usa `aapt` y `apksigner` del SDK y falla si cambia el paquete, cambia la firma o el código nuevo no aumenta. Es una comprobación de los APK, no una prueba de instalación en un teléfono. La prueba final consiste en instalar la versión anterior, guardar una partida, actualizar con la nueva y verificar partida y ajustes.

## Propuesta para actualizar desde el juego con APK directo

1. Publicar por HTTPS un manifiesto con `version_code`, `version_name`, `apk_url`, `sha256` y tamaño. Aún falta elegir/configurar esa URL.
2. Añadir «Buscar actualizaciones» en Ajustes; consultar solo a petición del usuario, con tiempo de espera y aviso si no hay conexión. Mostrar versión y tamaño antes de descargar.
3. Descargar el APK al almacenamiento privado temporal, verificar tamaño y SHA-256 y guardar la partida antes de iniciar la instalación. No hace falta permiso general para acceder a los archivos del teléfono.
4. Integrar un plugin Android para Godot con `PackageInstaller` y el permiso `REQUEST_INSTALL_PACKAGES`. El flujo debe consultar `canRequestPackageInstalls`, abrir los ajustes del sistema cuando corresponda y continuar solo tras autorización. La exportación actual usa plantilla estándar (`gradle_build/use_gradle_build=false`); el plugin requiere preparar la compilación Gradle.
5. Entregar el APK al instalador del sistema y manejar confirmación, cancelación, error y reintento. Android realiza la sustitución; no se desinstala la aplicación.
6. Al abrir la versión nueva se carga la partida habitual. Mantener las migraciones de guardados existentes.

El hash comprueba integridad de la descarga; la firma del APK es la que Android usa para aceptar que pertenece a la aplicación. No se promete instalación silenciosa.

### Dónde alojarlo

- **Servidor propio (por ejemplo el VPS Oracle):** URL HTTPS pública para manifiesto y APK; permite controlar la publicación sin exponer el código.
- **GitHub:** releases de un repositorio público dedicado a distribuir APK, o un servicio que entregue enlaces autorizados. El repositorio de código actual es privado: no se debe incluir una credencial de GitHub en el APK para acceder a sus releases privadas.

La versión instalada hoy necesitará recibir una vez por descarga manual un APK que incluya el futuro actualizador. A partir de esa versión se podrá iniciar el flujo desde Ajustes.

## Referencias oficiales

- [Cómo Android acepta actualizaciones: paquete, certificado y versión](https://developer.android.com/google/play/app-updates)
- [Confirmación del usuario en PackageInstaller](https://developer.android.com/reference/android/content/pm/PackageInstaller.SessionParams)
- [Permiso de instalación y canRequestPackageInstalls](https://developer.android.com/reference/android/content/pm/PackageManager#canRequestPackageInstalls())
- [Actualizaciones dentro de la app mediante Google Play](https://developer.android.com/guide/playcore/in-app-updates) — alternativa si más adelante se distribuye mediante esa tienda.
