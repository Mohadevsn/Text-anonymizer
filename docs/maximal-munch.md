# Partie 5 — Principe du Maximal Munch

Ibrahim Dan Azoumi — M1 GLSI

Pour cette partie on n'a pas voulu deviner comment JavaCC découpe le texte, donc on a
écrit un petit programme à part (`TokenDump.java`, pas dans le rendu final, juste un
outil de vérification) qui appelle directement `AnonymizerTokenManager` — le lexer
généré par `anonymizer.jj` — sur des phrases tests, et qui affiche pour chaque token
son type et son lexème. Tout ce qui suit est donc le résultat réel du programme, pas
une supposition.

## Rappel du principe

Le Maximal Munch, c'est la règle que JavaCC applique par défaut : à chaque position
dans le texte, parmi toutes les règles TOKEN qui peuvent matcher, il choisit celle qui
consomme **le plus de caractères possible**. S'il y a une égalité de longueur entre
plusieurs règles, c'est **l'ordre de déclaration dans le fichier `.jj`** qui décide (la
première déclarée gagne).

Dans notre fichier, l'ordre est : `ARTICLE`, `EMAIL`, `PHONE`, `DATE`, `AMOUNT`,
`PERSON`, `WORD`, `OTHER`. Cet ordre n'est pas anodin, comme on va le voir.

## Étude de plusieurs chaînes d'entrée

### 1. `FATOU SARR a signe le contrat.`

```
PERSON [F]
PERSON [A]
PERSON [T]
PERSON [O]
PERSON [U]
OTHER  [ ]
PERSON [S]
PERSON [A]
PERSON [R]
PERSON [R]
OTHER  [ ]
WORD   [a]
WORD   [signe]
WORD   [le]
WORD   [contrat]
OTHER  [.]
```

Chaque lettre de "FATOU" devient un token PERSON séparé. Le Maximal Munch essaie de
matcher le plus long possible à partir de "F" : la règle PERSON est
`[A-Z] [a-z]*`, donc à la position du "F" elle peut matcher "F" puis regarder si le
caractère suivant est une minuscule. Ici le caractère suivant est "A" (majuscule), donc
`[a-z]*` s'arrête tout de suite : le plus long match possible pour PERSON à cette
position est "F" seul, longueur 1. Aucune autre règle ne fait mieux à cette position
(WORD ne matche pas du tout puisqu'elle exige une minuscule au départ). Donc le
Maximal Munch redémarre à "A" et refait exactement le même raisonnement, etc.

### 2. `Éric Ndiaye a signe le document.`

```
OTHER  [É]
WORD   [ric]
OTHER  [ ]
PERSON [Ndiaye]
WORD   [a]
WORD   [signe]
WORD   [le]
WORD   [document]
OTHER  [.]
```

Ici c'est différent : "É" n'est reconnu par **aucune** règle définie sur des lettres
(PERSON, WORD et ARTICLE ne définissent que `A-Z`/`a-z` en ASCII). Le seul token qui
peut matcher "É" est OTHER (`~[]`, un caractère quelconque), donc il part tout seul en
OTHER, longueur 1 — pas de compétition possible ici, il n'y a qu'une seule règle
capable de le prendre. Ensuite le lexer repart à "r", qui est une minuscule : WORD
prend "ric" en entier (3 lettres) parce que WORD peut avancer tant qu'il voit des
minuscules. Résultat : "Éric" est coupé en deux tokens qui n'ont plus rien à voir avec
un nom de personne.

### 3. `amadou.diallo@gmail.comMerci pour votre comprehension.`

```
EMAIL [amadou.diallo@gmail.comMerci]
WORD  [pour]
WORD  [votre]
WORD  [comprehension]
OTHER [.]
```

Là le Maximal Munch fait exactement ce qu'on lui demande, le problème c'est que la
règle EMAIL elle-même est trop permissive. Après le `.` de "gmail.com", la règle
d'extension est `("." [a-zA-Z]+)+` : elle ne s'arrête pas après "com", elle continue à
lire tant qu'elle voit des lettres. Comme "Merci" est collé directement après "com"
(pas d'espace dans le texte d'entrée), EMAIL continue de matcher jusqu'à la fin de
"Merci". Le token le plus long gagne, donc EMAIL avale "comMerci" en un seul bloc.
Ce n'est pas un problème d'algorithme de Maximal Munch, c'est la regex EMAIL qui
n'a pas de limite haute sur la longueur de l'extension.

### 4. `Le paiement de 250000 FCFA a ete effectue le 15/06/2026.`

```
ARTICLE [Le]
WORD    [paiement]
WORD    [de]
AMOUNT  [250000 FCFA]
WORD    [a]
WORD    [ete]
WORD    [effectue]
WORD    [le]
DATE    [15/06/2026]
OTHER   [.]
```

Celle-là marche comme prévu, on la garde comme référence "cas normal" pour comparer.
On note quand même le conflit potentiel intéressant : à la position de "Le", deux
règles peuvent matcher — ARTICLE (`"Le"`, longueur 2) et PERSON (`[A-Z][a-z]*`, qui
matche aussi "Le", longueur 2). **Même longueur**, donc c'est l'ordre de déclaration
qui tranche : ARTICLE est déclaré avant PERSON dans le fichier, donc ARTICLE gagne. Si
jamais quelqu'un inversait l'ordre des deux blocs TOKEN dans `anonymizer.jj`, "Le"
deviendrait `<PERSONNE>` au lieu de rester "Le" — ça montre bien que l'ordre de
déclaration n'est pas un détail cosmétique.

### 5. `Bonjour Amadou, contactez-moi au 77 123 45 67.`

```
ARTICLE [Bonjour]
PERSON  [Amadou]
OTHER   [,]
WORD    [contactez]
OTHER   [-]
WORD    [moi]
WORD    [au]
PHONE   [77 123 45 67]
OTHER   [.]
```

Ici aussi tout se passe comme prévu : "Bonjour" est dans la liste ARTICLE donc il
gagne le conflit de longueur face à PERSON (même logique que pour "Le" au-dessus),
et "Amadou" n'étant pas dans la liste ARTICLE, il devient bien PERSON.

## Conflits lexicaux identifiés

En résumé, ce qu'on a repéré comme vrais conflits de Maximal Munch (pas juste des
"bugs" au sens large, mais des situations où plusieurs règles sont candidates) :

1. **ARTICLE vs PERSON** — conflit systématique sur tout mot en majuscule qui est
   dans la liste ARTICLE ("Le", "Bonjour", "Monsieur"...). Toujours à égalité de
   longueur, toujours résolu par l'ordre de déclaration (ARTICLE avant PERSON). Ça
   marche, mais uniquement pour les mots listés — ce n'est pas une vraie résolution
   du conflit, juste un contournement pour les cas connus.

2. **PERSON face à un mot tout en majuscules** — pas vraiment un conflit entre deux
   règles, plutôt une limite de la règle PERSON elle-même : à la 2e lettre d'un mot
   tout en majuscules, PERSON ne peut plus s'étendre (elle n'accepte que des
   minuscules après la 1ère lettre) donc le Maximal Munch la coupe à longueur 1,
   encore et encore.

3. **Aucune règle "lettre" ne couvre les caractères accentués** — donc pas de
   conflit à proprement parler, mais un trou de couverture : OTHER récupère le
   caractère accentué seul, et le reste du mot (en minuscules) part dans WORD. Le nom
   n'est jamais anonymisé.

4. **EMAIL sans borne de longueur sur l'extension** — l'extension email peut, en
   théorie, avaler n'importe quelle suite de lettres qui suit immédiatement, y compris
   un mot qui n'a rien à voir avec l'email si le texte source n'a pas d'espace de
   séparation.

Ces quatre points sont ceux qu'on propose de citer aussi dans la partie difficultés
(Partie 1) et dans l'analyse finale (Partie 10), vu qu'ils viennent directement du
comportement du Maximal Munch et pas d'un choix de conception qu'on pourrait justifier
autrement.
