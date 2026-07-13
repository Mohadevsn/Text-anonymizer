# Partie 1 — Étude du problème

Ibrahim Dan Azoumi — M1 GLSI

## Contexte

Le but du projet est d'anonymiser un texte en français : on doit repérer les infos
sensibles (email, téléphone, date, montant, nom de personne) et les remplacer par une
balise du genre `<EMAIL>`, sans toucher au reste de la phrase.

Pour cette partie on s'est basé directement sur ce que Mohamed a implémenté dans
`grammaire/anonymizer.jj`, pas sur une version "idéale" qu'on aurait pu imaginer de notre
côté. C'est important parce que pas mal des difficultés qu'on liste plus bas viennent
justement de choix faits dans le code (volontairement ou pas).

## 1. Catégories d'informations à anonymiser

On a 5 catégories vraiment "sensibles" :

- **Email** — ex. `amadou.diallo@gmail.com`
- **Téléphone** — formats sénégalais, ex. `77 123 45 67` ou `+221 77 123 45 67`
- **Date** — ex. `15/06/2026`
- **Montant** — ex. `250000 FCFA`
- **Nom propre / personne** — ex. `Amadou`, `Diallo`

Et deux catégories "techniques" qui ne sont pas sensibles mais qu'il faut quand même
définir pour que l'analyseur lexical marche sur n'importe quel texte :

- **Mot ordinaire** (WORD) : un mot qui commence par une minuscule, genre "est",
  "joignable", "au"...
- **Autre caractère** (OTHER) : tout ce qui ne rentre dans aucune catégorie
  au-dessus — ponctuation, chiffres isolés, caractères accentués, etc. C'est le
  "filet de sécurité" qui évite que le programme plante sur un caractère
  imprévu.

Il y a aussi une catégorie ARTICLE (Le, La, Monsieur, Bonjour...) qui n'est pas dans le
sujet mais que Mohamed a ajoutée dans le code. On y revient dans la partie difficultés,
parce qu'en fait elle sert juste à éviter un problème avec les noms propres.

## 2. Règles de reconnaissance

- Un **email** = un bloc de caractères, un `@`, un nom de domaine, un point, une
  extension.
- Un **téléphone** = un préfixe sénégalais connu (77, 76, 78...) éventuellement précédé
  de `+221`, suivi de 7 chiffres, avec ou sans espaces entre les groupes.
- Une **date** = jour/mois/année sur 2/2/4 chiffres, séparés par `/` ou par un espace.
- Un **montant** = un nombre (avec décimales possibles) suivi d'une devise (FCFA, CFA,
  F, $, €).
- Une **personne** = un mot qui commence par une majuscule suivie de minuscules.

Cette dernière règle est volontairement simple (c'est littéralement "majuscule +
minuscules"), et c'est là que ça devient intéressant pour la suite parce que le
français a pas mal de cas qui cassent cette règle.

## 3. Difficultés possibles

On a testé le programme avec les jeux d'essai fournis (`test4_maximal_munch_bugs.txt`
et `test5_faux_positifs_negatifs.txt`) et on a listé les vrais problèmes qu'on a
observés, pas juste des problèmes théoriques :

**a) Les majuscules en début de phrase.** Si on ne fait rien, n'importe quel mot en
début de phrase ("Le", "Bonjour", "Monsieur"...) commence par une majuscule et serait
donc pris pour un nom de personne. C'est pour ça que le token ARTICLE existe dans le
code : c'est une liste blanche de mots courants qui doit être vérifiée avant PERSON.
Le souci c'est que cette liste est forcément incomplète, donc si un mot n'y est pas,
il repasse en PERSON. Exemple concret : `test5_faux_positifs_negatifs.txt` contient
"La reunion commence..." et "La" est bien dans la liste donc ça passe, mais un autre
mot au hasard en début de phrase ne serait pas protégé.

**b) Les noms entièrement en majuscules.** On l'a vu directement en testant : sur
`FATOU SARR`, le résultat obtenu est `<PERSONNE><PERSONNE><PERSONNE><PERSONNE><PERSONNE>
<PERSONNE><PERSONNE><PERSONNE><PERSONNE>` — chaque lettre devient un `<PERSONNE>`
séparé. Ça vient du fait que la règle PERSON attend une seule majuscule suivie de
minuscules ; sur un mot tout en majuscules, dès la 2e lettre ça ne matche plus, donc
JavaCC redécoupe lettre par lettre. C'est un vrai bug, pas juste un détail : le
document "anonymisé" devient illisible à cet endroit.

**c) Les caractères accentués.** `Éric` n'est pas reconnu comme un nom parce que la
règle PERSON ne définit que `A-Z` (donc sans les majuscules accentuées comme É, È...).
Résultat vérifié sur `test5` : `Éric Ndiaye` devient `Éric <PERSONNE>` — seul "Ndiaye"
est anonymisé, "Éric" reste écrit en clair. C'est plutôt gênant vu que le but du
projet est justement la confidentialité.

**d) Email collé au mot suivant.** Sur `amadou.diallo@gmail.comMerci` (sans espace
après le point), l'analyseur avale "Merci" dans le nom de domaine parce que la règle
d'extension email n'a pas de limite de longueur. Le résultat anonymisé perd le mot
"Merci" alors qu'il n'avait rien de sensible.

**e) Ambiguïté des dates.** Le format `15/06/2026` peut se lire jour/mois/année ou
mois/jour/année selon le pays. On a choisi jour/mois/année (format français/sénégalais)
mais ça reste une hypothèse, pas une certitude garantie par la regex.

**f) Montants sans devise.** Un nombre seul comme "250000" sans "FCFA" derrière n'est
pas reconnu comme montant, il devient juste un `WORD`/`OTHER` normal. Donc si quelqu'un
écrit "il a payé 250000 pour la voiture" sans unité, le montant n'est pas anonymisé.

Ces points-là (surtout b, c et d) sont repris plus en détail dans la partie sur le
Maximal Munch, parce que ce sont typiquement des conflits qui viennent de la façon
dont JavaCC choisit le token le plus long.
