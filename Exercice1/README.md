# Exercice 1

## Evaluateur d'expressions arithmétiques infixées sur les nombres entiers.

### Analyse lexicale
Source pour l'analyseur lexical (JFlex) : *[src/main/jflex/AnalyseurLexical.flex](src/main/jflex/AnalyseurLexical.flex)*

On reconnait les différents mots du langage (lexème) : 
- opérateurs arithmétiques : +, -, /, *
- les parenthèses ouvrantes et fermante : (, )
- les entiers : [0-9]+
- les espaces (espaces, tabulation, passage à la ligne) : \s
- le lexème indiquant la fin d'une expression : ;


### Analyse syntaxique
Source de l'analyseur syntaxique : *[src/main/cup/AnalyseurSyntaxique.cup](src/main/cup/AnalyseurSyntaxique.cup)*

Il s'agit de reconnaître la syntaxe (grammaire du langage).
Il travaille à partir des lexèmes (token) qui remontent de l'analyseur lexical. 
Tous les lexèmes doivent être déclarés comme des symboles terminaux.
```JFLEX
terminal PLUS, MOINS, MUL, DIV, PAR_G, PAR_D, SEMI, ENTIER, ERROR; 
```
Les règles de la grammaire décrivent le langage :
- on a une suite d'expressions (au moins une)
- chaque expression est terminée par un point-virgule (lexème SEMI)
- une expression est soit :
    - un entier (lexème ENTIER)
    - une expression arithmétique simple : expression_gauche opérateur expression_droite
    - une expression parenthèsée : ( expression )
```
// on a une liste d'expressions (avec au moins une expression)
liste_expr ::= expr liste_expr 
             | expr  
             ;
// chaque expression arithmetique est terminee par un point virgule (SEMI)
expr ::= expression SEMI
       | error SEMI
       ;
expression ::= ENTIER 
             | expression PLUS expression  
             | expression MOINS expression  
             | expression MUL expression 
             | expression DIV expression
             | PAR_G expression PAR_D   
             ;
```
Les règles du genre : `expression ::= expression PLUS expression` introduisent des ambiguïtés dans la grammaire 
(ce que n'aime pas l'analyseur). 
Il faut dont lever ces ambiguïtés, soit en réécrivant les règles (cf. exemple donné en cours pour les expressions arithmétique), 
soit précisant (comme le permet l'analyseur syntaxique) l'associativité et la priorité des opérateurs:
```
precedence left PLUS, MOINS;
precedence left MUL, DIV;
```
On liste les opérateurs du moins prioritaire au plus prioritaire.

### Evaluation des expressions
Pour l'évaluation des expressions, il faut aussi disposer des valeurs des entiers reconnus par l'analyseur lexical. 
Avec JFlex et CUP cela peut se faire en passant un paramètre supplémentaire lors de la remonté du lexème par l'analyseur lexical :
```JFLEX
{chiffre}+	{ return new Symbol(sym.ENTIER, new Integer(yytext())) ;}
```
Au niveau de CUP (analyseur syntaxique) on peut avoir une valeur associée à chacun des symboles (terminaux ou non terminaux). 
Le type de cette valeur doit être spécifié lors de la déclation du symbole : 
```
/* symboles terminaux */
terminal PLUS, MOINS, MUL, DIV, PAR_G, PAR_D, SEMI, ERROR; 
terminal Integer ENTIER;
/* non terminaux */
non terminal liste_expr, expr;
non terminal Integer expression ;
```
Dans notre cas, on aura un entier associé 
- au symbole terminal (lexème) `ENTIER` - il est défini par l'analyzeur lexical - 
- au symbole non terminal `expression`.

Pour calculer les valeur associées au symboles non terminaux, on ajoute des actions sémantique dans les règles (valeur associée à `RESULT`) : 
`expression ::= expression:e1 PLUS expression:e2 {: RESULT = e1+e2 ; :} `

On ajoute aussi une action semantique pour afficher la valeur finale de l'expression : 
`expr ::= expression:e SEMI {: System.out.println("val: "+e); :}`
```
/* grammaire */
// on a une liste d'expressions (avec au moins une expression)
liste_expr ::= expr liste_expr 
             | expr  
             ;
// chaque expression arithmetique est terminee par un point virgule (SEMI)
expr ::= expression:e SEMI   {: System.out.println("val: "+e); :}
       | error SEMI
       ;
expression ::= ENTIER:e                            {: RESULT = e ; :}
             | expression:e1 PLUS expression:e2    {: RESULT = e1+e2 ; :}
             | expression:e1 MOINS expression:e2   {: RESULT = e1-e2 ; :}
             | expression:e1 MUL expression:e2     {: RESULT = e1*e2 ; :}
             | expression:e1 DIV expression:e2     {: RESULT = e1/e2 ; :}
             | PAR_G expression:e PAR_D            {: RESULT = e ; :}
             ;
```

La règle `expr ::= error SEMI` permet de gérér les erreurs syntaxiques en définissant un point de reprise d'erreur 
après l'obtention d'un point virgule.

### Prise en compte du moins unaire
Le moins unaire pose un problème particulier du fait qu'on utilise le même toket que pour l'opérateur binaire moins.

On peut se résoudre en ajoutant ue règle de priorité spécifique : 
```
precedence left PLUS, MOINS;
precedence left MUL, DIV;
precedence left MOINS_UNAIRE;
```
On précise ensuite au niveau de la règle de réécriture la priorité à utitilser :
```
expression ::= ENTIER:e                            {: RESULT = e ; :}
             | expression:e1 PLUS expression:e2    {: RESULT = e1+e2 ; :}
             | expression:e1 MOINS expression:e2   {: RESULT = e1-e2 ; :}
             | MOINS expression:e                  {: RESULT = -e ; :}      %prec MOINS_UNAIRE
             ...
```

#### Gestion des erreurs d'évaluation (division par zéro)
Pour éviter que l'interpréteur s'arrête lors d'une erreur d'execution (division par zéro par exemple), 
on peut tester si la valeur est différente de zéro avant d'effectuer l'opération. 
Dans le cas contraire on suspend l'évaluation tant qu'on est pas arrivé à un point de reprise d'erreur (obtention d'un point virgule).

À cette fin on peut ajouter un booléen dans la partie `action code` : 
```
action code {: 
    // pour utilisation dans les actions (classe action)
	private boolean erreur = false;
:};
```
qu'on utilisera dans les actions sémantiques des règles de la grammaire : 
```
/* package et imports */
package fr.usmb.m1isc.compilation.tp1;
import java_cup.runtime.Symbol;

/* inclusion du code */

action code {: 
    // pour utilisation dans les actions (classe action)
	private boolean erreur = false;
:};

 
parser code {:
    // pour le parser (redefinition de la methode reportant les erreurs d'analyse)
:};

 init with {:
    //	initialisation du parser
:};

/* symboles terminaux */
terminal PLUS, MOINS, MOINS_UNAIRE, MUL, DIV, MOD, PAR_G, PAR_D, SEMI, ERROR; 
terminal Integer ENTIER;
/* non terminaux */
non terminal liste_expr, expr;
non terminal Integer expression ;

precedence left PLUS, MOINS;
precedence left MUL, DIV, MOD;
precedence left MOINS_UNAIRE;

/* grammaire */
// on a une liste d'expressions (avec au moins une expression)
liste_expr  ::= expr liste_expr 
              | expr  
              ;
// chaque expression arithmetique est terminee par un point virgule (SEMI)
expr 		::= expression:e SEMI   {: if (! erreur) System.out.println("val: "+e); erreur = false; :}
              | error SEMI          {: erreur = false; :}
              ;
expression 	::= ENTIER:e                            {: RESULT = e ; :}
              | expression:e1 PLUS expression:e2    {: RESULT = e1+e2 ; :}
              | expression:e1 MOINS expression:e2   {: RESULT = e1-e2 ; :}
              | MOINS expression:e                  {: RESULT = -e ; :} 	%prec MOINS_UNAIRE
              | expression:e1 MUL expression:e2     {: RESULT = e1*e2 ; :}
              | expression:e1 DIV expression:e2     {: if (erreur) { RESULT= 0; } 
                                                       else if (e2 == 0) { RESULT = 0; erreur=true; System.err.println("Erreur division par zero"); } 
                                                       else { RESULT = e1/e2; } :}
              | expression:e1 MOD expression:e2     {: if (erreur) { RESULT= 0; } 
                                                       else if (e2 == 0) { RESULT = 0; erreur=true; System.err.println("Erreur division par zero"); } 
                                                       else { RESULT = e1%e2; } :}
              | PAR_G expression:e PAR_D            {: RESULT = e ; :}
              ;
```

#### Utilisation du numéro de ligne et de colonne et réécriture des messages d'erreur.
Il est possible de demander à l'analyseur lexical (JFlex) de passer à l'analyseur syntaxique (CUP) 
le numéro de ligne et de colonne dans le lexème.
CUP les propage alors au niveau des règles de la grammaire, 
ce qui permet des les utiliser dans les actions sémantiques et les messages d'erreur.

__Passage numero de ligne et de colonne dans JFLEX :__
```JFLEX
/* ------------------------Section des Regles Lexicales----------------------*/
"("			{ return new Symbol(sym.PAR_G, yyline, yycolumn) ;}
")"			{ return new Symbol(sym.PAR_D, yyline, yycolumn) ;}
"+"			{ return new Symbol(sym.PLUS, yyline, yycolumn) ;}
...
```

__Utilisation dans CUP : ??left et ??right__
```
expr ::= expression:e SEMI   {: if (! erreur) System.out.println("Ligne : "+eval: "+e); erreur = false; :}
```
__Réécriture du message d'erreur par défaut : __

On peut aussi adapter la méthode utilisée pour rapporter les erreurs en redefinissant `report_error` :
```
```


