#!/usr/bin/env bash
#
# build.sh — Génère et compile le parser JavaCC de l'anonymiseur.
# Portable : ne dépend d'aucun chemin absolu propre à une machine.
#
# Usage :
#   ./scripts/build.sh              → génère + compile
#   ./scripts/build.sh run <input> <output>   → génère + compile + exécute
#   ./scripts/build.sh clean         → nettoie les fichiers générés

set -euo pipefail

# =========================================================
# 1. LOCALISATION DU PROJET (indépendante de la machine)
# =========================================================
# ${BASH_SOURCE[0]} = chemin du script lui-même (même si appelé via un
# lien symbolique ou depuis un autre dossier). On résout son chemin
# absolu réel, puis on remonte à la racine du projet à partir de là.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GRAMMAR_DIR="${PROJECT_ROOT}/grammaire"
GRAMMAR_FILE="${GRAMMAR_DIR}/anonymizer.jj"
# BUILD_DIR="${PROJECT_ROOT}/build"
GENERATED_DIR="${PROJECT_ROOT}/src"
CLASSES_DIR="${PROJECT_ROOT}/class"
LIB_DIR="${PROJECT_ROOT}/lib"

echo "Racine du projet détectée : ${PROJECT_ROOT}"

# =========================================================
# 2. NETTOYAGE (option "clean")
# =========================================================
if [[ "${1:-}" == "clean" ]]; then
    echo "Nettoyage de ${GENERATED_DIR}..."
    rm -rf "${GENERATED_DIR}"
    echo "Nettoyage de ${CLASSES_DIR}..."
    rm -rf "${CLASSES_DIR}"
    echo "Terminé."
    exit 0
fi

# =========================================================
# 3. LOCALISATION DE JAVACC (sans dépendre d'un chemin fixe)
# =========================================================
# Ordre de recherche :
#   a) javacc déjà installé et dans le PATH (ex: via un package manager)
#   b) un javacc.jar présent dans lib/ à la racine du projet
#   c) échec avec message clair
JAVACC_CMD=""

if command -v javacc >/dev/null 2>&1; then
    JAVACC_CMD="javacc"
elif [[ -f "${LIB_DIR}/javacc.jar" ]]; then
    JAVACC_CMD="java -cp ${LIB_DIR}/javacc.jar javacc"
else
    echo "Erreur : javacc introuvable." >&2
    echo "  - Soit installez-le et assurez-vous qu'il est dans le PATH," >&2
    echo "  - Soit placez javacc.jar dans : ${LIB_DIR}/javacc.jar" >&2
    exit 1
fi

echo "javacc trouvé : ${JAVACC_CMD}"

# =========================================================
# 4. GENERATION DU PARSER
# =========================================================
if [[ ! -f "${GRAMMAR_FILE}" ]]; then
    echo "Erreur : fichier de grammaire introuvable : ${GRAMMAR_FILE}" >&2
    exit 1
fi

mkdir -p "${GENERATED_DIR}"
echo "Génération du parser depuis ${GRAMMAR_FILE}..."
# -OUTPUT_DIRECTORY force la sortie des .java générés dans build/generated,
# indépendamment de l'endroit d'où le script est appelé.
${JAVACC_CMD} -OUTPUT_DIRECTORY="${GENERATED_DIR}" "${GRAMMAR_FILE}"

# =========================================================
# 5. COMPILATION JAVA
# =========================================================
mkdir -p "${CLASSES_DIR}"
echo "Compilation des classes Java..."
javac -d "${CLASSES_DIR}" "${GENERATED_DIR}"/*.java

echo "Build terminé avec succès."
echo "Classes générées dans : ${CLASSES_DIR}"

# =========================================================
# 6. EXECUTION OPTIONNELLE (option "run <input> <output>")
# =========================================================
if [[ "${1:-}" == "run" ]]; then
    INPUT_FILE="${2:-}"
    OUTPUT_FILE="${3:-}"

    if [[ -z "${INPUT_FILE}" || -z "${OUTPUT_FILE}" ]]; then
        echo "Usage: $0 run <fichier_entree> <fichier_sortie>" >&2
        exit 1
    fi

    # Résout le chemin des fichiers d'entrée/sortie donnés par l'utilisateur
    # relativement au dossier courant d'où le script est appelé (pas au projet),
    # ce qui est le comportement attendu pour des arguments utilisateur.
    echo "Exécution sur ${INPUT_FILE}..."
    java -cp "${CLASSES_DIR}" Anonymizer "${INPUT_FILE}" "${OUTPUT_FILE}"
fi
