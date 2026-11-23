#!/usr/bin/env bash
# Instala el harness en un proyecto que YA EXISTE, sin tocar su código.
#
# Uso (desde la carpeta de harness-template):
#   bash install.sh /ruta/a/mi-proyecto
#
# Qué hace:
#   - Copia AGENTS.md, docs/, .agents/skills/, .claude/, .githooks/, scripts/check.sh e init.sh.
#   - NUNCA sobrescribe: si un archivo ya existe en tu proyecto, deja la versión del
#     harness al lado con el sufijo .harness (p. ej. AGENTS.harness.md) y te avisa.
#   - No copia apps/, packages/ ni tests/: tu proyecto ya tiene su propia estructura.
#   - No hace commits. Revisa los cambios con `git status` antes de commitear.
set -euo pipefail

ORIGEN="$(cd "$(dirname "$0")" && pwd)"
DESTINO="${1:-}"

if [ -z "$DESTINO" ] || [ ! -d "$DESTINO" ]; then
  echo "Uso: bash install.sh /ruta/a/mi-proyecto"
  exit 1
fi
DESTINO="$(cd "$DESTINO" && pwd)"
if [ "$DESTINO" = "$ORIGEN" ]; then
  echo "✘ El destino no puede ser la propia plantilla."
  exit 1
fi

conflictos=()

copiar() {  # copiar <ruta relativa de archivo>
  local rel="$1" src="$ORIGEN/$1" dst="$DESTINO/$1"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if cmp -s "$src" "$dst" 2>/dev/null; then return; fi
    local alt
    case "$dst" in
      *.*) alt="${dst%.*}.harness.${dst##*.}" ;;
      *)   alt="$dst.harness" ;;
    esac
    cp -p "$src" "$alt"
    conflictos+=("$rel  →  ${alt#"$DESTINO"/}")
  else
    cp -p "$src" "$dst"
  fi
}

echo "▶ Instalando el harness en: $DESTINO"

# Archivos sueltos
for f in AGENTS.md init.sh scripts/check.sh .env.example; do
  copiar "$f"
done

# Carpetas completas, archivo por archivo (para no sobrescribir nada)
for dir in docs .agents/skills .githooks .claude/hooks; do
  while IFS= read -r -d '' f; do
    copiar "${f#"$ORIGEN"/}"
  done < <(find "$ORIGEN/$dir" -type f -print0)
done
copiar .claude/settings.json

# Enlace de skills para Claude Code
if [ ! -e "$DESTINO/.claude/skills" ] && [ ! -L "$DESTINO/.claude/skills" ]; then
  ln -s ../.agents/skills "$DESTINO/.claude/skills" 2>/dev/null \
    || { cp -r "$ORIGEN/.agents/skills" "$DESTINO/.claude/skills"; echo "  ⚠ No se pudo crear el enlace simbólico; se copiaron las skills a .claude/skills"; }
fi

# .gitignore: añadir solo las líneas que falten
touch "$DESTINO/.gitignore"
nuevas=0
while IFS= read -r linea; do
  [ -z "$linea" ] && continue
  case "$linea" in \#*) continue ;; esac
  if ! grep -qxF -- "$linea" "$DESTINO/.gitignore"; then
    [ "$nuevas" -eq 0 ] && printf '\n# Añadido por el harness\n' >> "$DESTINO/.gitignore"
    echo "$linea" >> "$DESTINO/.gitignore"
    nuevas=$((nuevas + 1))
  fi
done < "$ORIGEN/.gitignore"

chmod +x "$DESTINO/init.sh" "$DESTINO/scripts/check.sh" "$DESTINO"/.githooks/* "$DESTINO"/.claude/hooks/*.sh 2>/dev/null || true

# Archivos de instrucciones de otras herramientas que harían que se ignore AGENTS.md
otros=()
for f in CLAUDE.md .claude/CLAUDE.md CLAUDE.local.md GEMINI.md .cursorrules .github/copilot-instructions.md; do
  [ -e "$DESTINO/$f" ] && otros+=("$f")
done

echo "✔ Harness copiado ($nuevas línea(s) nuevas a .gitignore)"

if [ "${#conflictos[@]}" -gt 0 ]; then
  echo ""
  echo "⚠ Estos archivos ya existían. NO se tocaron; la versión del harness quedó al lado:"
  printf '   %s\n' "${conflictos[@]}"
  echo "  La skill adoptar-proyecto te ayudará a fusionarlos."
fi

if [ "${#otros[@]}" -gt 0 ]; then
  echo ""
  echo "⚠ Tu proyecto tiene instrucciones para otras herramientas:"
  printf '   %s\n' "${otros[@]}"
  echo "  Claude Code ignora AGENTS.md mientras exista un CLAUDE.md. La skill"
  echo "  adoptar-proyecto pasará su contenido a AGENTS.md/docs y te pedirá permiso para borrarlos."
fi

cat <<EOF

Siguientes pasos:
  1. cd "$DESTINO"
  2. git checkout -b chore/adoptar-harness
  3. ./init.sh
  4. Abre Claude Code o Antigravity y pide:  "usa la skill adoptar-proyecto"
EOF
