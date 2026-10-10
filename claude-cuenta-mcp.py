"""Copia solo los servidores MCP de la configuración normal (~/.claude.json) a la de otra cuenta (lo usa claude-cuenta.ps1)."""
import json
import sys

origen, destino = sys.argv[1], sys.argv[2]
with open(origen, encoding="utf-8") as f:
    d = json.load(f)
with open(destino, "w", encoding="utf-8") as f:
    json.dump({"mcpServers": d.get("mcpServers", {})}, f, ensure_ascii=False, indent=1)
print("MCP copiados: %d" % len(d.get("mcpServers", {})))
