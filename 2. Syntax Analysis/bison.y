%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <string.h>
#include "settings.h"
#include "hashtbl.h"
#define MAX_PARSER_ERRORS 5

/** Extern from Flex **/
extern int lineno;
extern char str_buf[256];

extern int yylex();
extern char *yytext;
extern FILE *yyin;

 extern void yyterminate();

/** Bison specific variables **/
int scope=0;
int  error_count=0;
HASHTBL *hashtbl;
void yyerror(const char *message);
%}

%define parse.error verbose

%union{
    int intval;
    double doubleval;
    char *strval;
}

%token <intval> T_ICONST             "integer constant"
%token <doubleval> T_RCONST          "float constant"
%token <strval> T_FUNCTION           "FUNCTION"
%token <strval> T_SUBROUTINE         "SUBROUTINE"
%token <strval> T_END                "END"
%token <strval> T_INTEGER            "INTEGER"
%token <strval> T_REAL               "REAL"
%token <strval> T_LOGICAL            "LOGICAL"
%token <strval> T_CHARACTER          "CHARACTER"
%token <strval> T_RECORD             "RECORD"
%token <strval> T_ENDREC             "ENDREC"
%token <strval> T_DATA               "DATA"
%token <strval> T_CONTINUE           "CONTINUE"
%token <strval> T_GOTO               "GOTO"
%token <strval> T_CALL               "CALL"
%token <strval> T_READ               "READ"
%token <strval> T_WRITE              "WRITE"
%token <strval> T_IF                 "IF"
%token <strval> T_THEN               "THEN"
%token <strval> T_ELSE               "ELSE"
%token <strval> T_ENDIF              "ENDIF"
%token <strval> T_DO                 "DO"
%token <strval> T_ENDDO              "ENDDO"
%token <strval> T_STOP               "STOP"
%token <strval> T_RETURN             "RETURN"
%token <strval> T_STRING              "STRING"
%token <strval> T_CCONST              "CCONST"
%token <strval> T_ID                 "id"
%token <strval> T_OROP               ".OR."
%token <strval> T_ANDOP              ".ANDOP."
%token <strval> T_NOTOP              ".NOTOP."
%token <strval> T_ADDOP              "+ or -"
%token <strval> T_MULOP              "*"
%token <strval> T_DIVOP              "/"
%token <strval> T_RELOP              ".GT. or .GE. or .LT.  or .LE. or .EQ. or .NE."
%token <strval> T_POWEROP            "**"
%token <strval> T_LCONST             ".TRUE. or .FALSE."
%token <strval> T_LPAREN             "("
%token <strval> T_RPAREN             ")"
%token <strval> T_COMMA              ","
%token <strval> T_COLON              ":"
%token <strval> T_ASSIGN             "="
%token <strval> T_EOF              "end of file"

/*
%type <strval> program body declarations type vars undef_variable dims dim fields field
%type <strval> vals value_list values value repeat constant statements  labeled_statement
%type <strval> label statement simple_statement assignment variable expressions expression
%type <strval> goto_statement labels if_statement subroutine_call io_statement read_list read_item
%type <strval> iter_space step write_list write_item compound_statement branch_statement tail
%type <strval> loop_statement subprograms subprogram header formal_parameters
*/

%right T_ASSIGN
%left T_OROP
%left T_ANDOP
%nonassoc T_NOTOP
%nonassoc T_RELOP
%left T_ADDOP
%left T_DIVOP T_MULOP
%right T_POWEROP
%left T_LPAREN T_RPAREN T_COLLON

%nonassoc T_ELSE

%start program

%%

program : {scope++;} body T_END {scope--;} subprograms
          ;

body : declarations statements
        ;

declarations :     declarations type vars
                   | declarations T_RECORD fields T_ENDREC vars
                   | declarations T_DATA vals
                   | %empty	{ }
                    ;

type :              T_INTEGER
                    | T_REAL
					| T_LOGICAL
					| T_CHARACTER
                     ;

vars :              vars T_COMMA undef_variable
                   | undef_variable
                    ;

undef_variable :   T_ID T_LPAREN
                    dims T_RPAREN    {hashtbl_insert(hashtbl, $1, NULL, scope);}
                   | T_ID            {hashtbl_insert(hashtbl, $1, NULL, scope);}
                    ;

dims :            dims T_COMMA dim    {hashtbl_get(hashtbl, scope);}
                  | dim
                    ;

dim :             T_ICONST
                  | T_ID           {hashtbl_insert(hashtbl, $1, NULL, scope);}
                    ;

fields :          fields field
                  | field
                   ;

field :          type vars
                 | T_RECORD fields T_ENDREC vars
                  ;

vals :           vals T_COMMA T_ID value_list      {hashtbl_insert(hashtbl, $3, NULL, scope);}
                 | T_ID value_list                 {hashtbl_insert(hashtbl, $1, NULL, scope);}
                  ;

value_list :        T_DIVOP values T_DIVOP
                     ;

values :           values T_COMMA value          {hashtbl_get(hashtbl, scope);}
                   | value
                     ;

value :      repeat T_MULOP T_ADDOP constant
             | repeat T_MULOP constant
             | repeat T_MULOP T_STRING
             | T_ADDOP constant
             | constant
             | T_STRING
              ;

repeat :   T_ICONST
           | %empty { }
         ;
constant : T_ICONST
           | T_RCONST
		   | T_LCONST
		   | T_CCONST
            ;

statements : statements labeled_statement
             | labeled_statement
			 ;

labeled_statement:   label statement
                     | statement
					 ;
label:                T_ICONST
                    ;

statement:           simple_statement
                    | compound_statement
					;

simple_statement:    assignment
                    | goto_statement
                    | if_statement
                    | subroutine_call
                    | io_statement
                    | T_CONTINUE
                    | T_RETURN
                    | T_STOP
					;

assignment:          variable T_ASSIGN expression
                     | variable T_ASSIGN T_STRING
					 ;

variable:             variable T_COLON T_ID        {hashtbl_insert(hashtbl, $3, NULL, scope);}
                     | variable T_LPAREN
                      expressions T_RPAREN
                     | T_ID                        {hashtbl_insert(hashtbl, $1, NULL, scope);}
					 ;

expressions:          expressions T_COMMA expression
                      | expression
					  ;

expression:          expression T_OROP expression
                     | expression T_ANDOP expression
                     | expression T_RELOP expression
                     | expression T_ADDOP expression
                     | expression T_MULOP expression
                     | expression T_DIVOP expression
                     | expression T_POWEROP expression
                     | T_NOTOP expression
                     | T_ADDOP expression
                     | variable
                     | constant
                     | T_LPAREN
                       expression T_RPAREN
					 ;

goto_statement:      T_GOTO label
                     | T_GOTO T_ID T_COMMA T_LPAREN labels T_RPAREN                {hashtbl_insert(hashtbl, $2, NULL, scope);}
					 ;

labels:             labels T_COMMA label
                    | label
					;

if_statement:      T_IF T_LPAREN expression T_RPAREN  label T_COMMA label T_COMMA label {scope++;}
                   | T_IF T_LPAREN  expression T_RPAREN   simple_statement  {scope++;}
				   | T_IF  T_LPAREN  expression error   simple_statement   {scope++;} {yyerrok;}
				   ;

subroutine_call:    T_CALL variable
                    ;

io_statement:       T_READ read_list
                    | T_WRITE write_list
					;

read_list:           read_list T_COMMA read_item
                     | read_item
					 ;

read_item:            variable
                     | T_LPAREN
                     read_list T_COMMA T_ID T_ASSIGN iter_space T_RPAREN    {hashtbl_insert(hashtbl, $4, NULL, scope);}
					 ;

iter_space :        expression T_COMMA expression step
                      ;

step :               T_COMMA expression
                    | %empty  { }
                     ;

write_list :         write_list T_COMMA write_item
                     | write_item
                      ;

write_item :         expression
                     | T_LPAREN
                     write_list T_COMMA T_ID T_ASSIGN iter_space T_RPAREN         {hashtbl_insert(hashtbl, $4, NULL, scope);}
                     | T_STRING
                     ;

compound_statement : branch_statement
                    | loop_statement
                     ;

branch_statement :   T_IF
                      T_LPAREN  expression T_RPAREN  T_THEN  {hashtbl_get(hashtbl, scope);}
                      body tail
                     |T_IF
                      T_LPAREN  expression T_RPAREN  error body tail  {yyerrok;}
                      ;

tail :           T_ELSE {scope++;} body T_ENDIF {hashtbl_get(hashtbl, scope);scope--;}
                  | T_ENDIF {hashtbl_get(hashtbl, scope);scope--;}
                   ;

loop_statement :  T_DO {scope++;} T_ID T_ASSIGN iter_space body T_ENDDO     {hashtbl_insert(hashtbl, $3, NULL, scope);hashtbl_get(hashtbl, scope);scope--;}
                  ;

subprograms :     subprograms subprogram
                  | %empty	{ }
                  ;

subprogram :      header body T_END
                   ;

header :         type T_FUNCTION T_ID T_LPAREN formal_parameters T_RPAREN      {hashtbl_insert(hashtbl, $3, NULL, scope);}
                 | T_SUBROUTINE  T_ID T_LPAREN formal_parameters T_RPAREN       {hashtbl_insert(hashtbl, $2, NULL, scope);}
                 | T_SUBROUTINE  T_ID                                           {hashtbl_insert(hashtbl, $2, NULL, scope);}
                  ;

formal_parameters :  type vars T_COMMA formal_parameters
                     | type vars
                     ;

%%

int main(int argc, char* argv[] ){

   if(!(hashtbl = hashtbl_create(10, NULL))) {
        fprintf(stderr, "ERROR: hashtbl_create() failed!\n");
        exit(EXIT_FAILURE);
    }

    if(argc > 1){
        yyin = fopen(argv[1], "r");
        if (yyin == NULL){
            perror ("Error opening file");
            return -1;
        }
    }

    yyparse();

    hashtbl_get(hashtbl, scope); // Retrieve the last table (Scope 0);
    hashtbl_destroy(hashtbl);
    fclose(yyin);


    if(error_count > 0){
        printf("Syntax Analysis failed due to %d errors\n", error_count);
    }else{
        printf("Syntax Analysis completed successfully.\n");
    }
 return 0;

}


void yyerror(const char *message)
{
    error_count++;

	printf("\n[LINE %d] %s",lineno,message);

	if(error_count == MAX_PARSER_ERRORS){
	printf("\n Max parser error limit reached (%d)\n",MAX_PARSER_ERRORS);
	exit(EXIT_FAILURE);}
}