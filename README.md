# Projet de Compilation — Anonymisation Automatique de Documents Textuels (JavaCC)

**M1 GLSI — ESP/UCAD — 2025-2026**
Date début : 12/07/2026 — Date fin : 18/07/2026

> ⚠️ Rappel : les **Parties 1 à 4** et l'**Implémentation (Partie 7)** sont strictement notées. Les autres parties (5, 6, 8, 9, 10) restent à faire mais avec moins de pression.

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

Chaque test produit sa sortie et son log dans `test/resultats/`, comparés au fichier attendu correspondant dans `test/expected/` lorsqu'il existe.

## Répartition des tâches et fichiers

| Membre | Parties à charge | Fichier(s) à produire | Contenu attendu |
|---|---|---|---|
| **Ibrahim Dan Azoumi** | Partie 1 + Partie 2 + Partie 5 | `docs/etude-du-probleme.md`<br>`docs/regex.md` <br> `docs/maximal-munch.md` | - Catégories d'infos à anonymiser<br>- Règles de reconnaissance<br>- Difficultés possibles<br>- Expressions régulières (email, tél, date, montant, mot, autres)<br>- Justification des choix<br>- Étude du Maximal Munch sur plusieurs chaînes<br> |
| **Ramatoulaye Fall** | Partie 3 | `docs/automates.md`<br>`docs/automates/` (schémas)<br> | - Automates de reconnaissance (email, tél, date)<br>- États, transitions, états finaux + tableaux<br>- Conflits lexicaux identifiés et expliqués |
| **Moi (Mohamed)** | Partie 4 + Partie 6 + **Partie 7** | `grammar/anonymizer.jj`<br>`src/`<br>`docs/analyse-lexicale.md` | - Définition des tokens EMAIL, PHONE, DATE, AMOUNT, PERSON, WORD, OTHER<br>- Règles lexicales JavaCC<br>- Grammaire syntaxique (Partie 6)<br>- **Implémentation complète** : lecture fichier, génération tokens, anonymisation, écriture fichier de sortie |

## Fait à trois (après que le code soit stable)

| Parties | Fichier(s) | Contenu |
|---|---|---|
| Partie 8 | `docs/instrumentation.md` | Affichage type de token + lexème reconnu |
| Partie 9 | `tests/` + `docs/validation.md` | Jeux d'essais (plusieurs documents), tableau récapitulatif des résultats |
| Partie 10 | `docs/analyse-finale.md` | Performances, limites, rôle du Maximal Munch, améliorations possibles |

## Structure du dépôt

```
text-anonymizer/
├── grammaire/
│   └── anonymizer.jj              ← Moi (Partie 4 + 6 + 7) : grammaire JavaCC source
├── src/                            ← Généré par build.sh à partir de anonymizer.jj (ne pas éditer à la main)
├── class/                          ← Fichiers .class compilés (généré par build.sh)
├── scripts/
│   ├── build.sh                   ← génère + compile (+ exécute avec `run`)
│   └── test.sh                    ← exécute les jeux d'essais et compare aux sorties attendues
├── test/                           ← Équipe (Partie 9)
│   ├── test1_base.txt ... test5_faux_positifs_negatifs.txt
│   ├── expected/                  ← sorties de référence par test
│   └── resultats/                 ← sorties + logs générés par test.sh
├── docs/
│   ├── etude-du-probleme.md       ← Ibrahim Dan Azoumi (Partie 1)
│   ├── regex.md                   ← Ibrahim Dan Azoumi (Partie 2)
│   ├── automates.md               ← Ramatoulaye Fall (Partie 3)
│   ├── automates/                 ← Ramatoulaye Fall (schémas, Partie 3)
│   ├── maximal-munch.md           ← Ibrahim Dan Azoumi (Partie 5)
│   ├── analyse-lexicale.md        ← Moi (Partie 4 + 6)
│   ├── instrumentation.md         ← Équipe (Partie 8)
│   ├── validation.md              ← Équipe (Partie 9)
│   ├── analyse-finale.md          ← Équipe (Partie 10)
│   └── rapport-final.md           ← Assemblage final (tout le monde relit)
└── README.md
```

> Note : `docs/regex.md`, `docs/automates/` et les autres livrables docs listés ci-dessus sont encore vides à ce stade — à compléter par les personnes en charge.

## Règles de collaboration

- **Un seul fichier `.jj`** : c'est moi (Mohamed) qui le porte pour éviter les conflits Git. Si vous avez des regex ou tokens à proposer, envoyez-les moi en clair (pas de commit direct sur `anonymizer.jj`) et je les intègre.
- Chacun committe uniquement dans son propre dossier/fichier `docs/*.md`.
- Le `rapport-final.md` est assemblé en tout dernier, une fois toutes les parties individuelles validées.
- Jeux d'essais à préparer dès que possible (idéalement dès le début de semaine) pour servir de tests pendant le développement.