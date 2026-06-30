from flask import Flask
from pathlib import Path
from datetime import datetime

app = Flask(__name__)

DATA_DIR = Path("/data")
COUNTER_FILE = DATA_DIR / "contador.txt"


@app.route("/")
def contador():
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    if COUNTER_FILE.exists():
        try:
            visitas = int(COUNTER_FILE.read_text().strip())
        except ValueError:
            visitas = 0
    else:
        visitas = 0

    visitas += 1
    COUNTER_FILE.write_text(str(visitas))

    print(f"visita -> contador={visitas}", flush=True)

    fecha = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    return f"""
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <title>Aplicación Kubernetes - Caso Práctico 2</title>
    </head>
    <body>
        <h1>Aplicación desplegada en AKS</h1>
        <p>Esta es la segunda aplicación del caso práctico.</p>
        <p>Se ejecuta en Kubernetes sobre Azure Kubernetes Service.</p>
        <p><strong>Número de visitas:</strong> {visitas}</p>
        <p><strong>Última actualización:</strong> {fecha}</p>
        <p>El contador se guarda en el fichero <code>/data/contador.txt</code>.</p>
    </body>
    </html>
    """


@app.route("/health")
def health():
    return "OK", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
