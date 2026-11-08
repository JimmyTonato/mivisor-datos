#!/usr/bin/env bash
# Descubre a qué servidores de catálogo (puerto 8081) se conecta el motor OFICIAL de Ace Stream al abrir un ID.
# Requisitos: motor oficial de Ace Stream para Linux escuchando en 127.0.0.1:6878, tcpdump y permisos de root.
# Uso: sudo tools/descubrir-catalogo.sh <ID_de_40_caracteres> [segundos]
set -euo pipefail
id="${1:?Falta el ID}"; secs="${2:-25}"
out="$(mktemp)"
timeout "$secs" tcpdump -nn -l 'tcp dst port 8081 and tcp[tcpflags] & tcp-syn != 0' > "$out" 2>/dev/null &
sleep 1
curl -s -o /dev/null --max-time "$((secs - 2))" "http://127.0.0.1:6878/ace/getstream?id=${id}&format=json" || true
wait || true
echo "Servidores de catálogo vistos (ponlos en catalog-hosts.json):"
grep -oE '> [0-9.]+\.8081' "$out" | sed -E 's/> ([0-9.]+)\.8081/\1/' | sort | uniq -c | sort -rn
rm -f "$out"
