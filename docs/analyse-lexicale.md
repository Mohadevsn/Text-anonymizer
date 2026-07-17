# Partie 4 + Partie 6 — Analyse lexicale et grammaire syntaxique

Mohamed Wade — M1 GLSI

## Méthode

Ce document décrit le côté implémentation JavaCC de `grammaire/anonymizer.jj` : comment
les catégories définies par Ibrahim en [`etude-du-probleme.md`](etude-du-probleme.md) et
[`regex.md`](regex.md) sont traduites en blocs `TOKEN` JavaCC (Partie 4), puis comment la
règle de départ `Start` consomme ce flux de tokens pour produire le texte anonymisé
(Partie 6). Les deux parties sont regroupées dans un seul fichier parce qu'elles vivent
dans le même `.jj` et se lisent mieux ensemble : la grammaire syntaxique ici est
volontairement plate, elle ne fait qu'aiguiller chaque token vers une action, donc la
séparer de la partie lexicale aurait cassé la lecture pour peu de gain.

## 1. Les tokens définis

| Token | Rôle | Remplacé par (Partie 7) |
|---|---|---|
| `ARTICLE` | Mots-vides / articles en début de phrase (liste fermée) | recopié tel quel |
| `EMAIL` | Adresse email | `<EMAIL>` |
| `PHONE` | Numéro de téléphone sénégalais | `<TELEPHONE>` |
| `DATE` | Date `jj/mm/aaaa` ou `jj mm aaaa` | `<DATE>` |
| `AMOUNT` | Montant + devise | `<MONTANT>` |
| `PERSON` | Nom propre (majuscule + minuscules) | `<PERSONNE>` |
| `WORD` | Mot ordinaire (minuscules) | recopié tel quel |
| `OTHER` | N'importe quel autre caractère (filet de sécurité) | recopié tel quel |

Ces 8 tokens sont exactement ceux listés dans `AnonymizerConstants.java` généré par
JavaCC (`EOF`, puis `ARTICLE`...`OTHER` dans cet ordre, indices 0 à 8) — voir
[`instrumentation.md`](instrumentation.md) pour un outil qui affiche ces types en
direct sur un fichier.

## 2. Ordre de déclaration : la vraie règle qui régit le fichier

JavaCC applique le **Maximal Munch** (le token le plus long gagne) et, en cas
d'égalité de longueur, c'est **l'ordre de déclaration des blocs `TOKEN` dans le
fichier** qui décide (voir l'étude complète en
[`maximal-munch.md`](maximal-munch.md)). C'est pour ça que l'ordre choisi dans
`anonymizer.jj` n'est pas arbitraire :

```
ARTICLE → EMAIL → PHONE → DATE → AMOUNT → PERSON → WORD → OTHER
```

- `ARTICLE` est déclaré **avant** `PERSON` : sur un mot comme `"Le"`, les deux règles
  matchent une chaîne de même longueur (2 caractères), donc sans cet ordre `"Le"`
  deviendrait `<PERSONNE>` au lieu d'être recopié.
- `PERSON` est déclaré **avant** `WORD` : ce n'est pas un vrai conflit de longueur
  (les deux alphabets de départ — majuscule vs minuscule — sont disjoints), mais ça
  garde la lecture du fichier cohérente avec la logique "du plus spécifique au plus
  général".
- `OTHER` (`~[]`, n'importe quel caractère) est déclaré **en dernier**. S'il était
  placé avant, il absorberait tout et aucune autre règle ne pourrait jamais gagner.

## 3. Détail des règles lexicales (syntaxe JavaCC)

Extrait fidèle de `grammaire/anonymizer.jj` (section `TOKEN`), avec les choix
d'écriture propres à JavaCC :

```java
TOKEN : {
    < ARTICLE : "Le" | "La" | "Les" | "Un" | "Une" | "Des" | "Du"
              | "Son" | "Sa" | "Ses"
              | "Ce" | "Cette" | "Ces" | "Cet"
              | "Il" | "Elle" | "Ils" | "Elles" | "On"
              | "Je" | "Tu" | "Nous" | "Vous"
              | "Bonjour" | "Bonsoir" | "Merci" | "Salut" | "Oui" | "Non"
              | "Monsieur" | "Madame" | "Mr" | "Me" | "Mdm"
    >
}

TOKEN : {
    < EMAIL : (["a"-"z","A"-"Z","0"-"9","_",".","-"])+
              "@"
              (["a"-"z","A"-"Z","0"-"9","-"])+
              ("." (["a"-"z","A"-"Z"])+)+
    >
}

TOKEN : {
    < PHONE : ("+221" (" ")?)?
              ("77" | "76" | "75" | "78" | "70" | "33" | "32" | "31") (" ")?
              (["0"-"9"]){3} (" ")?
              (["0"-"9"]){2} (" ")?
              (["0"-"9"]){2}
    >
}

TOKEN : {
    < DATE : (["0"-"9"]){2} "/" (["0"-"9"]){2} "/" (["0"-"9"]){4}
           | (["0"-"9"]){2} " " (["0"-"9"]){2} " " (["0"-"9"]){4} >
}

TOKEN : {
    < AMOUNT : (["0"-"9"])+ ("." (["0"-"9"])+)? (" ")? ("FCFA" | "CFA" | "F" | "$" | "€") >
}

TOKEN : {
    < PERSON : ["A"-"Z"] (["a"-"z"])* >
}

TOKEN : {
    < WORD : ["a"-"z"] (["a"-"z"])* >
}

TOKEN : {
    < OTHER : ~[] >
}
```

Pourquoi un bloc `TOKEN` par catégorie plutôt qu'un seul gros bloc avec toutes les
définitions dedans : purement lisibilité, JavaCC ne fait aucune différence, l'ordre
global des blocs (et donc des règles) reste le même que si tout avait été regroupé.

Deux détails d'implémentation à signaler, communs à Ibrahim/Ramatoulaye et à moi :

- Ces règles sont **exactement** ce qu'Ibrahim documente en `regex.md`, je n'ai rien
  changé après leur relecture — les limites qu'ils ont identifiées (pas de borne sur
  l'extension email, `PERSON` limité à `A-Z` ASCII...) sont donc bien réelles dans le
  code, pas des suppositions théoriques.
- `AnonymizerConstants.java` (généré) confirme l'ordre : `EOF=0, ARTICLE=1, EMAIL=2,
  PHONE=3, DATE=4, AMOUNT=5, PERSON=6, WORD=7, OTHER=8`. Ce sont ces indices que
  `AnonymizerTokenManager` utilise en interne pour trancher les égalités de longueur.

## 4. Grammaire syntaxique (Partie 6)

Le sujet ne demande pas une syntaxe imbriquée (pas de phrases, pas de blocs) : le but
est d'anonymiser un flux de tokens indépendants les uns des autres. La grammaire
syntaxique est donc volontairement plate — une seule règle de départ, une répétition
d'alternatives :

```
Start → ( ARTICLE | EMAIL | PHONE | DATE | AMOUNT | PERSON | WORD | OTHER )* EOF
```

Traduite en JavaCC, avec les actions sémantiques qui construisent le texte de sortie
au fur et à mesure (`buffer` est passé en paramètre par `main`, voir Partie 7) :

```java
void Start(StringBuffer buffer) :
{
    Token t;
}
{
    (
        t = < ARTICLE >
        { buffer.append(t.image);}
        |
        t = < EMAIL >
        { buffer.append("<EMAIL>"); }
        |
        t = < PHONE >
        { buffer.append("<TELEPHONE>"); }
        |
        t = < DATE >
        { buffer.append("<DATE>"); }
        |
        t = < AMOUNT >
        { buffer.append("<MONTANT>"); }
        |
        t = < PERSON >
        { buffer.append("<PERSONNE>"); }
        |
        ( t = < WORD > | t = < OTHER > )
        { buffer.append(t.image); }
    )*
    <EOF>
}
```

Points à noter :

- **Une seule règle non-terminale.** Il n'y a pas besoin de récursivité ou de
  sous-règles : chaque token se traite indépendamment de son contexte (contrairement à
  une vraie grammaire de phrase). C'est cohérent avec le fait que l'anonymisation est
  un remplacement token-par-token, pas une analyse sémantique du texte.
- **`WORD` et `OTHER` partagent la même action** (`buffer.append(t.image)`), donc ils
  sont regroupés dans une même alternative imbriquée plutôt que dupliqués — évite une
  ligne identique en plus, rien de plus.
- **Les tokens catégorie "sensible"** (`EMAIL`, `PHONE`, `DATE`, `AMOUNT`, `PERSON`)
  n'ajoutent jamais `t.image` au buffer : leur lexème original disparaît complètement,
  remplacé par la balise. C'est la seule vraie logique métier de tout le parseur.
- **`ARTICLE`, `WORD`, `OTHER`** recopient `t.image` tel quel : c'est ce qui garantit
  que le reste du texte (ponctuation, espaces, mots courants) n'est jamais modifié.

## 5. Choix JavaCC autour de la grammaire

- `options { STATIC = false ; }` : nécessaire parce que `Start` reçoit un paramètre
  (`StringBuffer buffer`) qui doit être propre à chaque instance de `Anonymizer` — le
  mode statique par défaut de JavaCC ne permet pas ça proprement si on veut rester
  réentrant.
- Le bloc `PARSER_BEGIN(Anonymizer) ... PARSER_END(Anonymizer)` contient directement
  `public static void main` : lecture du fichier d'entrée (`FileReader`), appel à
  `parser.Start(buffer)`, écriture du résultat (`FileWriter`). Voir le détail de
  l'implémentation complète (Partie 7) dans `src/Anonymizer.java` généré et
  `README.md`.
- Deux erreurs sont explicitement distinguées à l'exécution : `ParseException`
  (aucune règle syntaxique ne peut avancer — en pratique quasi impossible ici vu que
  `Start` accepte n'importe quelle suite de tokens grâce à `OTHER`) et `TokenMgrError`
  (aucune règle lexicale ne peut matcher un caractère — également couvert par `OTHER`
  qui matche `~[]`, donc ce cas ne devrait jamais se produire en pratique non plus).
  On les garde quand même dans `main` par prudence, au cas où la grammaire évoluerait.

## 6. Génération

`scripts/build.sh` appelle `javacc -OUTPUT_DIRECTORY=src grammaire/anonymizer.jj`, ce
qui produit `Anonymizer.java`, `AnonymizerConstants.java`, `AnonymizerTokenManager.java`,
`ParseException.java`, `SimpleCharStream.java`, `Token.java` et `TokenMgrError.java`
dans `src/` (à ne jamais éditer à la main, voir la remarque dans `README.md`), puis
compile tout avec `javac -d class src/*.java`. Le seul fichier source de vérité reste
`grammaire/anonymizer.jj`.
