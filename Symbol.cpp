#include "Symbol.h"

void node::set_ret_type(int type) {
	this->ret_type=type;
}

int node::get_ret_type(void) {
	return this->ret_type;
}

node::node(string name, int token_type, int idt=0) {
	lexeme = name;
	tokentype = token_type; 
	id_type=idt; // 0 implies unassigned type
	next = NULL;
	prev = NULL;
	array_type = false;

	for(int i=0;i<100;i++) {
		arg_types[i]=0;
		arg_array[i]=false;
	}
	arg_size=0;
	ret_type = 0;
}
	
node::node() {
	next=NULL;
	prev=NULL;
	id_type=0;

	for(int i=0;i<100;i++) {
		arg_types[i]=0;
		arg_array[i]=false;
	}
	arg_size=0;
	ret_type=0;
}