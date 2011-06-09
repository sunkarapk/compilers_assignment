%{
	//Declarations
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	#include <vector>
	#include <assert.h>
	#include <stack>

	#include "Hashtable.h"
	#include "Record.h"
	
	using namespace std;

	extern int yylex(void);
	void yyerror(const char *str);
	int yywrap();
	void print_err(const char * str,int line);
	void type_mismatch_err(int line);
	int chk_num_type(const char * str);
	node * find_var(string str,Record * rec);
	void print_global();
	void type_to_str(int type, string &str);
		
	extern int cnt;
	extern char * yytext;
	extern int yyleng;
	
	//Symbol Table
	extern Hashtable symtable;
	extern Hashtable numtable;

	int prev_err_line=0;
	char prev_err[30]="";

	//Used for converting keys to upper case
	char str[30];

	//This part is added for semantic analysis
	
	//Declaration part
	bool dec_var = false;
	bool dec_program = false;
	bool dec_proc=false;
	bool dec_func = false;
	//Record for the outermost level (program)
	extern Record* global;
	//To keep track of current symbol table record
	Record * cur_record;
	node * fn_ptr = NULL;
	vector <node*> var_list;
	node * last_node;

	/*
	 * Global variables added to assist in type checking
	 * (types are represented using the corresponding integers as defined in the enum in node.h)
	 */
	int var_type;
	bool array_type=false;
	int exp_type;
	int term_type;
	int factor_type;
	int variable_type;
	int sim_exp_type;
	//Used for error messages
	string var_name;
	
	//For checking args passed to function calls
	vector<int> arg_types;
	stack<node*> fn_ptrs;
%}

%token T_ARRAY T_DOWNTO T_FUNCTION T_OF T_REPEAT T_UNTIL T_BEGIN T_ELSE T_GOTO T_PACKED T_SET T_VAR T_CASE T_END T_IF T_PROCEDURE T_THEN T_WHILE T_CONST T_FILE T_LABEL T_PROGRAM T_TO T_WITH T_DO T_FOR T_NIL T_RECORD T_TYPE T_CHAR T_INTEGER T_REAL T_NOT RELOP ASSGNOP PLUS MINUS MUL DIV NUM ID SP_CHAR ARITHMOP
%token NE LE LT GE GT EQ MOD 
 
%%
program: 	{cur_record = global; cur_record->name ="PROGRAM";} 
		t_program {dec_program=true;}
		id {dec_program=false;}
		open_paran identifier_list close_paran semicolon {dec_var=true;}
		declarations {dec_var = false;}
		subprograms_declarations 
		compound_statement 
		dot
		;
		
identifier_list:	id
			| identifier_list comma id
			;

declarations: /*empty*/
		| declarations T_VAR {var_list.clear();array_type=false;}
		identifier_list colon
		type {
				for(int i=0;i<var_list.size();i++) {
					var_list[i]->id_type=var_type;
					var_list[i]->array_type = array_type;
				}
				array_type = false;
		}
		semicolon
		| declarations error semicolon {print_err("keyword 'var' missing.",cnt); yyerrok;}
		;
	
type:	standard_type
	| T_ARRAY open_square num dot dot num close_square T_OF standard_type {array_type=true;}
	| error {printf("line %d: Invalid Type - %s\n",cnt,yytext); yyerrok;}
	;
		
standard_type: 	T_INTEGER {var_type = INTEGER;}
			| T_REAL {var_type = FLOAT;}
			;
				
subprograms_declarations: 	subprograms_declarations subprograms_declaration semicolon
					| /*empty*/
					;
			
subprograms_declaration: 	subprogram_head {dec_var=true;}
					declarations {dec_var = false;}
					subprograms_declarations
					compound_statement {cur_record = cur_record->parent; fn_ptr=NULL;}
					;
			
subprogram_head:	T_FUNCTION {dec_func = true;}
				id {
					Record * org = cur_record;
					cur_record = new Record();
					org->child.push_back(cur_record);
					cur_record->parent = org;

					for(int i=0;i<yyleng;i++)
						*(str+i) = toupper(yytext[i]);
					*(str+yyleng)='\0';

					cur_record->name = str;
					org->table.addword(str,ID,FUNC);
					//Adding type info
					node * temp = org->table.ispresent(str);
					//Assert(temp);
					if(temp)
						temp->id_type=FUNC;
					//In order to make arg type checks
					fn_ptr=temp;
					dec_func=false; 
				}
				arguments colon
				standard_type {
					node * temp = cur_record->table.ispresent(cur_record->name);
					if(temp!=NULL)
						temp->id_type = var_type;
					fn_ptr->set_ret_type(var_type);
 				}
				semicolon
				| T_PROCEDURE {dec_proc =true;}
				id {
					Record * org = cur_record;
					cur_record = new Record();
					org->child.push_back(cur_record);
					cur_record->parent = org;

					for(int i=0;i<yyleng;i++)
						*(str+i) = toupper(yytext[i]);
					*(str+yyleng)='\0';

					cur_record->name = str;
					//Adding type info
					node * temp = org->table.ispresent(str);
					temp->id_type=PROC;
					//In order to make arg type checks
					fn_ptr=temp;
					dec_proc=false;
				} 
				arguments	semicolon
				;
		
arguments:	open_paran { dec_var=true;} parameter_list {dec_var=false;} close_paran
		;
		
parameter_list: 	{var_list.clear();array_type=false;}
			identifier_list colon
			type {
				for(int i=0;i<var_list.size();i++) {
					var_list[i]->id_type=var_type;
					var_list[i]->array_type = array_type;
					assert(fn_ptr!=NULL);
					fn_ptr->arg_types[fn_ptr->arg_size] = var_type;
					fn_ptr->arg_array[fn_ptr->arg_size++]=array_type;
				}
				array_type = false;
			}
			| T_VAR {var_list.clear();array_type=false;}
			identifier_list colon
			type {
				for(int i=0;i<var_list.size();i++) {
					var_list[i]->id_type=var_type;
					var_list[i]->array_type = array_type;
					assert(fn_ptr!=NULL);
					fn_ptr->arg_types[fn_ptr->arg_size] = var_type;
					fn_ptr->arg_array[fn_ptr->arg_size++]=array_type;
				}
				array_type = false;
			}
			| parameter_list semicolon {var_list.clear();array_type=false;}
			identifier_list colon
			type {
				for(int i=0;i<var_list.size();i++) {
					var_list[i]->id_type=var_type;
					var_list[i]->array_type = array_type;
					assert(fn_ptr!=NULL);
					fn_ptr->arg_types[fn_ptr->arg_size] = var_type;
					fn_ptr->arg_array[fn_ptr->arg_size++]=array_type;
				}
				array_type = false;
			}
			| parameter_list semicolon T_VAR {var_list.clear();array_type=false;}
			identifier_list colon
			type {
				for(int i=0;i<var_list.size();i++) {
					var_list[i]->id_type=var_type;
					var_list[i]->array_type = array_type;
					assert(fn_ptr!=NULL);
					fn_ptr->arg_types[fn_ptr->arg_size] = var_type;
					fn_ptr->arg_array[fn_ptr->arg_size++]=array_type;
				}
				array_type = false;
			}
			;
				
compound_statement: 	T_BEGIN
				optional_statements
				T_END
				;
				 
optional_statements:	statement_list
				;
				
statement_list: 	statement
			| statement_list semicolon statement
				
				;
				
statement:	variable {variable_type = var_type;}
		assgnop
		expression {
			if(exp_type&&variable_type&&exp_type!=variable_type)
				type_mismatch_err(cnt);
		}
		| variable {variable_type = var_type;}
		EQ {print_err("Expected ':='",cnt);} 
		expression {
			if(exp_type&&variable_type&&exp_type!=variable_type)
				type_mismatch_err(cnt);
		}
		| procedure_statement
		| compound_statement
		| T_IF expression T_THEN statement
		| T_IF expression T_THEN statement T_ELSE statement
		| T_WHILE expression T_DO statement
		;
	 
variable: 	id {
			if(var_type==FUNC) {
				node * fn_ptr = find_var(str,cur_record);
				if(fn_ptr) {
					var_type = fn_ptr->get_ret_type();
				}
			}
		}

		| id { 
			if (!array_type && var_type!=0) {
				cout << "line " << cnt << " : ";
				cout << var_name << " - not of array type\n";
			}
		}
		open_square
		expression  {
			if(exp_type&&exp_type!=INTEGER){
				type_mismatch_err(cnt);
				cout << "\tArray index must be an integer\n";
			}
		}
		close_square
		;
	
procedure_statement:	id {
					if (var_type!=PROC) {
						cout << "line" << cnt << ":";
						cout << var_name << " not a procedure.\n";
					}
				}
				| id {
					//Need to do nesting for this
					node * temp = find_var(str,cur_record);
					if(!temp) {
						//Function not declared
						factor_type = 0;
					} else if(temp->id_type!=FUNC) {
						cout << "line " << cnt << " : " << str << " not a function \n";
						factor_type = temp->get_ret_type();
					} else {
						factor_type = temp->get_ret_type();
					} 
					fn_ptrs.push(temp);
				}
				open_paran {arg_types.clear();}
				expression_list
				close_paran {
					node* fn = fn_ptrs.top();
					fn_ptrs.pop();

					if(fn!=NULL && fn->get_ret_type()!=0) {
						//First check num of args
						if(fn->arg_size!=arg_types.size()) {
							cout << "\tIn call to function " << fn->lexeme << ", ";
							cout << "Expected " << fn->arg_size << " arguments, got " << arg_types.size() << endl;
						} else {
						//Now check type of each arg
							for(int i=0;i<arg_types.size();i++)
								if(arg_types[i]!=fn->arg_types[i]) {
									type_mismatch_err(cnt);
									cout << "\tIn call to function " << fn->lexeme << ", argument " << i+1 << " : ";
									string a,b;
									type_to_str(fn->arg_types[i],a);
									type_to_str(arg_types[i],b);
									cout << "Expected : " << a << ", Found : " << b << endl;
								}
						}
					} else
						exp_type=0;
					arg_types.clear();
				}
				;
			 
expression_list:	expression {arg_types.push_back(exp_type);}
			| expression_list comma expression {arg_types.push_back(exp_type);}
			;
				 
expression:	 simple_expression
		| simple_expression {sim_exp_type=exp_type;}
		RELOP
		simple_expression {
			if(sim_exp_type&& exp_type && sim_exp_type!=exp_type) {
				type_mismatch_err(cnt);
			}
			exp_type=BOOL;
		}
		;
		
simple_expression: term{exp_type = term_type;}
		 	| sign term{exp_type = term_type;}
		 	| simple_expression PLUS
		 	term { 
				if(term_type&&exp_type&&term_type!=exp_type)
					type_mismatch_err(cnt);
				//Else continue with the same type through the recursion
			}
			| simple_expression MINUS
			term {
				if(term_type&&exp_type&&term_type!=exp_type)
					type_mismatch_err(cnt);
				//Else continue with the same type through the recursion
			}
			;
		 
term: factor{term_type = factor_type;}
	| term MUL
	factor {
		if(term_type&&factor_type&&term_type!=factor_type)
			type_mismatch_err(cnt);
	}
	| term DIV
	factor {
		if(term_type&&factor_type&&term_type!=factor_type)
			type_mismatch_err(cnt);
	}
	| term MOD
	factor {
		if(term_type&&factor_type&&term_type!=factor_type)
			type_mismatch_err(cnt);
	}
	;

factor: 	id {factor_type = var_type;}
		| id {
			if (!array_type && var_type!=0) {
				cout << "line " << cnt << " : ";
				cout << var_name << " - not of array type\n";
			}
			factor_type = var_type;		
		}
		open_square
		expression {
			if(exp_type && exp_type!=INTEGER) {
				type_mismatch_err(cnt);
				cout << "\tArray index must be an integer\n";
			}
		}
		close_square
		| id {
			//Need to do nesting for this
			node * temp = find_var(str,cur_record);
			if(!temp) {
				//Function not declared
				factor_type = 0;
			} else if(temp->id_type!=FUNC) {
				cout << "line " << cnt << " : " << str << " not a function \n";
				factor_type = temp->get_ret_type();
			} else {
				factor_type = temp->get_ret_type();
			} 

			fn_ptrs.push(temp);
		}
		open_paran {arg_types.clear();}
		expression_list
		close_paran {
			node* fn = fn_ptrs.top();
			fn_ptrs.pop();
			if(fn!=NULL && fn->get_ret_type()!=0) {
				if(fn->arg_size!=arg_types.size()) {
					cout << "\tIn call to function " << fn->lexeme << ", ";
					cout << "Expected " << fn->arg_size << " arguments, got " << arg_types.size() << endl;
				} else {
					//Now check type of each arg
					for(int i=0;i<arg_types.size();i++)
						if(arg_types[i]!=fn->arg_types[i]) {
							type_mismatch_err(cnt);
							cout << "\tIn call to function " << fn->lexeme << ", argument " << i+1 << " : ";
							string a,b;
							type_to_str(fn->arg_types[i],a);
							type_to_str(arg_types[i],b);
							cout << "Expected : " << a << ", Found : " << b << endl;
						}
				}
			} else
				exp_type=0;
			arg_types.clear();
		}
		| num {factor_type = chk_num_type(yytext);}
		| sign num {factor_type = chk_num_type(yytext);}
		| open_paran expression close_paran
		| T_NOT factor
		;
			
sign:	PLUS
	| MINUS
	;

assgnop: 	ASSGNOP
		| error {print_err("Expected ':='",cnt);yyclearin; }
		;

comma: 	','
		| error {print_err("Expected ','",cnt); yyerrok;}
		;

semicolon: 	';'
		| error {print_err("Expected ';'",cnt); yyerrok;}
		;

colon:	':'
	| error {
		if(prev_err_line==cnt && !strcmp(prev_err,yytext))
			exit(0);
		strcpy(prev_err,yytext);
		prev_err_line=cnt;
		print_err("Expected ':'",cnt);
		yyerrok;
	}
	;

dot: 	'.'
	| error {print_err("Expected '.'",cnt); yyerrok;}
	;

open_paran: '('
		| error {
			if(prev_err_line==cnt && !strcmp(prev_err,yytext))
				exit(0);
			strcpy(prev_err,yytext);
			prev_err_line=cnt;
			print_err("Expected '('",cnt);
			yyerrok;
		}
		;

close_paran: ')'
		| error {print_err("Expected ')'",cnt); yyerrok;}
		;

open_square: 	'['
			| error {print_err("Expected '['",cnt); yyerrok;}
			;

close_square: 	']'
			| error {print_err("Expected ']'",cnt); yyerrok;}
			;

num: 	NUM
	| error {print_err("Expected Number",cnt); yyerrok;}
	;

t_program:	T_PROGRAM
		| error {print_err("Expected keyword 'program'",cnt); yyerrok;}
		;

id:	ID {
		var_name = yytext;
		for(int i=0;i<yyleng;i++)
			*(str+i) = toupper(yytext[i]);
		*(str+yyleng)='\0';
	
		if(!cur_record->table.ispresent(str)) {
			if(dec_var || dec_program || dec_func || dec_proc) {
				var_list.push_back(cur_record->table.addword(str,ID));
			} else {
				//Check parent records first (do later)
				node * temp;
				if(temp= find_var(str,cur_record->parent)) {
					var_type = temp->id_type;
					array_type=temp->array_type;
				} else {
					cout << "line " << cnt << ": ";
					cout << yytext << " not declared" << endl;
					var_type=0;
				}
			}
		} else {
			//Id present in symtable
			if(dec_var || dec_program || dec_func || dec_proc) {
				cout << "line " << cnt << " : Variable " << yytext << " already declared." << endl;
			} else {
				var_type = cur_record->table.ispresent(str)->id_type;
				array_type = cur_record->table.ispresent(str)->array_type;
			}
		}
	}
	| error {print_err("Expected identifier",cnt); yyerrok;}
	;
 
%%

//Additional code
void yyerror(const char *str) {
	 fprintf(stderr,"error: %s\n",str);
}

int yywrap() {
	 return 1;
} 

void print_err(const char * str,int line) {
	 cout << "line " << line << ": ";
	 cout << str << ", Found : '" << yytext << "'" << endl;
}

void type_mismatch_err(int line) {
	 cout << "line " << line << ": ";
	 cout << "Type mismatch." << endl;
}

int chk_num_type(const char * str) {
	for(int i=0;str[i];i++)
		if(str[i]=='.')
			return FLOAT;
	return INTEGER;
}

node * find_var(string str,Record * rec) {
	if(rec==NULL) return NULL;
	node * temp;
	if((temp = rec->table.ispresent(str))!=NULL)
		return temp;
	return find_var(str,rec->parent);
}
 
void print_global() {
	cout << "Global Record :\n";
	global->table.printtable();
}

void type_to_str(int type, string &str) {
	switch(type) {
		case INTEGER:
			str = "integer";
			break;
		case FLOAT:
			str = "real";
			break;
		default:
			str = "undefined type";
			break;
	}
}