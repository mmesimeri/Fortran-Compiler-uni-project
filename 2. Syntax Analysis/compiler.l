%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <string.h>
#include "settings.h"
#include "bison.tab.h"

/** Extern from Bison **/
extern int flag_err_type;
extern void yyerror(char *err);

/* grammi programmatos */
int lineno = 1;
int line_init=-1;

/* plithos sfalmatwn */

/* gia apothikeush strings */
char str_buf[256];
/* buffer gia ta strings */
char line[1000] = "";

char* str_buf_ptr;

void TPRINT(int token_id);
void NPRINT(int token_id, int base);
void FPRINT(int token_id, int base);

/* sinartiseis gia metatropes */
int dectoInt(char *str);
int hextoInt(char *str);
int bintoInt(char *str);
float BinToFloat(char* str);
float HexToFloat(char* str);
%}

%option case-insensitive

/* anagnwrish 1 arxeiou mono th fora */
%option noyywrap

/* states */
%x STRING
%x COMMENT
%x STATE_STRING

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
"FUNCTION"         {TPRINT(T_FUNCTION); yylval.strval = strdup(yytext); return T_FUNCTION;}

"SUBROUTINE"       {TPRINT(T_SUBROUTINE); yylval.strval = strdup(yytext); return T_SUBROUTINE;}

"END"              {TPRINT(T_END); yylval.strval = strdup(yytext); return T_END;}

"INTEGER"          {TPRINT(T_INTEGER); yylval.strval = strdup(yytext); return T_INTEGER;}

"REAL"             {TPRINT(T_REAL); yylval.strval = strdup(yytext); return T_REAL;}

"LOGICAL"          {TPRINT(T_LOGICAL); yylval.strval = strdup(yytext); return T_LOGICAL;}

"CHARACTER"        {TPRINT(T_CHARACTER); yylval.strval = strdup(yytext); return T_CHARACTER;}

"RECORD"           {TPRINT(T_RECORD); yylval.strval = strdup(yytext); return T_RECORD;}

"ENDREC"           {TPRINT(T_ENDREC); yylval.strval = strdup(yytext); return T_ENDREC;}

"DATA"             {TPRINT(T_DATA); yylval.strval = strdup(yytext); return T_DATA;}

"CONTINUE"         {TPRINT(T_CONTINUE); yylval.strval = strdup(yytext); return T_CONTINUE;}

"GOTO"             {TPRINT(T_GOTO); yylval.strval = strdup(yytext); return T_GOTO;}

"CALL"             {TPRINT(T_CALL); yylval.strval = strdup(yytext); return T_CALL;}

"READ"             {TPRINT(T_READ); yylval.strval = strdup(yytext); return T_READ;}

"WRITE"            {TPRINT(T_WRITE); yylval.strval = strdup(yytext); return T_WRITE;}

 "IF"              {TPRINT(T_IF); yylval.strval = strdup(yytext); return T_IF;}

"THEN"             {TPRINT(T_THEN); yylval.strval = strdup(yytext); return T_THEN;}

"ELSE"             {TPRINT(T_ELSE); yylval.strval = strdup(yytext); return T_ELSE;}

"ENDIF"           {TPRINT(T_ENDIF); yylval.strval = strdup(yytext); return T_ENDIF;}

"DO"               {TPRINT(T_DO); yylval.strval = strdup(yytext); return T_DO;}

"ENDDO"            {TPRINT(T_ENDDO); yylval.strval = strdup(yytext); return T_ENDDO;}

"STOP"            {TPRINT(T_STOP); yylval.strval = strdup(yytext); return T_STOP;}

"RETURN"           {TPRINT(T_RETURN); yylval.strval = strdup(yytext); return T_RETURN;}


{ID}  		      	                            {TPRINT(T_ID); yylval.strval = strdup(yytext); return	T_ID;}

0X[1-9A-F]{HEXDIGIT}* 				            {NPRINT(T_ICONST,16); yylval.intval = hextoInt(yytext); return T_ICONST;}

0B1{BINDIGIT}*                                  {NPRINT(T_ICONST, 2); yylval.intval = bintoInt(yytext); return T_ICONST;}

0|{NZNUMBER}                                    {NPRINT(T_ICONST, 10); yylval.intval =atoi(yytext); return T_ICONST;}


0|[1-9]{DIGIT}*	                                {TPRINT(T_INTEGER); yylval.strval = strdup(yytext); return	T_INTEGER;}

[1-9]{DIGIT}*[.]([1-9]{DIGIT}*|"0"+[1-9]{DIGIT}*)[Ee][+-]?([1-9]{DIGIT}*)      {FPRINT(T_RCONST,10); yylval.intval =atof(yytext); return T_RCONST;}
"0"?[.]([1-9]{DIGIT}*|"0"+[1-9]{DIGIT}*)[Ee][+-]?([1-9]{DIGIT}*)             {FPRINT(T_RCONST,10); yylval.intval =atof(yytext); return T_RCONST;}

0[x|X][1-9]+[A-F][a-f]+[.]([1-9]+[A-F][a-f]+)|([0]+[1-9]+[A-F][a-f]+)  {FPRINT(T_RCONST,16); yylval.intval =HexToFloat(yytext); return T_RCONST;}

0[b|B]1[01]*[.]("1"[01]*|"0"+[1][01]*)                                 {FPRINT(T_RCONST,2); yylval.intval =BinToFloat(yytext); return T_RCONST;}

".TRUE."					                    {TPRINT(T_LCONST); yylval.strval = strdup(yytext);return T_LCONST;}
".FALSE."                                       {TPRINT(T_LCONST); yylval.strval = strdup(yytext); return T_LCONST;}



\'\\n\'                                         {TPRINT(T_CCONST); yylval.strval = strdup(yytext); return	T_CCONST;}

\'\\f\'                                         {TPRINT(T_CCONST); yylval.strval = strdup(yytext); return	T_CCONST;}

\'\\t\'                                         {TPRINT(T_CCONST); yylval.strval = strdup(yytext); return	T_CCONST;}

\'\\r\'                                                   {TPRINT(T_CCONST); yylval.strval = strdup(yytext); return	T_CCONST;}

\'\\b\'                                                   {TPRINT(T_CCONST); yylval.strval = strdup(yytext); return	T_CCONST;}

\'\\v\'                                                  {TPRINT(T_CCONST); yylval.strval = strdup(yytext); return	T_CCONST;}





\'{ASCII}\'                                             {TPRINT(T_CCONST); yylval.strval = strdup(yytext); return	T_CCONST;}

\'{ALPHANUM}\'                                          {TPRINT(T_CCONST); yylval.strval = strdup(yytext); return	T_CCONST;}



\"                                                 { strcpy(str_buf, ""); BEGIN(STRING); }     /* adeiasma pinaka 'str_buf' */
<STRING>\"                                         {BEGIN(STATE_STRING); str_buf_ptr = str_buf;}
<STATE_STRING>\"                                        {BEGIN(INITIAL); *str_buf_ptr = '\0';
                                                            yylval.strval = strdup(str_buf);
                                                            if(FLEX_DEBUG && FLEX_SHOW_STRINGS)
                                                                printf("STRING FOUND: %s | TOKEN NUMBER: %d | LINE: %d\n", str_buf, T_LCONST, lineno);
                                                            return T_LCONST;}
<STRING>\n                                         { yyerror("Line feed in string without \\"); }
<STRING>(\\.|[^"\\])                               { strcat(str_buf, yytext); }    /* Προσθέτουμε οποιονδήποτε δεκτό χαρακτήρα στον πίνακα χαρακτήρων 'str_buf' για εμφάνιση του τελικού string μετά το τέλος του */
<STRING>\\\n                                       {lineno++;}
<STRING><<EOF>>                                    { yyerror("EOF in string"); }
<STRING>.                                          { yyerror("Unknown character in string"); }
\n                                                 {lineno++;}

 ".OR."					    {TPRINT(T_OROP); yylval.strval = strdup(yytext); return T_OROP;}

 ".ANDOP."				     {TPRINT(T_ANDOP); yylval.strval = strdup(yytext); return T_ANDOP;}

".NOTOP."				     {TPRINT(T_NOTOP); yylval.strval = strdup(yytext); return T_NOTOP;}

".GT."|".GE."|".LT."|".LE."|".EQ."|".NE."    {TPRINT(T_RELOP); yylval.strval = strdup(yytext); return T_RELOP;}

[+-]		                             {TPRINT(T_ADDOP); yylval.strval = strdup(yytext); return T_ADDOP;}

"*" 					     {TPRINT(T_MULOP); yylval.strval = strdup(yytext); return T_MULOP;}

"/"					     {TPRINT(T_DIVOP); yylval.strval = strdup(yytext); return T_DIVOP;}

"**"                                         {TPRINT(T_POWEROP); yylval.strval = strdup(yytext); return T_POWEROP;}


"("					     {TPRINT(T_LPAREN); yylval.strval = strdup(yytext); return T_LPAREN;}
")"				            {TPRINT(T_RPAREN); yylval.strval = strdup(yytext); return T_RPAREN;}
","                                          {TPRINT(T_COMMA); yylval.strval = strdup(yytext);  return T_COMMA;}
"="					     {TPRINT(T_ASSIGN); yylval.strval = strdup(yytext); return T_ASSIGN;}
":"				             {TPRINT(T_COLON); yylval.strval = strdup(yytext);  return T_COLON;}
<<EOF>>                                    {TPRINT(T_EOF); yylval.strval = strdup(yytext);	return T_EOF;}


%%


int dectoInt(char *str){
    return atoi(str);
}

int hextoInt(char *str){
    int res;
    res = (int)strtol(&str[2], NULL, 16);
    return res;
}
int bintoInt(char *str){
    return (int) strtol(&str[2], NULL, 2);
}

float BinToFloat(char* str){
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

float HexToFloat(char*str){
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
        if(base == 2) number = BinToFloat(yytext);
        else if(base == 16) number = HexToFloat(yytext);
        else number = atof(yytext);
        printf("FLOAT FOUND: %lf (%s) | FROM BASE: %d | TOKEN NUMBER: %d | LINE: %d\n", number, yytext, base, token_id, lineno);
    }
}