# Projet de Compilation — Anonymisation Automatique de Documents Textuels (JavaCC)

**M1 GLSI — ESP/UCAD — 2025-2026**
Date début : 12/07/2026 — Date fin : 18/07/2026

> ⚠️ Rappel : les **Parties 1 à 4** et l'**Implémentation (Partie 7)** sont strictement notées. Les autres parties (5, 6, 8, 9, 10) restent à faire mais avec moins de pression.

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
projet-anonymisation/
├── grammar/
│   └── anonymizer.jj              ← Moi (Partie 4 + 6 + 7)
├── src/                            ← Moi (Partie 7 - code généré + main)
├── tests/                          ← Équipe (Partie 9)
│   ├── exemple1.txt
│   ├── exemple2.txt
│   └── resultats-attendus/
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

## Règles de collaboration

- **Un seul fichier `.jj`** : c'est moi (Mohamed) qui le porte pour éviter les conflits Git. Si vous avez des regex ou tokens à proposer, envoyez-les moi en clair (pas de commit direct sur `anonymizer.jj`) et je les intègre.
- Chacun committe uniquement dans son propre dossier/fichier `docs/*.md`.
- Le `rapport-final.md` est assemblé en tout dernier, une fois toutes les parties individuelles validées.
- Jeux d'essais à préparer dès que possible (idéalement dès le début de semaine) pour servir de tests pendant le développement.