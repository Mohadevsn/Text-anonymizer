# Projet de Compilation — Anonymisation Automatique de Documents Textuels (JavaCC)

**M1 GLSI — ESP/UCAD — 2025-2026**
Date début : 12/07/2026 — Date fin : 18/07/2026

Projet réalisé par **Ibrahim Dan Azoumi**, **Ramatoulaye Fall** et **Mohamed Wade**.
Les 10 parties du sujet sont couvertes ; le détail de chacune (méthode, choix,
limites assumées) est dans les documents listés en [Documentation](#documentation).

## Description

`Anonymizer` est un analyseur lexical/syntaxique généré avec **JavaCC** qui lit un fichier texte en français et remplace les informations sensibles qu'il reconnaît par des balises génériques, tout en recopiant le reste du texte à l'identique :

| Type reconnu | Exemple d'entrée | Remplacé par |
|---|---|---|
| Email | `amadou.diallo@gmail.com` | `<EMAIL>` |
| Téléphone (formats sénégalais) | `77 123 45 67`, `+221 77 123 45 67` | `<TELEPHONE>` |
| Date | `15/06/2026`, `15 06 2026` | `<DATE>` |
| Montant | `250000 FCFA`, `12.50 €` | `<MONTANT>` |
| Nom propre | `Amadou`, `Diallo` | `<PERSONNE>` |
| Article / mot-vide en début de phrase | `Le`, `Bonjour`, `Monsieur`... | recopié tel quel |
| Autre mot / caractère | ponctuation, mots courants | recopié tel quel |

La grammaire complète (tokens + règle de départ) est définie dans [`grammaire/anonymizer.jj`](grammaire/anonymizer.jj).

Certains comportements limites sont volontairement documentés plutôt que masqués
(ex. noms tout en majuscules, accents, email collé au mot suivant) — voir
[`docs/maximal-munch.md`](docs/maximal-munch.md) et [`docs/analyse-finale.md`](docs/analyse-finale.md).

## Prérequis

- JDK (`java`, `javac`)
- [JavaCC](https://javacc.github.io/javacc/) accessible via le `PATH`, **ou** un `javacc.jar` placé dans `lib/javacc.jar`

## Build & exécution

```bash
# Génère le parser depuis la grammaire, puis compile les .class
./scripts/build.sh

# Génère, compile puis exécute directement sur un fichier
./scripts/build.sh run <fichier_entree> <fichier_sortie>

# Exécution manuelle après un build
java -cp class Anonymizer <fichier_entree> <fichier_sortie>

# Nettoyage des fichiers générés (src/ et class/)
./scripts/build.sh clean
```

## Tests

Les jeux d'essais se trouvent dans `test/*.txt`, avec les sorties attendues dans `test/expected/`.

```bash
# Lance tous les tests (nécessite un build préalable)
./scripts/test.sh

# Recompile puis lance tous les tests
./scripts/test.sh --build

# Ne lance que les tests dont le nom contient "test2"
./scripts/test.sh test2
```

Chaque test produit sa sortie et son log dans `test/resultats/`, comparés au fichier attendu correspondant dans `test/expected/` lorsqu'il existe. Détail des 5 jeux d'essai, de leur objectif et des résultats obtenus : [`docs/validation.md`](docs/validation.md).

## Instrumentation (Partie 8)

`tools/TokenDump.java` affiche, pour un fichier donné, le type de token, sa position et le lexème exact reconnu par le lexer généré — sans passer par le parseur, donc sans effet sur l'anonymisation elle-même.

```bash
./scripts/trace.sh <fichier_entree>
```

Détails et exemples de sortie : [`docs/instrumentation.md`](docs/instrumentation.md).

## Documentation

| Partie | Sujet | Fichier(s) | Auteur(s) |
|---|---|---|---|
| 1 | Étude du problème (catégories, règles, difficultés) | [`docs/etude-du-probleme.md`](docs/etude-du-probleme.md) | Ibrahim Dan Azoumi |
| 2 | Expressions régulières | [`docs/regex.md`](docs/regex.md) | Ibrahim Dan Azoumi |
| 3 | Automates finis (email, téléphone, date) | [`docs/automates.md`](docs/automates.md), [`docs/automates/`](docs/automates/) | Ramatoulaye Fall |
| 4 + 6 | Spécification lexicale et grammaire syntaxique JavaCC | [`docs/analyse-lexicale.md`](docs/analyse-lexicale.md), [`grammaire/anonymizer.jj`](grammaire/anonymizer.jj) | Mohamed Wade |
| 5 | Étude du Maximal Munch sur plusieurs chaînes | [`docs/maximal-munch.md`](docs/maximal-munch.md) | Ibrahim Dan Azoumi |
| 7 | Implémentation complète (lecture, tokenisation, anonymisation, écriture) | [`src/`](src/) (généré depuis `anonymizer.jj`) | Mohamed Wade |
| 8 | Instrumentation : affichage type de token + lexème | [`docs/instrumentation.md`](docs/instrumentation.md), [`tools/TokenDump.java`](tools/TokenDump.java) | Équipe |
| 9 | Validation : jeux d'essais et tableau récapitulatif | [`docs/validation.md`](docs/validation.md), [`test/`](test/) | Équipe |
| 10 | Analyse finale : performances, limites, rôle du Maximal Munch, améliorations | [`docs/analyse-finale.md`](docs/analyse-finale.md) | Équipe |

## Structure du dépôt

```
text-anonymizer/
├── grammaire/
│   └── anonymizer.jj              ← Grammaire JavaCC source (Parties 4 + 6 + 7)
├── src/                            ← Généré par build.sh à partir de anonymizer.jj (ne pas éditer à la main)
├── class/                          ← Fichiers .class compilés (généré par build.sh)
├── tools/
│   └── TokenDump.java             ← Outil d'instrumentation (Partie 8)
├── scripts/
│   ├── build.sh                   ← génère + compile (+ exécute avec `run`)
│   ├── test.sh                    ← exécute les jeux d'essais et compare aux sorties attendues
│   └── trace.sh                   ← compile + exécute TokenDump sur un fichier
├── test/                           ← Jeux d'essai (Partie 9)
│   ├── test1_base.txt ... test5_faux_positifs_negatifs.txt
│   ├── expected/                  ← sorties de référence par test
│   └── resultats/                 ← sorties + logs générés par test.sh
├── docs/
│   ├── etude-du-probleme.md       ← Partie 1
│   ├── regex.md                   ← Partie 2
│   ├── automates.md               ← Partie 3
│   ├── automates/                 ← Partie 3 (schémas email/téléphone/date)
│   ├── maximal-munch.md           ← Partie 5
│   ├── analyse-lexicale.md        ← Parties 4 + 6
│   ├── instrumentation.md         ← Partie 8
│   ├── validation.md              ← Partie 9
│   └── analyse-finale.md          ← Partie 10
└── README.md
```

## Limites connues et pistes d'amélioration

Le projet documente volontairement plusieurs comportements imparfaits plutôt que de les masquer (noms tout en majuscules, accents non couverts, email sans borne de longueur, liste d'articles nécessairement incomplète...). La liste complète, avec pour chacune l'origine exacte et une piste de correction, est dans [`docs/analyse-finale.md`](docs/analyse-finale.md).
