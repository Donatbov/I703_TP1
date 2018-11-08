/* --------------------------Section de Code Utilisateur---------------------*/
package fr.usmb.m1isc.compilation.tp1;
import java_cup.runtime.Symbol;

%%

/* -----------------Section des Declarations et Options----------------------*/
// nom de la class a generer
%class LexicalAnalyzer
%unicode
%line   // numerotation des lignes
%column // numerotation caracteres par ligne

// utilisation avec CUP 
%cup

// code a ajouter dans la classe produite
%{

%}

/* definitions regulieres */

chiffre 	= [0-9]
espace 		= \s
let			= "let"|"LET"
// un identifiant commence par une lettre suivit d'un charactere alphanumerique (lettre/chiffre/underscore)
ident		= [:letter:]\w*
comment1	= "//".*							// commentaire uniligne
comment2	= "/*"([^*]|("*"+[^/*]))*"*"+"/"	// commentaire multiligne
comment	= {comment1}|{comment2}	

%% 
/* ------------------------Section des Regles Lexicales----------------------*/

/* regles */

{let}		{ return new Symbol(sym.LET) ;}
"="			{ return new Symbol(sym.EGAL) ;}
"("			{ return new Symbol(sym.PAR_G) ;}
")"			{ return new Symbol(sym.PAR_D) ;}
"+"			{ return new Symbol(sym.PLUS) ;}
"-"			{ return new Symbol(sym.MOINS) ;}
"/"			{ return new Symbol(sym.DIV) ;}
"*"			{ return new Symbol(sym.MUL) ;}
";"			{ return new Symbol(sym.SEMI) ;}
{chiffre}+	{ return new Symbol(sym.ENTIER, new Integer(yytext())) ;}
{ident}		{ return new Symbol(sym.IDENT, yytext()) ;}
{comment}	{ /*commentaire : pas d'action*/ }
{espace} 	{ /*espace : pas d'action*/ }
.			{ return new Symbol(sym.ERROR) ;}