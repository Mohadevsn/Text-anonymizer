# Partie 3 — Automates finis

Ramatoulaye Fall — M1 GLSI

## Méthode

Pour ne pas repartir de zéro, on a repris directement les expressions régulières
définies par Ibrahim dans [`regex.md`](regex.md) (qui elles-mêmes correspondent
exactement à `grammaire/anonymizer.jj`). Le but ici est de construire l'automate fini
correspondant à chacune des 3 regex demandées par le sujet : EMAIL, TELEPHONE, DATE.

Petite précision sur la façon dont on a représenté les choses : certaines parties des
regex sont optionnelles (l'espace entre les groupes de chiffres du téléphone,
l'indicatif `+221`...). Plutôt que de dupliquer des états pour transformer ça en
automate déterministe "pur", on a représenté l'option comme deux flèches possibles
depuis le même état (une flèche qui consomme le caractère optionnel, une flèche qui
saute directement à l'état suivant sans rien consommer). C'est une simplification
qu'on assume — un vrai DFA minimisé aurait plus d'états, mais on trouvait que ça
rendait les schémas illisibles pour rien.

Les 3 automates détaillés (états, transitions, tableaux, schéma) sont dans des fichiers
séparés :

- [`automates/email.md`](automates/email.md)
- [`automates/telephone.md`](automates/telephone.md)
- [`automates/date.md`](automates/date.md)

## Résumé rapide

| Automate | Nb d'états | État(s) final/finaux | Particularité |
|---|---|---|---|
| EMAIL | 6 | 1 état final, mais avec une boucle arrière possible (plusieurs sous-domaines/extensions) | Pas de borne sur la longueur de l'extension → c'est cette absence de borne qui cause le bug documenté par Ibrahim en Partie 5 (email qui avale le mot suivant) |
| TELEPHONE | 18 | 1 état final | Le plus complexe des 3, à cause des deux formats de préfixe (77/76/75/78/70 ou 33/32/31) et des 3 espaces optionnels |
| DATE | 11 (2 branches de 8 après le "jour") | 2 états finaux (un par branche de séparateur) | Les séparateurs `/` et espace ne se mélangent pas : soit toute la date utilise `/`, soit elle utilise des espaces, pas les deux |

On n'a pas retraité ici les conflits lexicaux (Maximal Munch, ARTICLE vs PERSON, etc.)
— c'est déjà couvert en détail par Ibrahim dans
[`maximal-munch.md`](maximal-munch.md), pas la peine de dupliquer.
