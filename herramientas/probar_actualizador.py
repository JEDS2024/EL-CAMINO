"""Prueba el actualizador contra un servidor HTTPS local, sin publicar ni instalar nada."""
import argparse
import hashlib
import http.server
import json
import os
from pathlib import Path
import ssl
import subprocess
import tempfile
import threading


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--godot", default=str(Path.home() / "Juegos/herramientas/godot"))
    args = p.parse_args()
    raiz = Path(__file__).resolve().parent.parent
    with tempfile.TemporaryDirectory(prefix="lumbral-https-") as temporal:
        ruta = Path(temporal)
        cert, key = ruta / "servidor.crt", ruta / "servidor.key"
        subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
                        "-keyout", str(key), "-out", str(cert), "-subj", "/CN=localhost",
                        "-addext", "subjectAltName=DNS:localhost"], check=True, capture_output=True)
        contenido = b"Archivo sintetico para probar la descarga.\n" * 24000
        class Servidor(http.server.BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass
            def do_GET(self):
                host = f"https://localhost:{self.server.server_port}"
                if self.path == "/version.json":
                    dato = {"package": "com.jader.elcamino", "version_code": 100000,
                            "version_name": "prueba HTTPS", "apk_url": host + "/descarga.apk",
                            "size": len(contenido), "sha256": hashlib.sha256(contenido).hexdigest()}
                    cuerpo = json.dumps(dato).encode()
                elif self.path == "/descarga.apk":
                    self.send_response(302)
                    self.send_header("Location", host + "/archivo.apk")
                    self.send_header("Content-Length", "0")
                    self.end_headers()
                    return
                elif self.path == "/archivo.apk":
                    cuerpo = contenido
                else:
                    self.send_error(404)
                    return
                self.send_response(200)
                self.send_header("Content-Length", str(len(cuerpo)))
                self.end_headers()
                self.wfile.write(cuerpo)
        servidor = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Servidor)
        tls = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        tls.load_cert_chain(cert, key)
        servidor.socket = tls.wrap_socket(servidor.socket, server_side=True)
        hilo = threading.Thread(target=servidor.serve_forever, daemon=True)
        hilo.start()
        entorno = dict(os.environ, XDG_DATA_HOME=str(ruta / "usuario"),
                       LUMBRAL_CERT_PRUEBA=str(cert),
                       LUMBRAL_URL_PRUEBA=f"https://localhost:{servidor.server_port}/version.json")
        try:
            resultado = subprocess.run([args.godot, "--headless", "--path", str(raiz),
                                       "res://pruebas/actualizador.tscn", "--", "--red"], env=entorno, timeout=40)
            return resultado.returncode
        finally:
            servidor.shutdown()
            servidor.server_close()


if __name__ == "__main__":
    raise SystemExit(main())
