#!/usr/bin/env bash
# ¿Sigue valiendo cada servidor del catálogo? Prueba de verdad, no solo «abre el puerto»: para cada servidor arranca
# Outpace (con el parche de MiVisor) usando SOLO ese servidor y le pide uno o varios IDs que funcionen. Si convierte
# alguno en su descriptor, el servidor VALE.
#
# Uso:
#   tools/verificar-catalogo.sh --id <ID1> [--id <ID2> …] [--actualizar] [ip:puerto …]
#     sin ip:puerto  → prueba todos los de catalog-hosts.json (también los desactivados)
#     --actualizar   → apunta el resultado en catalog-hosts.json (last_ok, fails, enabled) para que se vea el historial
# Requisitos: python3, curl y el binario de Outpace con el parche de MiVisor (variable OUTPACE, por defecto «outpace»).
set -euo pipefail
OUTPACE="${OUTPACE:-outpace}"
JSON="${JSON:-catalog-hosts.json}"
ids=(); hosts=(); update=0
while [ $# -gt 0 ]; do
  case "$1" in
    --id) ids+=("$2"); shift 2 ;;
    --actualizar) update=1; shift ;;
    *) hosts+=("$1"); shift ;;
  esac
done
[ ${#ids[@]} -gt 0 ] || { echo "Falta al menos un --id que funcione (mejor 2 o 3 de canales distintos)"; exit 2; }
command -v "$OUTPACE" >/dev/null || { echo "No encuentro Outpace ($OUTPACE). Mira el README: «Preparar el verificador»."; exit 2; }
if [ ${#hosts[@]} -eq 0 ]; then
  mapfile -t hosts < <(python3 -c 'import json,sys
for h in json.load(open(sys.argv[1]))["hosts"]: print("%s:%s" % (h["host"], h.get("port", 8081)))' "$JSON")
fi
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
results="$work/results.tsv"; : > "$results"
port=17900
for h in "${hosts[@]}"; do
  port=$((port + 1))
  log="$work/engine-$port.log"
  OUTPACE_BIND="127.0.0.1:$port" OUTPACE_DATA_DIR="$work/data-$port" HOME="$work" \
  OUTPACE_CATALOG_HOSTS="$h" OUTPACE_CATALOG_HOSTS_ONLY=1 OUTPACE_BEP9_CONTENT_ID_FALLBACK=0 \
  OUTPACE_ENABLE_INBOUND=0 OUTPACE_ENABLE_SEEDING=0 OUTPACE_ENABLE_PORT_MAPPING=0 OUTPACE_PORT_MAP_BACKEND=none \
  OUTPACE_RTMP_BIND="127.0.0.1:0" OUTPACE_PEER_LISTEN="127.0.0.1:0" \
    "$OUTPACE" serve > "$log" 2>&1 &
  pid=$!
  for _ in $(seq 1 50); do curl -fs "http://127.0.0.1:$port/healthz" >/dev/null 2>&1 && break; sleep 0.2; done
  verdict="FALLA"; detail="ningún ID resuelto"
  for id in "${ids[@]}"; do
    # Error rápido (4xx/5xx en < 8 s) = el catálogo no lo resolvió. 200, o seguir esperando pares = SÍ lo resolvió.
    code="$(curl -s -o "$work/body" -w '%{http_code}' --max-time 8 "http://127.0.0.1:$port/streams/ace/cid:${id}.m3u8" || true)"
    if [ "$code" = "200" ] || [ "$code" = "000" ]; then verdict="VALE"; detail="resuelve ${id:0:8}…"; break; fi
    detail="HTTP $code: $(head -c 90 "$work/body" 2>/dev/null | tr '\n' ' ')"
  done
  kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
  printf '%-6s %-22s %s\n' "$verdict" "$h" "$detail"
  printf '%s\t%s\n' "$h" "$verdict" >> "$results"
done
if [ "$update" = 1 ]; then
  python3 - "$JSON" "$results" <<'PY'
import json, sys, datetime
path, res = sys.argv[1], sys.argv[2]
today = datetime.date.today().isoformat()
d = json.load(open(path))
seen = dict(l.rstrip("\n").split("\t") for l in open(res) if l.strip())
for h in d["hosts"]:
    key = f'{h["host"]}:{h.get("port", 8081)}'
    if key not in seen: continue
    if seen[key] == "VALE":
        h["last_ok"] = today; h["fails"] = 0; h.pop("enabled", None)
    else:
        h["fails"] = int(h.get("fails", 0)) + 1
        h["last_fail"] = today
        if h["fails"] >= 3: h["enabled"] = False       # 3 comprobaciones seguidas sin valer: fuera de uso
d["updated"] = today
json.dump(d, open(path, "w"), ensure_ascii=False, indent=2); open(path, "a").write("\n")
print(f"\n{path} actualizado ({today}).")
PY
fi
grep -q $'\tVALE$' "$results"   # código de salida 1 si no vale NINGUNO
