# Partie 9 — Validation

Équipe (Ibrahim Dan Azoumi, Ramatoulaye Fall, Mohamed Wade) — M1 GLSI

## Objectif

Vérifier que l'anonymiseur se comporte de façon **stable et reproductible** sur
plusieurs documents couvrant des cas différents : le cas nominal, les ambiguïtés
identifiées en [`etude-du-probleme.md`](etude-du-probleme.md), et les bugs de Maximal
Munch mis en évidence en [`maximal-munch.md`](maximal-munch.md).

**Précision importante** : "validation" ici ne veut pas dire "l'anonymiseur est
sémantiquement parfait". Les fichiers `test/expected/*.txt` ont été construits en
enregistrant la sortie **réellement produite** par le programme (y compris ses bugs
connus), pas une sortie "idéale". Un test marqué `OK` confirme donc que le
comportement observé est stable d'une exécution à l'autre — pas qu'il est correct.
L'évaluation de ce qui est correct ou non est traitée séparément en
[`etude-du-probleme.md`](etude-du-probleme.md), [`maximal-munch.md`](maximal-munch.md)
et [`analyse-finale.md`](analyse-finale.md).

## Jeux d'essai

| Fichier | Contenu | Catégories couvertes | Ce qu'il vérifie |
|---|---|---|---|
| `test1_base.txt` | Phrase simple avec un peu de tout : titre + 2 noms, téléphone, email, montant, date | `ARTICLE`, `PERSON`, `PHONE`, `EMAIL`, `AMOUNT`, `DATE` | Cas nominal, une occurrence de chaque catégorie sensible |
| `test2_dates_montants.txt` | Deux formats de date (`/` et espace) + un montant avec point décimal | `DATE`, `AMOUNT` | Les deux syntaxes de séparateur de date ; montant avec décimales |
| `test3_telephones.txt` | Plusieurs numéros (mobile + fixe) dans le même texte | `PHONE`, `PERSON` | Les deux familles de préfixes (77/70 mobile, 33 fixe) |
| `test4_maximal_munch_bugs.txt` | `FATOU SARR` (tout en majuscules) + email collé à "Merci" | `PERSON`, `EMAIL` | Les bugs documentés en Partie 5 : explosion lettre par lettre, email sans borne |
| `test5_faux_positifs_negatifs.txt` | "La reunion..." (article connu) + "Éric Ndiaye" (accent) | `ARTICLE`, `PERSON` | Faux négatif volontaire (accent non couvert) vs vrai positif (article listé) |

## Méthode d'exécution

```bash
# Build préalable requis (génère class/*.class)
./scripts/build.sh

# Lance les 5 jeux d'essai et compare chaque sortie à test/expected/
./scripts/test.sh

# Ou en une seule commande (rebuild + tests)
./scripts/test.sh --build
```

Pour chaque fichier `test/xxx.txt`, le script exécute
`java -cp class Anonymizer test/xxx.txt test/resultats/xxx_output.txt`, capture les
logs dans `test/resultats/xxx.log`, puis compare (`diff`) la sortie obtenue à
`test/expected/xxx_expected.txt` quand cette référence existe.

## Résultats obtenus (exécution réelle du 2026-07-17)

```
Fichiers de test à exécuter : 5

FICHIER                                  STATUT     COMMENTAIRE
-------                                  ------     -----------
test1_base                               OK
test2_dates_montants                     OK
test3_telephones                         OK
test4_maximal_munch_bugs                 OK
test5_faux_positifs_negatifs             OK

Résumé : 5 OK / 0 échec(s) / 0 sans référence
```

Aucune erreur d'analyse syntaxique (`ParseException`) ni erreur lexicale
(`TokenMgrError`) sur aucun des 5 fichiers — cohérent avec ce qu'on attendait, vu que
la règle `OTHER` (`~[]`) garantit qu'aucun caractère ne peut faire planter le lexer
(voir [`analyse-lexicale.md`](analyse-lexicale.md), section 5).

## Détail par test

| Test | Sortie obtenue conforme à la référence | Comportement "correct" au sens sémantique ? |
|---|---|---|
| `test1_base` | Oui | Oui — les 5 catégories sensibles sont bien anonymisées |
| `test2_dates_montants` | Oui | Oui — les deux formats de date et le montant décimal sont bien reconnus |
| `test3_telephones` | Oui | Oui — mais "Dakar" (ville) ressort en `<PERSONNE>`, limite déjà connue de la règle `PERSON` (aucune distinction nom propre de personne / lieu, hors scope du sujet) |
| `test4_maximal_munch_bugs` | Oui | **Non** — `FATOU SARR` explose en tokens `PERSON` d'une lettre, et l'email avale "Merci" ; ces deux comportements sont volontairement figés comme référence pour documenter le bug (Partie 5) plutôt que masqués |
| `test5_faux_positifs_negatifs` | Oui | **Partiel** — "La reunion..." est correctement laissé tel quel (article whitelisté), mais "Éric" reste en clair (accent non couvert) alors que "Ndiaye" est bien anonymisé |

## Ajouter un nouveau jeu d'essai

1. Déposer un fichier `test/nom_du_test.txt`.
2. Lancer `./scripts/test.sh nom_du_test` pour générer
   `test/resultats/nom_du_test_output.txt` (statut `GENERE`, pas encore de
   référence).
3. Relire la sortie à la main, et si elle est jugée correcte (ou si elle documente un
   bug connu volontairement), la copier vers
   `test/expected/nom_du_test_expected.txt` pour l'activer dans les comparaisons
   automatiques futures.
