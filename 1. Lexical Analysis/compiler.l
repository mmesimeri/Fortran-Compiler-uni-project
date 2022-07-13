%{
#include "header.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <string.h>

int lineno = 1;       /* grammi programmatos */
int error_count = 0;  /* plithos sfalmatwn */
char str_buf[256];    /* gia apothikeush strings */

/* sinartisi gia errors */
void yyerror(const char* err);

void TPRINT(int token_id);
void NPRINT(int token_id, int base);
void FPRINT(int token_id, int base);

/* sinartiseis gia metatropes */
int dectoInt(char *str);
int hextoInt(char *str);
int bintoInt(char *str);
float bintoFloat(char* str);
float hextoFloat(char* str);
%}

/* anagnwrish 1 arxeiou mono th fora */
%option noyywrap

%option case-insensitive


/* states */
%x STRING
%x COMMENT

LETTER      [a-zA-Z]
DIGIT       [0-9]
BINDIGIT    [01]
CHARACTER   {LETTER}|{DIGIT}
HEXDIGIT    [0-9A-F]
NZNUMBER    [1-9]{DIGIT}*
DINAMI      E[+-]?(0|{NZNUMBER})
ID          ({LETTER}({DIGIT}|{LETTER})*)
ICONST      {NZNUMBER}
RCONST      ({NZNUMBER}\.{DIGIT}+) | ({DIGIT}+ \.? {NZNUMBER})
WHITESPACE  [ \t]
ASCII 	    [ !"#$%&'()*+,-./:;<=>?@\[\\\]^_`{|}~]
ALPHANUM    ({LETTER}|{DIGIT})

%%
"FUNCTION"         {TPRINT(T_FUNCTION); return T_FUNCTION;}

"SUBROUTINE"       {TPRINT(T_SUBROUTINE); return T_SUBROUTINE;}

"END"              {TPRINT(T_END); return T_END;}

"INTEGER"          {TPRINT(T_INTEGER); return T_INTEGER;}

"REAL"             {TPRINT(T_REAL); return T_REAL;}

"LOGICAL"          {TPRINT(T_LOGICAL); return T_LOGICAL;}

"CHARACTER"        {TPRINT(T_CHARACTER); return T_CHARACTER;}

"RECORD"           {TPRINT(T_RECORD); return T_RECORD;}

"ENDREC"           {TPRINT(T_ENDREC); return T_ENDREC;}

"DATA"             {TPRINT(T_DATA); return T_DATA;}

"CONTINUE"         {TPRINT(T_CONTINUE); return T_CONTINUE;}

"GOTO"             {TPRINT(T_GOTO); return T_GOTO;}

"CALL"             {TPRINT(T_CALL); return T_CALL;}

"READ"             {TPRINT(T_READ); return T_READ;}

"WRITE"            {TPRINT(T_WRITE); return T_WRITE;}

 "IF"              {TPRINT(T_IF); return T_IF;}

"THEN"             {TPRINT(T_THEN); return T_THEN;}

"ELSE"             {TPRINT(T_ELSE); return T_ELSE;}

"ENDIF"            {TPRINT(T_ENDIF); return T_ENDIF;}

"DO"               {TPRINT(T_DO); return T_DO;}

"ENDDO"            {TPRINT(T_ENDDO); return T_ENDDO;}

"STOP"             {TPRINT(T_STOP); return T_STOP;}

"RETURN"           {TPRINT(T_RETURN);  return T_RETURN;}

{ID}  		      	                            {TPRINT(T_ID); return	T_ID;}

0X[1-9A-F]{HEXDIGIT}* 				            {NPRINT(T_ICONST,16); return T_ICONST;}

0B1{BINDIGIT}*                                  {NPRINT(T_ICONST, 2); return T_ICONST;}

0|{NZNUMBER}                                    {NPRINT(T_ICONST, 10); return T_ICONST;}


0|[1-9]{DIGIT}*	                                {TPRINT(T_INTEGER); return	T_INTEGER;}

[1-9]{DIGIT}*[.]([1-9]{DIGIT}*|"0"+[1-9]{DIGIT}*)[Ee][+-]?([1-9]{DIGIT}*)      {FPRINT(T_RCONST,10); return T_RCONST;}
"0"?[.]([1-9]{DIGIT}*|"0"+[1-9]{DIGIT}*)[Ee][+-]?([1-9]{DIGIT}*)             {FPRINT(T_RCONST,10); return T_RCONST;}

0[x|X][1-9]+[A-F][a-f]+[.]([1-9]+[A-F][a-f]+)|([0]+[1-9]+[A-F][a-f]+)  {FPRINT(T_RCONST,16); return T_RCONST;}

0[b|B]1[01]*[.]("1"[01]*|"0"+[1][01]*)                                 {FPRINT(T_RCONST,2); return T_RCONST;}

".TRUE."				{TPRINT(T_LCONST); return T_LCONST;}
".FALSE."               {TPRINT(T_LCONST); return T_LCONST;}


\'\\n\'                  {TPRINT(T_CCONST); return	T_CCONST;}

\'\\f\'                  {TPRINT(T_CCONST);  return	T_CCONST;}

\'\\t\'                  {TPRINT(T_CCONST); return	T_CCONST;}

\'\\r\'                  {TPRINT(T_CCONST); return	T_CCONST;}

\'\\b\'                 {TPRINT(T_CCONST);  return	T_CCONST;}

\'\\v\'                 {TPRINT(T_CCONST);  return	T_CCONST;}




\'{ASCII}\'            {TPRINT(T_CCONST); return	T_CCONST;}

\'{ALPHANUM}\'         {TPRINT(T_CCONST);  return	T_CCONST;}



\"                                                 { strcpy(str_buf, ""); BEGIN(STRING); }     /* adeiasma pinaka 'str_buf' */
<STRING>\"                                         { printf("\nSCONST -> %s\n", str_buf); BEGIN(INITIAL); return T_SCONST; }
<STRING>\n                                         { yyerror("Line feed in string without \\"); }
<STRING>\\.|[^"\\]                                 { strcat(str_buf, yytext); }    /* Προσθέτουμε οποιονδήποτε δεκτό χαρακτήρα στον πίνακα χαρακτήρων 'str_buf' για εμφάνιση του τελικού string μετά το τέλος του */
<STRING>\\\n                                       {lineno++;}
<STRING><<EOF>>                                    { yyerror("EOF in string"); }
<STRING>.                                          { yyerror("Unknown character in string"); }
\n                                                 {lineno++;}

 ".OR."					    {TPRINT(T_OROP); return T_OROP;}
 ".ANDOP."				     {TPRINT(T_ANDOP); return T_ANDOP;}
".NOTOP."				     {TPRINT(T_NOTOP);  return T_NOTOP;}

".GT."|".GE."|".LT."|".LE."|".EQ."|".NE."    {TPRINT(T_RELOP); return T_RELOP;}

[+-]		             {TPRINT(T_ADDOP); return T_ADDOP;}

"*" 					 {TPRINT(T_MULOP); return T_MULOP;}

"/"					     {TPRINT(T_DIVOP); return T_DIVOP;}

"**"                     {TPRINT(T_POWEROP);  return T_POWEROP;}


"("					     {TPRINT(T_LPAREN);  return T_LPAREN;}
")"				         {TPRINT(T_RPAREN); return T_RPAREN;}
","                      {TPRINT(T_COMMA);   return T_COMMA;}
"="					     {TPRINT(T_ASSIGN);  return T_ASSIGN;}
":"				         {TPRINT(T_COLON);  return T_COLON;}
<<EOF>>                  {TPRINT(T_EOF); 	return T_EOF;}


%%
int main(int argc, char* argv[]) {

    int token;

   if(argc > 1){
        yyin = fopen(argv[1], "r");
        if (yyin == NULL){
            perror ("Error opening file"); return -1;
        }
    }

    do {
        token = yylex();
    } while (token != T_EOF);

if(error_count > 0){
        printf("Failed to analyze the program due to %d errors\n", error_count);
    }else{
        printf("Program analyzed successfully\n");
    }
    fclose(yyin);
    yyterminate();

    return 0;

}

/* sinartisi pou metra errors kai termatizei sta 5 errors*/
void yyerror(const char* err) {

    error_count++;

    printf("\n[ERROR - Line %d]: %s\n", yylineno, err);

    if (error_count == 5) {
        printf("\n Exiting...\n");
        exit(EXIT_FAILURE);
    }

}

int dectoInt(char *str){
    return atoi(str);
}

int hextoInt(char *str){
    return (int) strtol(&str[2], NULL, 16);
}

int bintoInt(char *str){
    return (int) strtol(&str[2], NULL, 2);
}

float bintoFloat(char* str){
    float number = 0.0;
    int i,length_real;
    char *character;
    character = strchr(str,'.');
    length_real = strlen(character)-1;
    number = (int)strtol(&str[2],&character,2);
    for(i=1;i<length_real;i++){
        number += (character[i] - '0') * (1/pow(2,i));
    }
    return number;
}

float hextoFloat(char*str){
    float number = 0.0;
    int i,length_real;
    char *character;
    character = strchr(str,'.');
    length_real = strlen(character)-1;
    number = (int)strtol(&str[2],&character,16);
    for(i=1;i<=length_real;i++){
        if(character[i] <= '9')
			number += (character[i] - '0') * (1/pow(16,i));
		else
			number += (character[i] + 10 - 'A') * (1/pow(16,i)); /** TODO: CASE SENSITIVE **/
	}
    return number;
}

void TPRINT(int token_id){
    if(FLEX_DEBUG && FLEX_SHOW_TOKENS){
        printf("TOKEN FOUND: %s | TOKEN NUMBER: %d | LINE: %d\n", yytext, token_id, lineno);
    }
}


    void NPRINT(int token_id, int base){
    if(FLEX_DEBUG && FLEX_SHOW_NUMERIC){
        int number;
        if(base == 2) number = bintoInt(yytext);
        else if(base == 16) number = hextoInt(yytext);
        else number = atoi(yytext);
        printf("NUMBER FOUND: %d (%s) | FROM BASE: %d | TOKEN NUMBER: %d | LINE: %d\n", number, yytext, base, token_id, lineno);
    }
}

void FPRINT(int token_id, int base){
    if(FLEX_DEBUG && FLEX_SHOW_NUMERIC){
        float number;
        if(base == 2) number = bintoFloat(yytext);
        else if(base == 16) number = hextoFloat(yytext);
        else number = atof(yytext);
        printf("FLOAT FOUND: %lf (%s) | FROM BASE: %d | TOKEN NUMBER: %d | LINE: %d\n", number, yytext, base, token_id, lineno);
    }
}
