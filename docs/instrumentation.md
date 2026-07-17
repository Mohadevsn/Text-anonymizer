# Partie 8 — Instrumentation de l'analyseur lexical

Équipe (Ibrahim Dan Azoumi, Ramatoulaye Fall, Mohamed Wade) — M1 GLSI

## Objectif

Le sujet demande un moyen d'afficher, pour un texte donné, le type de chaque token
reconnu et le lexème exact qui a été consommé. C'est exactement l'outil qu'Ibrahim
avait bricolé "à la main" pour l'étude du Maximal Munch en
[`maximal-munch.md`](maximal-munch.md) (mentionné là-bas comme `TokenDump.java`, "pas
dans le rendu final, juste un outil de vérification"). Vu que le sujet la demande
officiellement en Partie 8, on l'a repris, nettoyé et committé pour de vrai dans
[`tools/TokenDump.java`](../tools/TokenDump.java) — les exemples de sortie de la
Partie 5 et ceux ci-dessous viennent bien du même outil.

## Principe

`TokenDump.java` n'appelle **jamais** le parseur `Anonymizer` : il instancie
directement `AnonymizerTokenManager` (le lexer généré par JavaCC depuis
`grammaire/anonymizer.jj`) sur un `SimpleCharStream`, puis boucle sur
`getNextToken()` jusqu'à `EOF`. Pour chaque token il affiche :

- son **type** (`AnonymizerConstants.tokenImage[t.kind]`, ex. `PERSON`, `EMAIL`...) ;
- sa **position** (ligne / colonne de début, `t.beginLine` / `t.beginColumn`) ;
- son **lexème** (`t.image`, la chaîne exacte consommée dans le texte source).

Comme l'outil n'utilise que le *token manager* et jamais la règle `Start`, il n'a
strictement aucun effet sur l'anonymisation elle-même : c'est un outil de lecture
seule, purement diagnostique.

```java
Reader reader = new FileReader(args[0]);
SimpleCharStream stream = new SimpleCharStream(reader);
AnonymizerTokenManager tokenManager = new AnonymizerTokenManager(stream);

Token t = tokenManager.getNextToken();
while (t.kind != AnonymizerConstants.EOF) {
    String type = AnonymizerConstants.tokenImage[t.kind].replace("<", "").replace(">", "");
    System.out.printf("%-10s %-6d %-6d [%s]%n", type, t.beginLine, t.beginColumn, t.image);
    t = tokenManager.getNextToken();
}
```

## Utilisation

```bash
# Après un ./scripts/build.sh (nécessaire pour avoir class/*.class à jour)
./scripts/trace.sh <fichier_entree>

# Équivalent manuel :
javac -cp class -d class tools/TokenDump.java
java -cp class TokenDump <fichier_entree>
```

`scripts/trace.sh` suit le même schéma que `build.sh`/`test.sh` (chemins résolus par
rapport au script, pas à la machine).

## Exemple réel — `test1_base.txt` (cas nominal)

Sortie exacte de `./scripts/trace.sh test/test1_base.txt` sur la première ligne du
fichier (`Monsieur Amadou Diallo est joignable au 77 123 45 67.`) :

```
TYPE       LIGNE  COL    LEXEME
--------------------------------------------------
ARTICLE    1      1      [Monsieur]
OTHER      1      9      [ ]
PERSON     1      10     [Amadou]
OTHER      1      16     [ ]
PERSON     1      17     [Diallo]
OTHER      1      23     [ ]
WORD       1      24     [est]
OTHER      1      27     [ ]
WORD       1      28     [joignable]
OTHER      1      37     [ ]
WORD       1      38     [au]
OTHER      1      40     [ ]
PHONE      1      41     [77 123 45 67]
OTHER      1      53     [.]
```

On voit bien "Monsieur" capté en `ARTICLE` (et pas `PERSON`) grâce à l'ordre de
déclaration, "Amadou"/"Diallo" en `PERSON`, et le numéro entier capté en un seul
`PHONE` malgré les espaces internes.

## Exemple réel — `test4_maximal_munch_bugs.txt` (bugs connus, en direct)

```
PERSON     1      1      [F]
PERSON     1      2      [A]
PERSON     1      3      [T]
PERSON     1      4      [O]
PERSON     1      5      [U]
OTHER      1      6      [ ]
PERSON     1      7      [S]
PERSON     1      8      [A]
PERSON     1      9      [R]
PERSON     1      10     [R]
...
PERSON     2      1      [Contactez]
OTHER      2      10     [ ]
EMAIL      2      11     [amadou.diallo@gmail.comMerci]
```

L'outil rend visibles, colonne par colonne, exactement les deux bugs décrits en
[`maximal-munch.md`](maximal-munch.md) : `FATOU` explosé en 5 tokens `PERSON` d'une
seule lettre, et l'email qui avale `Merci` faute de borne sur l'extension. Sans cet
affichage token-par-token, ces deux comportements seraient difficiles à distinguer
d'une simple différence de texte dans la sortie finale.

## Exemple réel — `test5_faux_positifs_negatifs.txt` (accents)

```
OTHER      2      1      [É]
WORD       2      2      [ric]
OTHER      2      5      [ ]
PERSON     2      6      [Ndiaye]
```

Confirme que "É" part seul en `OTHER` (aucune règle lettre ne couvre les majuscules
accentuées) tandis que "ric" redevient un `WORD` classique — "Éric" ne sera donc
jamais anonymisé comme un tout.

## Limites de l'outil

- Un seul fichier à la fois, pas de mode batch (pas nécessaire ici, `scripts/test.sh`
  s'en charge côté validation).
- Pas de tokens spéciaux à afficher (whitespace/commentaires) puisque la grammaire
  n'en définit pas — tout caractère non reconnu ailleurs finit de toute façon en
  `OTHER`, donc il apparaît déjà dans le flux normal.
- Sert à observer le comportement du lexer généré, pas à le corriger : les bugs qu'il
  révèle sont documentés et discutés en [`maximal-munch.md`](maximal-munch.md) et
  synthétisés en [`analyse-finale.md`](analyse-finale.md).
