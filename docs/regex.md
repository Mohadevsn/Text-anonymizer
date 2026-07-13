# Partie 2 — Expressions régulières

Ibrahim Dan Azoumi — M1 GLSI

Les regex ci-dessous sont celles réellement utilisées dans `grammaire/anonymizer.jj`
(section TOKEN). On les réécrit ici en notation "classique" (style regex) pour pouvoir
les commenter, mais elles correspondent exactement à ce qui est codé, on n'a rien
inventé de notre côté.

## EMAIL

```
[a-zA-Z0-9_.-]+ @ [a-zA-Z0-9-]+ ("." [a-zA-Z]+)+
```

- La partie locale (avant le `@`) accepte lettres, chiffres, `_`, `.` et `-`, ce qui
  couvre la grande majorité des adresses réelles (`amadou.diallo`, `a_diallo-2026`...).
- Le nom de domaine n'accepte pas le point directement (il est géré séparément par
  `("." [a-zA-Z]+)+`) pour permettre plusieurs sous-domaines/extensions, genre
  `.univ-dakar.sn` ou `.co.uk`.
- **Limite qu'on a identifiée** : cette dernière partie n'a pas de longueur max, donc
  si le texte n'a pas d'espace après l'email, la regex continue à manger les
  lettres suivantes en pensant que c'est encore une extension (voir `test4`, où
  `amadou.diallo@gmail.comMerci` devient un seul email `amadou.diallo@gmail.comMerci`
  au lieu de `amadou.diallo@gmail.com` + le mot "Merci"). On le signale comme
  limite plutôt que de le corriger nous-mêmes, vu que le fichier `.jj` appartient à
  Mohamed.

## TELEPHONE

```
(+221 ?)? (77|76|75|78|70|33|32|31) ?[0-9]{3} ?[0-9]{2} ?[0-9]{2}
```

- On s'est limité aux formats sénégalais réels : les préfixes mobiles (77, 76, 78, 70,
  75) et fixes (33, 32, 31).
- Les espaces entre les groupes de chiffres sont optionnels partout, ce qui permet de
  reconnaître aussi bien `771234567` que `77 123 45 67`.
- L'indicatif `+221` est optionnel lui aussi.
- **Choix discutable qu'on assume** : on ne gère pas les indicatifs d'autres pays. Le
  sujet ne demandait pas l'international donc on est restés sur le Sénégal, mais ça
  vaut la peine de le mentionner comme limite si jamais un email ou un texte contient
  un numéro français par exemple.

## DATE

```
[0-9]{2} / [0-9]{2} / [0-9]{4}
[0-9]{2} " " [0-9]{2} " " [0-9]{4}
```

- Deux formats acceptés : avec `/` (`15/06/2026`) ou avec des espaces
  (`15 06 2026`).
- On n'a pas mis de validation sur les valeurs (genre rejeter "32/13/2026"), la regex
  vérifie juste le format, pas que la date existe vraiment. On considère que ce n'est
  pas le rôle de l'analyseur lexical de faire ça — c'est plutôt une histoire de
  validation sémantique, donc hors scope pour une regex.
- Comme dit en partie 1, `jj/mm/aaaa` est une hypothèse (format français), la regex ne
  peut pas distinguer toute seule si c'est jour/mois ou mois/jour.

## MONTANT

```
[0-9]+ ("." [0-9]+)? " "? (FCFA|CFA|F|$|€)
```

- Un nombre entier obligatoire, une partie décimale optionnelle (`12.50`), un espace
  optionnel avant la devise, puis une des devises supportées.
- On a mis `FCFA` avant `F` dans l'énumération pour que JavaCC essaie d'abord de
  matcher la devise la plus longue possible (même si en pratique avec le maximal
  munch l'ordre des alternatives dans un même OU ne change rien au résultat, seule la
  longueur du match compte — mais ça reste plus lisible de le voir écrit dans cet
  ordre).
- **Limite** : un montant sans devise du tout (juste "250000") n'est pas reconnu comme
  MONTANT, il tombe dans WORD/OTHER caractère par caractère selon comment JavaCC le
  découpe. On ne pouvait pas faire autrement sans risquer de transformer n'importe
  quel nombre du texte (numéro de téléphone partiel, année...) en montant.

## PERSON (nom propre)

```
[A-Z] [a-z]*
```

- Une majuscule suivie de zéro ou plusieurs minuscules. C'est la règle du sujet
  ("mots commençant par une majuscule"), appliquée au sens strict.
- **C'est la regex qui nous a posé le plus de questions.** Deux problèmes qu'on détaille
  aussi en partie 5 (Maximal Munch) :
  - elle ne couvre que `A-Z` en ASCII, donc un nom accentué comme `Éric` n'est pas
    reconnu du tout ;
  - elle ne matche qu'une seule majuscule suivie de minuscules, donc un nom écrit tout
    en majuscules (`FATOU`) ne peut pas être capturé comme un seul token — chaque
    lettre majuscule redevient un match séparé de longueur 1.
  - On a choisi de documenter ces deux limites plutôt que de proposer une regex
    "corrigée" nous-mêmes, parce que ce n'était pas notre lot dans le projet
    (Mohamed avait dit l'avoir fait exprès, justement pour qu'on le remarque et
    qu'on le commente ici).

## Token ARTICLE (mots-vides en début de phrase)

Ce n'est pas demandé dans le sujet en tant que catégorie séparée, mais on le mentionne
parce qu'il sert directement à limiter les faux positifs sur PERSON :

```
Le|La|Les|Un|Une|Des|Du|Son|Sa|Ses|Ce|Cette|Ces|Cet|Il|Elle|Ils|Elles|On|
Je|Tu|Nous|Vous|Bonjour|Bonsoir|Merci|Salut|Oui|Non|Monsieur|Madame|Mr|Me|Mdm
```

- C'est une énumération fermée de mots courants qui commencent par une majuscule mais
  qui ne sont clairement pas des noms propres.
- Elle doit être déclarée **avant** PERSON dans le fichier `.jj` pour gagner en cas
  d'égalité de longueur au moment du Maximal Munch (sinon PERSON matcherait aussi
  "Le", "Bonjour" etc., vu que ça respecte bien la règle "majuscule + minuscules").
- **Limite évidente** : la liste ne peut pas être exhaustive. N'importe quel mot de
  début de phrase qui n'y figure pas repassera en PERSON. C'est un compromis, pas une
  vraie solution au problème.

## WORD (mot ordinaire)

```
[a-z]+
```

Tout mot qui commence par une minuscule. Simple, pas de piège particulier ici — sauf
que par définition elle ne matche jamais un mot en début de phrase (puisqu'en français
on met une majuscule en début de phrase), ce qui est normal.

## OTHER (autre caractère)

```
.
```

Un seul caractère, n'importe lequel (`~[]` dans la syntaxe JavaCC, c'est-à-dire
"tout sauf rien"). Ce token doit être déclaré en dernier dans le fichier, sinon il
prendrait la priorité sur tout le reste. Son rôle est juste d'éviter que le programme
plante (`TokenMgrError`) sur un caractère qu'aucune autre règle ne reconnaît —
ponctuation, chiffres isolés, caractères accentués dans des mots normaux, etc.

## Pourquoi ces choix, en résumé

On a essayé de rester sur des regex simples qui collent au sujet, plutôt que de
vouloir tout couvrir (ex: accents, formats internationaux). Le compromis c'est qu'on a
des cas connus qui cassent, mais on préfère les documenter clairement (voir partie 5)
plutôt que prétendre que tout fonctionne parfaitement.
