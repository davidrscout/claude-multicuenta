"""Pone o quita una clave de primer nivel en un settings.json sin tocar el resto (lo usa claude-cuenta.ps1).
Uso: python claude-cuenta-ajuste.py <settings.json> <clave> <@fichero con el valor JSON | --quitar>"""
import json
import os
import shutil
import sys

ruta, clave, valor = sys.argv[1], sys.argv[2], sys.argv[3]
if valor.startswith("@"):
    with open(valor[1:], encoding="utf-8-sig") as f:
        valor = f.read()
nuevo = None if valor == "--quitar" else json.loads(valor)  # validar antes de tocar nada
datos = {}
if os.path.exists(ruta):
    with open(ruta, encoding="utf-8-sig") as f:
        texto = f.read().strip()
    datos = json.loads(texto) if texto else {}
    shutil.copy2(ruta, ruta + ".antes_claude-cuenta")
if nuevo is None:
    datos.pop(clave, None)
else:
    datos[clave] = nuevo
temporal = ruta + ".tmp"
with open(temporal, "w", encoding="utf-8") as f:
    json.dump(datos, f, ensure_ascii=False, indent=2)
    f.write("\n")
with open(temporal, encoding="utf-8") as f:
    json.load(f)  # comprobar que ha quedado válido antes de sustituir
os.replace(temporal, ruta)
print("OK " + ruta)
