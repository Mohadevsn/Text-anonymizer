#!/usr/bin/env bash
#
# test.sh — Exécute l'anonymiseur sur tous les jeux d'essais et
# produit un récapitulatif (Partie 9 : validation).
#
# Portable : chemins calculés relativement au script, pas à la machine.
#
# Usage :
#   ./scripts/test.sh              → lance tous les tests
#   ./scripts/test.sh test2        → lance uniquement les tests dont le
#                                     nom de fichier contient "test2"
#   ./scripts/test.sh --build      → recompile avant de lancer les tests

set -euo pipefail

# =========================================================
# 1. LOCALISATION DU PROJET (même mécanisme que build.sh)
# =========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TESTS_DIR="${PROJECT_ROOT}/test"
BUILD_DIR="${PROJECT_ROOT}/src"
CLASSES_DIR="${PROJECT_ROOT}/class"
RESULTS_DIR="${TESTS_DIR}/resultats"
EXPECTED_DIR="${TESTS_DIR}/expected"

# =========================================================
# 2. OPTION --build : recompiler avant de tester
# =========================================================
if [[ "${1:-}" == "--build" ]]; then
    echo "Recompilation avant tests..."
    "${SCRIPT_DIR}/build.sh"
    shift
fi

# =========================================================
# 3. VERIFICATIONS PREALABLES
# =========================================================
if [[ ! -d "${CLASSES_DIR}" ]]; then
    echo "Erreur : classes compilées introuvables (${CLASSES_DIR})." >&2
    echo "Lancez d'abord : ./scripts/build.sh   (ou ./scripts/test.sh --build)" >&2
    exit 1
fi

if [[ ! -d "${TESTS_DIR}" ]]; then
    echo "Erreur : dossier de tests introuvable (${TESTS_DIR})." >&2
    exit 1
fi

mkdir -p "${RESULTS_DIR}"

# =========================================================
# 4. SELECTION DES FICHIERS DE TEST
# =========================================================
# Filtre optionnel passé en argument (ex: "test2" pour ne lancer que
# test2_dates_ambigues.txt). Sans argument, on prend tout tests/*.txt.
FILTER="${1:-}"

TEST_FILES=()
for f in "${TESTS_DIR}"/*.txt; do
    [[ -e "$f" ]] || continue
    if [[ -z "${FILTER}" || "$(basename "$f")" == *"${FILTER}"* ]]; then
        TEST_FILES+=("$f")
    fi
done

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    echo "Aucun fichier de test trouvé (filtre: '${FILTER}')." >&2
    exit 1
fi

echo "Fichiers de test à exécuter : ${#TEST_FILES[@]}"
echo ""

# =========================================================
# 5. EXECUTION DE CHAQUE TEST + COMPARAISON (si sortie attendue dispo)
# =========================================================
# TODO: format du tableau récapitulatif à adapter/enrichir pour la Partie 9
printf "%-40s %-10s %-30s\n" "FICHIER" "STATUT" "COMMENTAIRE"
printf "%-40s %-10s %-30s\n" "-------" "------" "-----------"

PASS_COUNT=0
FAIL_COUNT=0
NO_REF_COUNT=0

for input_file in "${TEST_FILES[@]}"; do
    name="$(basename "${input_file}" .txt)"
    output_file="${RESULTS_DIR}/${name}_output.txt"
    expected_file="${EXPECTED_DIR}/${name}_expected.txt"

    # Exécution du programme (main : Anonymizer <entree> <sortie>)
    if ! java -cp "${CLASSES_DIR}" Anonymizer "${input_file}" "${output_file}" > "${RESULTS_DIR}/${name}.log" 2>&1; then
        printf "%-40s %-10s %-30s\n" "${name}" "ERREUR" "voir log"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi

    # Comparaison avec la sortie attendue, si elle existe déjà
    if [[ -f "${expected_file}" ]]; then
        if diff -q "${output_file}" "${expected_file}" > /dev/null 2>&1; then
            printf "%-40s %-10s %-30s\n" "${name}" "OK" ""
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            printf "%-40s %-10s %-30s\n" "${name}" "DIFF" "voir log"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        # TODO: une fois les sorties attendues validées manuellement,
        # les copier dans tests/expected/ pour activer la comparaison automatique
        printf "%-40s %-10s %-30s\n" "${name}" "GENERE" "pas de référence (voir ${output_file})"
        NO_REF_COUNT=$((NO_REF_COUNT + 1))
    fi
done

# =========================================================
# 6. RECAPITULATIF
# =========================================================
echo ""
echo "Résumé : ${PASS_COUNT} OK / ${FAIL_COUNT} échec(s) / ${NO_REF_COUNT} sans référence"
echo "Résultats détaillés dans : ${RESULTS_DIR}"

if [[ ${FAIL_COUNT} -gt 0 ]]; then
    exit 1
fi
