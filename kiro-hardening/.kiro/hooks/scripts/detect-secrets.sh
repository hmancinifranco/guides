#!/usr/bin/env bash
#
# Hook PreToolUse: bloquea escrituras que parezcan contener secretos.
# Kiro invoca este script antes de fs_write / str_replace / fs_append y le pasa
# por stdin el payload JSON de la invocación (incluye el contenido a escribir).
#
# Contrato de salida:
#   - exit 0  -> permite la escritura
#   - exit 2  -> bloquea la escritura; stderr se muestra al usuario/agente
#
# Ajusta o añade patrones según el contexto del cliente.
set -euo pipefail

payload="$(cat)"

patterns=(
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'AKIA[0-9A-Z]{16}'
  'aws_secret_access_key'
  '(password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token)[[:space:]]*[:=][[:space:]]*"[^"]{6,}'
  '(password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token)[[:space:]]*[:=][[:space:]]*[A-Za-z0-9/+=_.-]*[0-9][A-Za-z0-9/+=_.-]{3,}'
  'gh[pousr]_[A-Za-z0-9]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
)

for p in "${patterns[@]}"; do
  if printf '%s' "$payload" | grep -Eiq -e "$p"; then
    echo "Escritura bloqueada por el hook de secretos: el contenido parece contener un secreto (patron: ${p})." >&2
    echo "Usa variables de entorno o un secrets manager en lugar de incrustar el valor en el codigo." >&2
    echo "Si es un falso positivo, ajusta los patrones en .kiro/hooks/scripts/detect-secrets.sh" >&2
    exit 2
  fi
done

exit 0
