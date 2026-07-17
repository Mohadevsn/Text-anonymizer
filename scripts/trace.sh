#!/usr/bin/env bash
#
# trace.sh — Compile puis exécute TokenDump (Partie 8 : instrumentation)
# sur un fichier donné, pour afficher type de token + lexème reconnu
# ligne par ligne.
#
# Portable : chemins calculés relativement au script, pas à la machine.
#
# Usage :
#   ./scripts/trace.sh <fichier_entree>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CLASSES_DIR="${PROJECT_ROOT}/class"
TOOLS_DIR="${PROJECT_ROOT}/tools"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <fichier_entree>" >&2
    exit 1
fi

INPUT_FILE="$1"

if [[ ! -d "${CLASSES_DIR}" ]]; then
    echo "Erreur : classes compilées introuvables (${CLASSES_DIR})." >&2
    echo "Lancez d'abord : ./scripts/build.sh" >&2
    exit 1
fi

javac -cp "${CLASSES_DIR}" -d "${CLASSES_DIR}" "${TOOLS_DIR}/TokenDump.java"
java -cp "${CLASSES_DIR}" TokenDump "${INPUT_FILE}"
