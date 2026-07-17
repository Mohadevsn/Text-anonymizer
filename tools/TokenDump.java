/* TokenDump.java — Partie 8 : instrumentation de l'analyseur lexical.
 *
 * Utilitaire autonome qui appelle directement AnonymizerTokenManager (le
 * lexer généré depuis grammaire/anonymizer.jj) sur un fichier, et affiche
 * pour chaque token reconnu : son type, sa position (ligne/colonne) et le
 * lexème exact consommé. Ne touche pas au parseur ni à la sortie
 * anonymisée : c'est un outil de vérification, pas une étape du pipeline
 * principal.
 *
 * Compilation (après un ./scripts/build.sh) :
 *   javac -cp class -d class tools/TokenDump.java
 *
 * Exécution :
 *   java -cp class TokenDump <fichier_entree>
 *
 * Voir scripts/trace.sh pour un raccourci qui fait les deux étapes.
 */
import java.io.FileReader;
import java.io.Reader;

public class TokenDump {

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.out.println("Usage: java -cp class TokenDump <fichier_entree>");
            return;
        }

        Reader reader = new FileReader(args[0]);
        SimpleCharStream stream = new SimpleCharStream(reader);
        AnonymizerTokenManager tokenManager = new AnonymizerTokenManager(stream);

        System.out.printf("%-10s %-6s %-6s %s%n", "TYPE", "LIGNE", "COL", "LEXEME");
        System.out.println("-".repeat(50));

        Token t = tokenManager.getNextToken();
        while (t.kind != AnonymizerConstants.EOF) {
            String type = AnonymizerConstants.tokenImage[t.kind].replace("<", "").replace(">", "");
            String lexeme = t.image.replace("\n", "\\n");
            System.out.printf("%-10s %-6d %-6d [%s]%n", type, t.beginLine, t.beginColumn, lexeme);
            t = tokenManager.getNextToken();
        }
    }
}
