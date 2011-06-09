#include <stdio.h>
#include <string>
#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <fstream>
#include <ctype.h>
#include <assert.h>
#include "Hashtable.h"
#include "Record.h"

#define NO_OF_KEYWORDS 33
#define NO_OF_FUNC 2
#define KEY 300

using namespace std;

extern int yyparse(void);
extern FILE *yyin;
extern char *yytext;
extern int yylex(void);
extern int yyleng;
extern int relval;
extern int arithmval;
extern int yywrap(void);

const char * keyword[] = {
	"ARRAY",
	"DOWNTO",
	"FUNCTION",
	"OF",
	"REPEAT",
	"UNTIL",
	"BEGIN",
	"ELSE",
	"GOTO",
	"PACKED",
	"SET",
	"VAR",
	"CASE",
	"END",
	"IF",
	"PROCEDURE",
	"THEN",
	"WHILE",
	"CONST",
	"FILE",
	"LABEL",
	"PROGRAM",
	"TO",
	"WITH",
	"DO",
	"FOR",
	"NIL",
	"RECORD",
	"TYPE",
	"INTEGER",
	"CHAR",
	"INPUT",
	"OUTPUT",
	//Default functions
	"WRITE",
	"READ"
};

//Global symbol table & Global number table.
Hashtable symtable;
Hashtable numtable;

//Added in semantics
Record * global;

void insert_keys() {
	// Installing keywords in symbol table
	for(int i=0; i<NO_OF_KEYWORDS; i++)
		//Check i/33 later
		global->table.addword(keyword[i],KEY,0);

	for(int i=NO_OF_KEYWORDS; i < NO_OF_KEYWORDS + NO_OF_FUNC; i++) {
		node * temp = global->table.addword(keyword[i], KEY, FUNC);
		cout << "inserting " << keyword[i] << endl;
		temp->arg_types[0]=INTEGER;
		temp->arg_size=1;
	}

	/*
	 * Assuming read takes one arg -an integer.
	 * This can be modified to allow for arbit no of arguments/types
	 * (will involve some more bookkeeping)
	 */
}

void free_records(Record * rec) {
	for(int i=0; i<rec->child.size(); i++) {
		free_records(rec->child[i]);
		delete rec->child[i];
	}
}

int main(int argc, char*argv[]) {
	if(argc!=2) {
		printf("Usage: %s <filename>\n",argv[0]);
		return 0;
	}

	yyin = fopen(argv[1],"r");

	global = new Record();
	insert_keys();

	cout << endl << "Beginning parsing." << endl;
	yyparse();
	cout << endl << "Parsing complete." << endl;

	freopen("symtable.out","w",stdout);

	cout << endl << "The symbol table is:" << endl;
	symtable.printtable();
	cout << endl << "The number table is:" << endl;
	numtable.printtable();
}