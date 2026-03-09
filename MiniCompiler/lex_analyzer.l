/* This file is divided into 3 main sections:
    1. Definition section   (%{  %})
    2. Rules section        (between %% %%)
    3. User code section    (after second %%) */

%option noyywrap Normally,  // Flex calls a function yywrap() when it reaches end of input.
                            // By using this option, you tell Flex:
                            // “Don’t call yywrap(), just stop lexing at EOF.”
                            // Reason: You don’t need to define yywrap() yourself.

%{      // Definition section starts here.

#include"symbol_info.h"         // Includes your symbol_info class.
                                // This class is used to store token information (like identifier name, type, array size, etc.).
                                
#define YYSTYPE symbol_info*    // YYSTYPE defines the data type of the semantic value of a token. YYSTYPE tells the parser what type of data a token carries.
                                // Here, you tell the parser: Each token will pass a pointer to symbol_info as its semantic value.

#include "y.tab.h"

extern YYSTYPE yylval;          // yylval is the variable used to pass semantic values from lexer to parser.

void yyerror(char *);           // yyerror() is a function used by the parser to report syntax errors.
                                // When the parser finds something that does not match the grammar rules, it calls this function.
                                //          void → function returns nothing
                                //          yyerror → name of the error handling function
                                //          char * → receives an error message string

extern int lines;               // Keeps track of current line number while scanning.

%}     // Definition section ends here.

delim	 [ \t\v\r\f]                        // This defines delimiter characters.space, tab, vertical tab, carriage return, form feed.
newline  \r?\n                              // newline, carriage return
ws		 {delim}+                           // This means one or more whitespace characters.
letter_	 [A-Za-z_]                          // This defines a letter or underscore, which can be the first character of an identifier.
digit	 [0-9]                              // This defines a digit, which can be part of an identifier or a number.        
id		 {letter_}({letter_}|{digit})*      // This defines an identifier: starts with a letter or underscore, followed by zero or more letters, digits, or underscores.
integers {digit}+                           // Matches integer numbers.
floats	 {digit}*(\.{digit}+)|{digit}*(\.{digit}+)?((E|e)[-]?{digit}+)  // This matches floating-point numbers.
 

%%

// This section is the Rules part of your Flex lexer. Each rule has the form:  pattern    { action }
// Meaning: When the lexer finds a pattern, it executes the action.

{ws}		{ /* ignore whitespace */ }
{newline}	{ lines++; }

if          { return IF; }          // When the lexer reads the word if, it returns the token IF to the parser, identifying it as a keyword.
else		{ return ELSE; }
for         { return FOR; }
while       { return WHILE; }
do          { return DO; }
break       { return BREAK; }
continue    { return CONTINUE; }
return      { return RETURN; }
int         { return INT; }
float       { return FLOAT; }
char        { return CHAR; }
void        { return VOID; }
double      { return DOUBLE; }
switch      { return SWITCH; }
case        { return CASE; }
default     { return DEFAULT; }
printf      { return PRINTLN; }


// When the lexer matches + or -, it creates a symbol_info object for the operator, stores it in yylval, and returns the token ADDOP to the parser.
"+"|"-"	    {
                symbol_info *s = new symbol_info((string)yytext,"ADDOP");
                yylval = (YYSTYPE)s;
                return ADDOP;
		    }
"*"|"/"|"%"    {
                symbol_info *s = new symbol_info((string)yytext,"MULOP");
                yylval = (YYSTYPE)s;
                return MULOP;
            }
"++"        { return INCOP; }
"--"        { return DECOP; }
"<"|">"|"<="|">="|"=="|"!=" {
                symbol_info *s = new symbol_info((string)yytext,"RELOP");
                yylval = (YYSTYPE)s;
                return RELOP;
            }

"="         { return ASSIGNOP; }
"&&"|"||"   {
		   	symbol_info *s = new symbol_info((string)yytext,"LOGICOP");
			yylval = (YYSTYPE)s;
			return LOGICOP;
		    }

"!"        { return NOT; }
"("        { return LPAREN; }
")"        { return RPAREN; }
"{"        { return LCURL; }
"}"        { return RCURL; }
"["        { return LTHIRD; }
"]"        { return RTHIRD; }
";"        { return SEMICOLON; }
","        { return COMMA; }

{id}       {
                symbol_info *s = new symbol_info((string)yytext,"ID");
                yylval = (YYSTYPE)s;
                return ID;
            }
{integers} {
                symbol_info *s = new symbol_info((string)yytext,"INT");
                yylval = (YYSTYPE)s;
                return CONST_INT;
            }
{floats}   {
                symbol_info *s = new symbol_info((string)yytext,"FLOAT");
                yylval = (YYSTYPE)s;
                return CONST_FLOAT;
            }
