#include <string>
#include <iostream>
#include <vector>

using namespace std;

enum {INTEGER=1,FLOAT,BOOL,PROC,FUNC};

//Node is equivalent to a symbol in the symbol table.
class node {
	private:
		//Return type of a function
		int ret_type;
	
	public:
		string lexeme;
		int tokentype;
		int id_type; 
		bool array_type;

		//Types of arguments reqd for a func or proc
		int arg_types[100]; 
		//Argument if array or not
		bool arg_array[100];
		//No of args
		int arg_size;

		node* next;
		node* prev;

		void set_ret_type(int);
		int get_ret_type(void);
		
		node(string, int, int);
		node();

};