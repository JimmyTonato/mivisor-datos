#!/usr/bin/env bash
# Comprueba que los servidores de catalog-hosts.json aceptan conexión en su puerto (sin pedir nada).
# Uso: tools/comprobar-catalogo.sh [catalog-hosts.json]
set -euo pipefail
f="${1:-catalog-hosts.json}"
python3 - "$f" <<'PY'
import json, socket, sys
d = json.load(open(sys.argv[1]))
bad = 0
for h in d["hosts"]:
    if h.get("enabled") is False:
        continue
    host, port = h["host"], int(h.get("port", 8081))
    s = socket.socket(); s.settimeout(4)
    try:
        s.connect((host, port)); print(f"OK      {host}:{port}")
    except Exception as e:
        bad += 1; print(f"FALLA   {host}:{port}  ({e.__class__.__name__})")
    finally:
        s.close()
print(f"\n{bad} sin respuesta" if bad else "\nTodos responden")
sys.exit(1 if bad else 0)
PY
