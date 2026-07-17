# Partie 10 — Analyse finale

Équipe (Ibrahim Dan Azoumi, Ramatoulaye Fall, Mohamed Wade) — M1 GLSI

## Bilan général

L'anonymiseur reconnaît les 5 catégories sensibles demandées par le sujet (email,
téléphone, date, montant, personne) plus les tokens techniques nécessaires
(`ARTICLE`, `WORD`, `OTHER`), et passe les 5 jeux d'essai avec un statut `OK` (voir
[`validation.md`](validation.md)). Mais comme précisé dans ce même document, `OK`
signifie "comportement stable et reproductible", pas "comportement sémantiquement
parfait" : deux des cinq tests (`test4`, `test5`) enregistrent volontairement des
bugs connus comme référence, justement pour pouvoir les analyser ici.

## Performances

- Le lexer généré par JavaCC est un automate à table, **une seule passe sur le
  texte, sans retour en arrière** (le Maximal Munch se décide caractère par
  caractère en avançant, pas en réessayant plusieurs découpages). La complexité est
  donc linéaire en nombre de caractères du fichier d'entrée, indépendamment du
  nombre de règles `TOKEN` déclarées.
- Le parseur (`Start`) est lui aussi linéaire : une seule règle, pas de récursivité,
  chaque token consommé déclenche une action en O(1) (un `append` sur un
  `StringBuffer`).
- On n'a pas fait de mesure formelle (les fichiers de test font quelques lignes),
  mais l'exécution des 5 tests via `./scripts/test.sh` est instantanée à l'échelle
  humaine. Le point qui coûterait réellement cher à grande échelle serait la règle
  `EMAIL` sans borne de longueur (voir plus bas) : dans le pire cas elle peut avaler
  un nombre arbitraire de caractères avant de s'arrêter, mais ça reste O(n) au total,
  pas quadratique — juste "un seul token anormalement gros" plutôt qu'un vrai
  problème de performance.

## Rôle du Maximal Munch

Le Maximal Munch est à la fois ce qui **fait marcher** la reconnaissance normale et
ce qui **cause** la totalité des bugs identifiés (voir l'étude complète en
[`maximal-munch.md`](maximal-munch.md)) :

- Il fait marcher `PHONE`, `DATE`, `AMOUNT`, `EMAIL` correctement dans les cas
  standards, en captant chaque motif en un seul token le plus long possible.
- Il résout le conflit `ARTICLE` vs `PERSON` (`"Le"`, `"Bonjour"`...) uniquement
  parce qu'on a placé `ARTICLE` avant `PERSON` dans le fichier — sans cet ordre de
  déclaration, le mécanisme jouerait contre nous.
- Il est **directement responsable** du bug `FATOU` → 5 tokens `PERSON` d'une
  lettre : à la 2e lettre du mot, plus aucune règle ne peut s'étendre davantage que
  1 caractère, donc le Maximal Munch redémarre encore et encore à la position
  suivante.
- Il est aussi responsable de l'email qui avale "Merci" : ce n'est pas un défaut de
  l'algorithme lui-même, mais de la regex `EMAIL` qui ne borne pas la longueur de
  l'extension — le Maximal Munch fait exactement ce qu'on lui a demandé de faire.

En résumé : le Maximal Munch n'est jamais "en tort" en tant que mécanisme, il révèle
juste, de façon très mécanique, les endroits où les regex elles-mêmes sont trop
permissives ou incomplètes.

## Limites connues (synthèse)

| # | Limite | Origine | Détaillé dans |
|---|---|---|---|
| 1 | Noms entièrement en majuscules explosent lettre par lettre | Règle `PERSON` = `[A-Z][a-z]*`, ne peut avancer que sur des minuscules après la 1ère lettre | `etude-du-probleme.md`, `maximal-munch.md` |
| 2 | Lettres majuscules accentuées non reconnues (`Éric` → `É` + `ric`) | `PERSON`/`WORD` limités à `A-Z`/`a-z` ASCII | `etude-du-probleme.md`, `maximal-munch.md` |
| 3 | Email sans espace après avale le mot suivant | Extension email `("." [a-zA-Z]+)+` sans borne haute | `regex.md`, `maximal-munch.md` |
| 4 | Liste `ARTICLE` forcément incomplète | Whitelist fermée de mots courants, pas de vraie détection de début de phrase | `etude-du-probleme.md`, `regex.md` |
| 5 | Montant sans devise non reconnu | Choix volontaire pour éviter de transformer n'importe quel nombre en montant | `regex.md` |
| 6 | Pas de validation sémantique des dates (`32/13/2026` accepté) | Hors scope pour une regex lexicale | `regex.md` |
| 7 | Téléphone limité aux préfixes sénégalais | Le sujet ne demandait pas l'international | `regex.md` |
| 8 | Noms de lieux confondus avec des noms de personne (ex. "Dakar" → `<PERSONNE>`) | `PERSON` ne distingue pas les catégories de noms propres | `validation.md` |

## Améliorations possibles

- **`PERSON`** : étendre les classes de caractères pour couvrir les majuscules/minuscules
  accentuées (`À-Ö`, `Ø-Þ`, `à-ö`, `ø-ÿ` en Latin-1 étendu), et ajouter une alternative
  qui capte un mot entièrement en majuscules (`["A"-"Z"](["A"-"Z"])+`) déclarée avec la
  bonne priorité pour éviter que le Maximal Munch la découpe lettre par lettre.
- **`EMAIL`** : borner la longueur de l'extension, par exemple
  `("." (["a"-"z","A"-"Z"]){2,24})+`, pour éviter qu'elle avale indéfiniment le texte
  qui suit quand il n'y a pas d'espace de séparation.
- **`ARTICLE`** : remplacer (ou compléter) la liste fermée par une vraie détection de
  début de phrase (position juste après un `.`, `!`, `?` ou en tout début de
  document) combinée à une règle plus fine pour `PERSON`, plutôt que de dépendre
  d'une énumération qui ne pourra jamais être exhaustive.
- **`AMOUNT`** : envisager un token "nombre nu" séparé, anonymisé seulement si le
  contexte syntaxique le justifie (ex. après un verbe comme "payer", "coûter") —
  nécessiterait de sortir du seul niveau lexical, donc un vrai compromis à discuter.
- **`DATE`** : ajouter une vérification sémantique légère (jour ≤ 31, mois ≤ 12) au
  niveau de l'action sémantique du parseur plutôt que dans la regex, ce qui reste
  cohérent avec la séparation lexical/syntaxique déjà en place.
- **`PERSON` vs lieux** : hors de portée d'une regex seule (nécessiterait une liste de
  toponymes ou un vrai NER) — à documenter comme limite assumée plutôt qu'à tenter de
  corriger dans ce projet.

## Conclusion

Le pipeline JavaCC (lexer table-driven + grammaire plate à une seule règle) est
largement suffisant pour le besoin du sujet : anonymiser un texte français en
remplaçant des motifs reconnaissables par des balises, sans en changer la structure.
Les limites identifiées ne sont pas des erreurs d'implémentation du Maximal Munch —
elles viennent toutes de regex volontairement simples, documentées et assumées comme
telles dès la Partie 1, puis vérifiées concrètement avec l'outil d'instrumentation
(Partie 8) et les jeux d'essai (Partie 9). Une version "production" du projet
reprendrait la liste des améliorations ci-dessus, mais le compromis actuel —
regex simples et lisibles, limites documentées plutôt que masquées — correspondait
mieux à l'objectif pédagogique du projet.
