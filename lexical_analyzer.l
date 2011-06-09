%{
	#include<ctype.h>
	#include "y.tab.h"
	#include "Hashtable.h"

	int relval,arithmval;
	int cnt=1;

	extern Hashtable symtable;
	extern Hashtable numtable;

%}

whites [ \t]
newlines  [\n]
comments "{"[^{}]*"}"
number [0-9]+("."[0-9]+)?(E[+-]?[0-9]+)?  
identifier [a-zA-Z_][_a-zA-Z0-9]*


%%
{newlines}  ++cnt;
{whites}  ; //ignore whitespace
{comments} ; //ignore comments

array { return T_ARRAY;}
downto {return T_DOWNTO;}
function {return T_FUNCTION;}
of {return T_OF;}
repeat {return T_REPEAT;}
until {return T_UNTIL;}
begin {return T_BEGIN;}
else {return T_ELSE;}
goto {return T_GOTO;}
packed {return T_PACKED;}
set {return T_SET;}
var {return T_VAR;}
case {return T_CASE;}
end {return T_END;}
if {return T_IF;}
procedure {return T_PROCEDURE;}
then {return T_THEN;}
while {return T_WHILE;}
const {return T_CONST;}
file {return T_FILE;}
label {return T_LABEL;}
program {return T_PROGRAM;}
to {return T_TO;}
with {return T_WITH;}
do {return T_DO;}
for {return T_FOR;}
nil {return T_NIL;}
record {return T_RECORD;}
type {return T_TYPE;}
not {return T_NOT;}

char {return T_CHAR;}
integer {return T_INTEGER;}
real {return T_REAL;}

"<>" {relval = NE; return RELOP;}
"<=" {relval = LE; return RELOP;}
"<" {relval = LT; return RELOP;}
">=" {relval = GE; return RELOP;}
">" {relval = GT; return RELOP;}
"=" {relval = EQ; return RELOP;}

mod {arithmval = MOD; return MOD;}
"+" {arithmval = PLUS; return PLUS;}
"-" {arithmval = MINUS; return MINUS;}
"/" {arithmval = DIV; return DIV;}
"*" {arithmval = MUL; return MUL;}
":=" {return ASSGNOP;}

{number}	{
	if(!numtable.ispresent(yytext))
		numtable.addword(yytext,NUM);
	return NUM;
}

{identifier} {return ID;}
. {return *yytext;}

%%
//earlier : ("."|"/"|";"|":"|"("|")"|"["|"]"|"'"|",")  {return SP_CHAR;}
