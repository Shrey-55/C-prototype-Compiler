%skeleton "lalr1.cc"
%require  "3.0.1"

%defines 
%define api.namespace {IPL}
%define api.parser.class {Parser}

%define parse.trace
%define api.location.type {IPL::location}

%code requires{
   namespace IPL {
      class Scanner;
   }

  // # ifndef YY_NULLPTR
  // #  if defined __cplusplus && 201103L <= __cplusplus
  // #   define YY_NULLPTR nullptr
  // #  else
  // #   define YY_NULLPTR 0
  // #  endif
  // # endif

}

%code requires{
	#include "ast.hh"
	#include "location.hh"
	#include "symbtab.hh"
	#include "type.cpp"
	
	
	extern SymbTab gst;

	
}
%code{
	#include "scanner.hh"
	
	using namespace std;
	SymbTab *mera_st;
	vector<kuch_class> var_list;
	vector<exp_astnode*>exp_list;
	// extern string text;
	
	int curr_offset = 0;
	int offset_multiplier = 1;
	string code = "";
	string func_ret_type = "";
	
	// stack<string>rstack;
	int count_code_labels = 1;
	int LC_count = 0;
	map<string,abstract_astnode*> ast;
}

%printer { std::cerr << $$; } VOID
%printer { std::cerr << $$; } INT
%printer { std::cerr << $$; } FLOAT
%printer { std::cerr << $$; } STRUCT
%printer { std::cerr << $$; } NUMBER
%printer { std::cerr << $$; } RETURN
%printer { std::cerr << $$; } OR_OP
%printer { std::cerr << $$; } AND_OP
%printer { std::cerr << $$; } EQ_OP
%printer { std::cerr << $$; } NE_OP
%printer { std::cerr << $$; } LE_OP
%printer { std::cerr << $$; } GE_OP
%printer { std::cerr << $$; } INC_OP
%printer { std::cerr << $$; } PTR_OP
%printer { std::cerr << $$; } WHILE
%printer { std::cerr << $$; } FOR
%printer { std::cerr << $$; } IF
%printer { std::cerr << $$; } ELSE
%printer { std::cerr << $$; } IDENTIFIER
%printer { std::cerr << $$; } INT_CONSTANT
%printer { std::cerr << $$; } FLOAT_CONSTANT
%printer { std::cerr << $$; } STRING_LITERAL
%printer { std::cerr << $$; } MAIN
%printer { std::cerr << $$; } PRINTF



%parse-param { Scanner  &scanner  }
%locations
%code{
   #include <iostream>
   #include <cstdlib>
   #include <fstream>
   #include <string>
   
   
   #include "scanner.hh"
   int nodeCount = 0;

#undef yylex
#define yylex IPL::Parser::scanner.yylex

}




%define api.value.type variant
%define parse.assert

%start program


%token <std::string> VOID
%token <std::string> INT
%token <std::string> FLOAT
%token <std::string> STRUCT
%token <std::string> NUMBER
%token <std::string> RETURN
%token <std::string> OR_OP
%token <std::string> AND_OP
%token <std::string> EQ_OP
%token <std::string> NE_OP
%token <std::string> LE_OP
%token <std::string> GE_OP
%token <std::string> INC_OP
%token <std::string> PTR_OP
%token <std::string> WHILE
%token <std::string> FOR
%token <std::string> IF
%token <std::string> ELSE
%token <std::string> IDENTIFIER
%token <std::string> PRINTF
%token <std::string> MAIN
%token <std::string> INT_CONSTANT
%token <std::string> FLOAT_CONSTANT
%token <std::string> STRING_LITERAL
%token '\n'
%token ':' '.' '{' '}' '[' ']' ';' ',' '=' '<' '>' '+' '-' '/' '*' '!' '&' '(' ')'

%nterm <kuch_class> translation_unit struct_specifier function_definition type_specifier fun_declarator parameter_list parameter_declaration declarator_arr declarator compound_statement statement_list statement assignment_expression assignment_statement procedure_call expression logical_and_expression equality_expression relational_expression additive_expression unary_expression multiplicative_expression postfix_expression primary_expression expression_list unary_operator selection_statement iteration_statement declaration_list declaration declarator_list main_definition printf_call

%%
program:
	main_definition
	{
		
	}
	| translation_unit main_definition
	{
	
	}
	;

main_definition:
   	INT MAIN '(' ')'{
		
		mera_st = new SymbTab();
		curr_offset =0;
		offset_multiplier = -1;
		curr_offset = 0;
		func_ret_type = "int";
		entry *e = new entry();
		e->name = "main";
		e->varfun = "fun";
		e->scope = "global";
		if(gst.Entries.find(e->name)!=gst.Entries.end())
		{
			error(@1,e->name+" has a previous definition");
		}
		// cout<<"dkfmefmokm";
		gst.Entries.insert({e->name,*e});
		text = text + "\t.globl\t" + "main" + "\n\t.type\t" + "main" + ", @function\n";
		text = text  + "main" + ":\n";
		text = text + "\tpushl %ebp\n\tmovl %esp, %ebp\n"; 
		
	} 
	compound_statement 
  	{
	 
	
		entry *e = &gst.Entries["main"];
		e->size = 0;
		e->offset = 0;
		e->type = "int";
		e->symbtab = mera_st;
		$$.node = $6.node;

		// cout<<"here1"<<endl;
		ast.insert({e->name,$$.node});
		//add the number of local variables in the below concatenation (make space)
		// cout<<"adad    "<<$$.node->astnode_type<<endl;

		$$.node->gencode();
		
		cout<<rodata<<endl;
		cout<<text<<endl;
		cout<<"\tleave\n\tret"<<endl;
		rodata = "";
		text = "";

	
  }
  ;

printf_call:
  	PRINTF '(' STRING_LITERAL ')' ';' 
  {
	// rodata = rodata + ".LC"+LC_count+":"+"\n\t.string \""+$3+"\"\n";
	// text = text + "\t" + "pushl	$.LC" + LC_count + "\n" + "\tcall\tprintf\n\taddl\t$4, %esp\n";  
	// LC_count+=1;
	$$.node = new proccall_astnode();
		identifier_astnode* iden = new identifier_astnode();
		iden->id = "printf";
		static_cast<proccall_astnode*>($$.node)->fname = iden;
		stringconst_astnode* str = new stringconst_astnode();
		str->s = $3;
		exp_list.push_back(static_cast<exp_astnode*>(str));
		
		static_cast<proccall_astnode*>($$.node)->arguments = exp_list;	
		exp_list.clear();

	  int a =1;
		

  }
  | PRINTF '(' STRING_LITERAL ',' expression_list ')' ';'
  {
	  	$$.node = new proccall_astnode();
		identifier_astnode* iden = new identifier_astnode();
		iden->id = "printf";
		// cout<<exp_list.size()<<"   "<<$5.e_list.size()<<endl;
		vector<exp_astnode*>tempp;
		for(int i=0;i<$5.e_list.size();i++) {
			tempp.push_back(static_cast<exp_astnode*>($5.e_list[i].node));
		}
		static_cast<proccall_astnode*>($$.node)->fname = iden;
		stringconst_astnode* str = new stringconst_astnode();
		str->s = $3;

		tempp.push_back(static_cast<exp_astnode*>(str));
		
		static_cast<proccall_astnode*>($$.node)->arguments =tempp;	
		exp_list.clear();
		//rodata = rodata + ".LC"+LC_count+":"+"\n\t.string \""+$3+"\"\n";
	  	
		// for(auto i=0;i<exp_list.length();i++) {
		// 	exp_list[i]->gencode();
			
	  	// 	text = text + "\tpushl "+rstack.top()+"\n";
	  
		// }
	//text = text + "\t" + "pushl	$.LC" + LC_count + "\n"+ "\tcall\tprintf\n\taddl\t$"+to_string(exp_list.length()*4+4)+", %esp\n";
	//LC_count+=1;
	//exp_list.clear();
	  //int a =1;

  }
  ;

translation_unit:
	struct_specifier 
	{
		 
	}

	| function_definition 
	{
		
	}

	| translation_unit struct_specifier 
	{
		
	}

	| translation_unit function_definition 
	{
		
	}

	;

struct_specifier:
	STRUCT IDENTIFIER '{'
	{
		mera_st = new SymbTab();
		curr_offset = 0;
		offset_multiplier = 1;
		entry *e = new entry();
		e->name = "struct " + $2;
		e->varfun = "struct";
		e->scope = "global";
		if(gst.Entries.find(e->name)!=gst.Entries.end())
		{
			error(@1,e->name+" has a previous definition");
		}
		gst.Entries.insert({e->name,*e});
	} 
	declaration_list '}' ';' 
	{
		entry *e = &gst.Entries["struct " + $2];
		e->size = $5.size;
		e->offset = 0;
		e->type = "-";
		e->symbtab = mera_st;
		
		
	}
	;

function_definition:
	type_specifier fun_declarator 
	{
		offset_multiplier = -1;
		curr_offset = 0;
		func_ret_type = $1.type;
		entry *e = new entry();
		e->name = $2.name;
		e->varfun = "fun";
		e->scope = "global";
		if(gst.Entries.find(e->name)!=gst.Entries.end())
		{
			error(@1,e->name+" has a previous definition");
		}
		gst.Entries.insert({e->name,*e});
		text = text + "\t.globl\t" + $2.name + "\n\t.type\t" + $2.name + ", @function\n";
		text = text  + $2.name + ":\n";
		text = text + "\tpushl %ebp\n\tmovl %esp, %ebp\n"; 
		// text = text + "\tsubl " + ",%esp\n";  

	}
	compound_statement 

	{
		entry *e = &gst.Entries[$2.name];
		e->size = 0;
		e->offset = 0;
		e->type = $1.type;
		e->symbtab = mera_st;
		$$.node = $4.node;
		// cout<<"here1"<<endl;
		ast.insert({e->name,$$.node});
		//add the number of local variables in the below concatenation (make space)
		// cout<<"adad    "<<$$.node->astnode_type<<endl;

		$$.node->gencode();
		// cout<<"here1"<<endl;
		
		
		cout<<rodata<<endl;

		cout<<text<<endl;
		cout<<"\tleave\n\tret"<<endl;
		rodata = "";
		text = "";
		
		//mera_st = new SymbTab();
		// stat_list.clear();
	}
	;

type_specifier:
	VOID 
	{
		$$.type = $1;
		$$.size = 4;
	}

	| INT 
	{
		// cout<<"in int";
		$$.type = $1;
		$$.size = 4;
	}

	| FLOAT 
	{
		$$.type = $1;
		$$.size = 4;
	}

	| STRUCT IDENTIFIER 
	{
		$$.type = $1 + " " + $2;
		//symbtab se lana hai
		if(gst.Entries.find($$.type) == gst.Entries.end())
		{
			error(@1,"given structure def doesn't exist");
		}
		else
		{
			$$.size = gst.Entries[$$.type].size;
		}
		
	}

	;

fun_declarator:
	IDENTIFIER '(' 
	{
		//$$.name = $1;
		mera_st = new SymbTab();
		curr_offset = 0;
	} 
	parameter_list ')' 
	{
		$$.name = $1;
		int vecSize = var_list.size();
		for (int var=vecSize-1;var >= 0;var--){
			entry* e = new entry();
			e->name = var_list[var].name;
			e->varfun = "var";
			e->scope = "param";
			e->type = var_list[var].type;
			if(e->type.find("void")!=string::npos)
			{
				if(e->type.find("*") == string::npos)
					error(@1,"can't declare the type of a parameter as void");
			}
			e->size = var_list[var].size;
			e->offset = 12 + curr_offset;
			curr_offset += e->size;
			e->symbtab = nullptr;
			if(mera_st->Entries.find(e->name) != mera_st->Entries.end())
			{
				error(@1,"\"" + e->name +"\" has a previous declaration");
			}
			mera_st->Entries.insert({e->name,*e});
		}
		var_list.clear();

	}

	| IDENTIFIER '(' ')' 
	{
		$$.name = $1;
		mera_st = new SymbTab();
		curr_offset =0;
	}
	;

parameter_list:
	parameter_declaration 
	{
		var_list.push_back($1);
	}

	| parameter_list ',' parameter_declaration 
	{
		var_list.push_back($3);
	}
	;

parameter_declaration:
	type_specifier declarator 
	{

		$$.name = $2.name;
		
		$$.type = $1.type + $2.type;
		if(($$.type.find("struct") != string::npos) && ($$.type.find("*")!= string::npos))
		{
			
			$$.size = 4 * $2.size;
		}
		else
		{
			$$.size = $1.size * $2.size;
		}
	}
	;

declarator_arr:
	IDENTIFIER 
	{
		$$.name = $1;
		$$.type = "";
		$$.size = 1;
		$$.is_lvalue = true;
	}

	| declarator_arr '[' INT_CONSTANT ']' 
	{
		$$.name = $1.name;
		$$.type = $1.type + "["+ $3 +"]";
		//////////////////////
		$$.size = $1.size * stoi($3);
		$$.is_lvalue = true;
	}

	;

declarator:
	declarator_arr 
	{
		$$.type = $1.type;
		$$.name = $1.name;
		$$.size = $1.size;
		$$.is_lvalue = true;
	}

	| '*' declarator 
	{
		$$.type = "*" + $2.type ;
		$$.name = $2.name;
		//////////////// change size
		$$.size = $2.size; 
		$$.is_lvalue = true;
	}

	;

compound_statement:
	'{' '}' 
	{
		$$.node = new seq_astnode();
	}

	| '{' statement_list '}' 
	{
		// cout<<"yadayada"<<endl;
		$$.node = $2.node;
	}
	| '{' declaration_list '}'
	{
		$$.node = new seq_astnode();
	}

	| '{' declaration_list statement_list '}' 
	{
		$$.node = $3.node;
	}
	;

statement_list:
	statement 
	{
		$$.node = new seq_astnode();
		$$.stat_list.push_back(static_cast<statement_astnode*>($1.node));
		static_cast<seq_astnode*>($$.node)->statements = $$.stat_list;

	}

	| statement_list statement 
	{
		$$.node = new seq_astnode();
		$$.stat_list = $1.stat_list;
		$$.stat_list.push_back(static_cast<statement_astnode*>($2.node));
		static_cast<seq_astnode*>($$.node)->statements = $$.stat_list;
	}
	;

statement:
	';' 
	{
		$$.node = new empty_astnode();
		$$.stat_list.push_back(static_cast<statement_astnode*>($$.node));
	}

	| '{' statement_list '}' 
	{
		$$.node = $2.node;
		$$.stat_list = $2.stat_list;
	}

	| selection_statement 
	{
		$$.node = $1.node;
		$$.stat_list.push_back(static_cast<statement_astnode*>($1.node));
	}

	| iteration_statement 
	{
		$$.node = $1.node;
		$$.stat_list.push_back(static_cast<statement_astnode*>($1.node));
	}

	| assignment_statement 
	{
		$$.node = $1.node;
		$$.stat_list.push_back(static_cast<statement_astnode*>($1.node));
		
	}

	| procedure_call 
	{
		$$.node = $1.node;
		$$.stat_list.push_back(static_cast<statement_astnode*>($1.node));
	}
	| printf_call
	{
		$$.node = $1.node;	
		$$.stat_list.push_back(static_cast<statement_astnode*>($1.node));
	}
	| RETURN expression ';' 
	{
		$$.node = new return_astnode();
	
		static_cast<return_astnode*>($$.node)->return_exp =static_cast<exp_astnode*>($2.node); 
		if($2.type != func_ret_type)
		{
			//might need to cast
			if(func_ret_type == "float")
			{
				if($2.type == "int")
				{
					op_unary_astnode* temp = new op_unary_astnode();
					temp->op = "TO_FLOAT";
					temp->a = static_cast<exp_astnode*>($2.node);
					static_cast<return_astnode*>($$.node)->return_exp = static_cast<exp_astnode*>(temp);
				}
				else
				{
					error(@1,"incompatible return type float");
				}
			}
			else if(func_ret_type == "int")
				{
					if($2.type == "float")
					{
						op_unary_astnode* temp = new op_unary_astnode();
						temp->op = "TO_INT";
						temp->a = static_cast<exp_astnode*>($2.node);
						static_cast<return_astnode*>($$.node)->return_exp = static_cast<exp_astnode*>(temp);
					}
					else
					{
						error(@1,"incompatible return type int");
					}
				}
			else if(func_ret_type == "void")
			{
				error(@1, "Return type void");
			}
			else
			{
				error(@1,"incompatible return type");
			}
		}
		
		$$.stat_list.push_back(static_cast<statement_astnode*>($$.node));
	}

	;

assignment_expression:
	unary_expression '=' expression 
	{
		$$.node = new assignE_astnode();
		// static_cast<assignE_astnode*>($$.node)->type = static_cast<exp_astnode*>($3.node)->type;
		// $$.node->type = $3.n
		static_cast<assignE_astnode*>($$.node)->lhs = static_cast<exp_astnode*>($1.node);
		static_cast<assignE_astnode*>($$.node)->rhs = static_cast<exp_astnode*>($3.node);
		

		
		if($1.type == "float")
		{
			if($3.type == "float") {
				$$.type = "float";
			}
			else
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				
				static_cast<assignE_astnode*>($$.node)->rhs = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<assignE_astnode*>($$.node)->lhs = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			else
			{
				$$.type = $1.type;
				
			}
			
		}
		else if($1.is_ptr() && $3.is_zero) {
			
		}
		else if($1.mtype() == $3.mtype()) {
			$$.type = $1.type;
			static_cast<assignE_astnode*>($$.node)->type = static_cast<exp_astnode*>($1.node)->type;

		}
		else if($1.is_void() && $1.is_ptr() == 1 && $3.is_ptr()) {

		}
		else if($1.is_ptr() && $3.is_void() && $3.is_ptr() == 1) {

		}
		
		

	// $$.node->gencode(mera_st);
		
	}

	;

assignment_statement:
	assignment_expression ';' 
	{
		$$.node = new assignS_astnode();
		static_cast<assignS_astnode*>($$.node)->lhs = static_cast<assignE_astnode*>($1.node)->lhs;
		static_cast<assignS_astnode*>($$.node)->rhs = static_cast<assignE_astnode*>($1.node)->rhs;
		// cout<<"oiafawnf"<<endl;
		// static_cast<assignS_astnode*>($$.node)->gencode(mera_st);
	}

	;

procedure_call:
	IDENTIFIER '(' ')' ';' 
	{
		$$.node = new proccall_astnode();
		identifier_astnode* iden = new identifier_astnode();
		iden->id = $1;
		static_cast<proccall_astnode*>($$.node)->fname = iden;
		static_cast<proccall_astnode*>($$.node)->arguments = exp_list;
		if(gst.Entries.find($1) == gst.Entries.end())
		{
			if($1=="printf" || $1 == "scanf");	
			else
				error(@1,"No function of name "+$1 + " exists");
		}
		else
		{
			SymbTab *f_st = gst.Entries[$1].symbtab;
			vector<string> types = f_st->sort1();
			$$.type = gst.Entries[$1].type;
			if(types.size()>0)
			{
				error(@1,"Procedure "+$1+"called with too little arguments");
			}

		}
		exp_list.clear();
	}

	| IDENTIFIER '(' expression_list ')' ';' 
	{
		$$.node = new proccall_astnode();
		identifier_astnode* iden = new identifier_astnode();
		iden->id = $1;

		if(gst.Entries.find($1) == gst.Entries.end())
		{
			if($1=="printf" || $1 == "scanf");	
			else
				error(@1,"No function of name "+$1 + " exists");
		}
		else
		{
			SymbTab *f_st = gst.Entries[$1].symbtab;
			vector<string> types = f_st->sort1();
			$$.type = gst.Entries[$1].type;
			if(types.size()>$3.e_list.size())
			{
				error(@1,"Procedure called with too little arguments");
			}
			else if(types.size()<$3.e_list.size())
			{
				error(@1,"Procedure called with too many arguments");
			}
			else
			{
				for(int i = 0; i< types.size();i++)
				{
					// cout<<i<<types[i]<<$3.e_list[i].type<<endl;
					if(types[i]!=$3.e_list[i].type)
					{
						if(types[i] == "float")
						{
							if($3.e_list[i].type == "int")
							{
								op_unary_astnode* temp = new op_unary_astnode();
								temp->op = "TO_FLOAT";
								temp->a = static_cast<exp_astnode*>(exp_list[i]);
								(exp_list[i]) = static_cast<exp_astnode*>(temp);
							}
							else
							{
								error(@1,"Expected " + types[i] + " but argument is of type "+$3.e_list[i].type);
							}
						}
						else if(types[i] == "int")
							{
								if($3.e_list[i].type == "float")
								{
									
									op_unary_astnode* temp = new op_unary_astnode();
									temp->op = "TO_INT";
									temp->a = static_cast<exp_astnode*>(exp_list[i]);
									(exp_list[i]) = static_cast<exp_astnode*>(temp);
								}
								else
								{
									error(@1,"Expected " + types[i] + " but argument is of type "+$3.e_list[i].type);
								}
							}
						else if(types[i] == "void*" && $3.e_list[i].is_ptr())
						{
							//need to handle when func ret type is ptr and void* ret
						}
						else
						{
							error(@1,"incompatible argument type" + types[i] + " and " + $3.e_list[i].type);
						}
					}
				}
			}

		} 
		static_cast<proccall_astnode*>($$.node)->fname = iden;
		static_cast<proccall_astnode*>($$.node)->arguments = exp_list;
		exp_list.clear();
	}

	;

expression:
	logical_and_expression 
	{
		$$.node = $1.node;
		$$.type = $1.type;
		$$.is_lvalue = $1.is_lvalue;
		$$.is_zero = $1.is_zero;

	}

	| expression OR_OP logical_and_expression 
	{
		$$.node = new op_binary_astnode();
		if($1.is_struct() && !$1.is_ptr() || $3.is_struct() && !$3.is_ptr()) {
			error(@1, "struct not allowed with operator OR");
		}
		static_cast<op_binary_astnode*>($$.node)->op = "OR_OP";
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);
		static_cast<op_binary_astnode*>($$.node)->type = "int";
		
		$$.type = "int";
		$$.is_lvalue = false;
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	;

logical_and_expression:
	equality_expression 
	{
		$$.node = $1.node;
		$$.type = $1.type;
		$$.is_lvalue = $1.is_lvalue;
		$$.is_zero = $1.is_zero;
	}

	| logical_and_expression AND_OP equality_expression 
	{
		$$.node = new op_binary_astnode();
		if($1.is_struct() && !$1.is_ptr() || $3.is_struct() && !$3.is_ptr()) {
			error(@1, "struct not allowed with operator AND");
		}
		static_cast<op_binary_astnode*>($$.node)->op = "AND_OP";
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);
		static_cast<op_binary_astnode*>($$.node)->type = "int";

		$$.type = "int";
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}		
	}

	;

equality_expression:
	relational_expression 
	{
		$$.node = $1.node;
		$$.type = $1.type;
		$$.is_lvalue = $1.is_lvalue;
		$$.is_zero = $1.is_zero;
	}

	| equality_expression EQ_OP relational_expression 
	{
		$$.node = new op_binary_astnode();
		// /* cout<<$1.type<<$3.type<<endl; */
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);
		if($1.is_struct() && !$1.is_ptr() || $3.is_struct() && !$3.is_ptr()) {
			error(@1, "struct not allowed with operator ==");
		}

		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "EQ_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->type = "int";

			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "EQ_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				static_cast<op_binary_astnode*>($$.node)->type = "int";

				$$.type = "int";
			}
			else {
				error(@1, "Incompatable types with possible correct float pointer addition waapas dekh");
			}
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "EQ_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				static_cast<op_binary_astnode*>($$.node)->type = "int";

				$$.type = "int";
			}
			else if($3.type == "int")
			{
				$$.type = $1.type;
				static_cast<op_binary_astnode*>($$.node)->op = "EQ_OP_INT";
			}
			else {
				error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary ==");
			}
		}
		else if($1.is_ptr() && $3.is_zero || $1.is_zero && $3.is_ptr()) {
			$$.type = "int";
			static_cast<op_binary_astnode*>($$.node)->op = "EQ_OP_INT";
		}
		else if($1.mtype() == $3.mtype()) {
			$$.type = "int";
			static_cast<op_binary_astnode*>($$.node)->op = "EQ_OP_INT";
			//check other pointers and stuff by testing later for now allowing same datatypes
		}
		else if($1.is_ptr() == $3.is_ptr()) {
			if(($3.is_int() && $1.is_int()) || ($1.is_float() && $3.is_float())) {
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "EQ_OP_INT";
			}
		}
		else {
			error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary ==");
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	| equality_expression NE_OP relational_expression 
	{
		$$.node = new op_binary_astnode();
		
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);
		if($1.is_struct() && !$1.is_ptr() || $3.is_struct() && !$3.is_ptr()) {
			error(@1, "struct not allowed with operator !=");
		}

		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "NE_OP_FLOAT";
			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "NE_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			else {
				error(@1, "Incompatable types with possible correct float pointer addition waapas dekh");
			}
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "NE_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			else if($3.type == "int")
			{
				$$.type = $1.type;
				static_cast<op_binary_astnode*>($$.node)->op = "NE_OP_INT";
			}
			else {
				error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary !=");
			}
		}
		else if($1.is_ptr() && $3.is_zero || $1.is_zero && $3.is_ptr()) {
			$$.type = "int";
			static_cast<op_binary_astnode*>($$.node)->op = "EQ_OP_INT";
		}
		else if($1.mtype() == $3.mtype()) {
			$$.type = "int";
			static_cast<op_binary_astnode*>($$.node)->op = "NE_OP_INT";
			//check other pointers and stuff by testing later for now allowing same datatypes
		}
		else if($1.is_ptr() == $3.is_ptr()) {
			if(($3.is_int() && $1.is_int()) || ($1.is_float() && $3.is_float())) {
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "NE_OP_INT";
			}
		}
		else {
				error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary !=");
			
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	;

relational_expression:
	additive_expression 
	{
		$$.node = $1.node;
		$$.type = $1.type;
		$$.is_lvalue = $1.is_lvalue;
		$$.is_zero = $1.is_zero;
	}

	| relational_expression '<' additive_expression 
	{
		$$.node = new op_binary_astnode();
		// cout<<$1.type<<$3.type<<endl;
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);
		if($1.is_struct() && !$1.is_ptr() || $3.is_struct() && !$3.is_ptr()) {
			error(@1, "struct not allowed with operator <");
		}

		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "LT_OP_FLOAT";
			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "LT_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			else {
				error(@1, "Incompatable types with possible correct float pointer addition waapas dekh");
			}
		}
		else if($1.type == "int")
		{
			// // cout<<"here"<<endl;
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "LT_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			else if($3.type == "int")
			{
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "LT_OP_INT";
			}
			else {
				$$.type = "int";
				error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary <");
			}
		}
		else if($1.mtype() == $3.mtype()) {
			$$.type = "int";
			static_cast<op_binary_astnode*>($$.node)->op = "LT_OP_INT";
			//check other pointers and stuff by testing later for now allowing same datatypes
		}
		else if($1.is_ptr() == $3.is_ptr()) {
			if(($3.is_int() && $1.is_int()) || ($1.is_float() && $3.is_float())) {
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "LT_OP_INT";
			}
		}
		else {
			error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary <");
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	| relational_expression '>' additive_expression 
	{
		$$.node = new op_binary_astnode();
		
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);


		if($1.is_struct() && !$1.is_ptr() || $3.is_struct() && !$3.is_ptr()) {
			error(@1, "struct not allowed with operator >");
		}
		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "GT_OP_FLOAT";
			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "GT_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			else {
				error(@1, "Incompatable types with possible correct float pointer addition waapas dekh");
			}
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "GT_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			else if($3.type == "int")
			{
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "GT_OP_INT";
			}
			else {
				error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary >");
			}
		}
		else if($1.mtype() == $3.mtype()) {
			$$.type = "int";
			static_cast<op_binary_astnode*>($$.node)->op = "GT_OP_INT";
			//check other pointers and stuff by testing later for now allowing same datatypes
		}
		else if($1.is_ptr() == $3.is_ptr()) {
			if(($3.is_int() && $1.is_int()) || ($1.is_float() && $3.is_float())) {
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "GT_OP_INT";
			}
		}
		else {
			error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary >");
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	| relational_expression LE_OP additive_expression 
	{
		$$.node = new op_binary_astnode();
		
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);
		if($1.is_struct() && !$1.is_ptr() || $3.is_struct() && !$3.is_ptr()) {
			error(@1, "struct not allowed with operator <=");
		}

		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "LE_OP_FLOAT";
			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "LE_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			
			else {
				error(@1, "Incompatable types with possible correct float pointer addition waapas dekh");
			}
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "LE_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			else if($3.type == "int")
			{
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "LE_OP_INT";
			}
			else {
				error(@1,"Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary <=");
			}
		}
		else if($1.mtype() == $3.mtype()) {
			$$.type = "int";
			static_cast<op_binary_astnode*>($$.node)->op = "LE_OP_INT";
			//check other pointers and stuff by testing later for now allowing same datatypes
		}
		else if($1.is_ptr() == $3.is_ptr()) {
			if(($3.is_int() && $1.is_int()) || ($1.is_float() && $3.is_float())) {
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "LE_OP_INT";
			}
		}
		else {
			error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary <=");
		}	
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	| relational_expression GE_OP additive_expression 
	{
		$$.node = new op_binary_astnode();
		
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);
		if($1.is_struct() && !$1.is_ptr() || $3.is_struct() && !$3.is_ptr()) {
			error(@1, "struct not allowed with operator >=");
		}

		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "GE_OP_FLOAT";
			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "GE_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			
			else {
				error(@1, "Incompatable types with possible correct float pointer addition waapas dekh");
			}
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "GE_OP_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				$$.type = "int";
			}
			else if($3.type == "int")
			{
				$$.type = $1.type;
				static_cast<op_binary_astnode*>($$.node)->op = "GE_OP_INT";
			}
			else {
				error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary >=");
			}
		}

		else if($1.mtype() == $3.mtype()) {
			$$.type = "int";
			static_cast<op_binary_astnode*>($$.node)->op = "GE_OP_INT";
			//check other pointers and stuff by testing later for now allowing same datatypes
		}
		else if($1.is_ptr() == $3.is_ptr()) {
			if(($3.is_int() && $1.is_int()) || ($1.is_float() && $3.is_float())) {
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "GE_OP_INT";
			}
		}
		else {
			error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary >=");
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	;

additive_expression:
	multiplicative_expression 
	{
		$$.node = $1.node;
		$$.type = $1.type;
		$$.is_lvalue = $1.is_lvalue;
		$$.is_zero = $1.is_zero;
	}

	| additive_expression '+' multiplicative_expression 
	{
		$$.node = new op_binary_astnode();
		
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);

		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "float";
				static_cast<op_binary_astnode*>($$.node)->op = "PLUS_FLOAT";
			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "PLUS_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			else if($3.is_ptr()) {
				$$.type = "float";
				static_cast<op_binary_astnode*>($$.node)->op = "PLUS_FLOAT";
			}
			else {
				error(@1, "Incompatable types with possible correct float pointer addition waapas dekh");
			}
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "PLUS_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			else if($3.type == "int")
			{
				$$.type = $1.type;
				static_cast<op_binary_astnode*>($$.node)->op = "PLUS_INT";
			}
			else if($3.is_ptr()) {
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "PLUS_INT";
			}
			else {
				error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary +");
			}
		}
		else if($1.is_ptr()) {
			if($3.type == "float") {
				$$.type = $1.type;
				static_cast<op_binary_astnode*>($$.node)->op = "PLUS_FLOAT";
			}
			else if($3.type == "int") {
				$$.type = $1.type;
				static_cast<op_binary_astnode*>($$.node)->op = "PLUS_INT";
			}
			else {
				error(@1, "Incompatable types " + $1.type + " and " + $3.type  + "in binary + operator");
			}
		}
		else {
			error(@1, "Incompatable types " + $1.type + " and " + $3.type  + "in binary + operator");
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	| additive_expression '-' multiplicative_expression 
	{
		$$.node = new op_binary_astnode();
		
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);

		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "float";
				static_cast<op_binary_astnode*>($$.node)->op = "MINUS_FLOAT";
			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "MINUS_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			else {
				error(@1, "Incompatable types with possible correct float pointer addition waapas dekh");
			}
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "MINUS_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			else if($3.type == "int")
			{
				$$.type = $1.type;
				static_cast<op_binary_astnode*>($$.node)->op = "MINUS_INT";
			}
			else {
				
				error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary -");
			}
		}
		else if($1.is_ptr()) {
			if($3.is_ptr() == $1.is_ptr()) {
				if(($3.is_int() && $1.is_int()) || ($1.is_float() && $3.is_float())) {
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "MINUS_INT";
			}
			}
			else if($3.type == "int") {
				$$.type = "int";
				static_cast<op_binary_astnode*>($$.node)->op = "MINUS_INT";
			}
			else if($3.type == "float") {
				$$.type = "float";
				static_cast<op_binary_astnode*>($$.node)->op = "MINUS_FLOAT";
			}
			else {
				error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary -");
			}
		}
		else {
			error(@1, "Incompatable types " + $1.type + " and " + $3.type + " incompatible in binary -");
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	;

unary_expression:
	postfix_expression 
	{
		$$.node = $1.node;
		$$.type = $1.type;
		$$.is_lvalue = $1.is_lvalue;
		$$.is_zero = $1.is_zero;
	}

	| unary_operator unary_expression 
	{
		$$.node = new op_unary_astnode();
		if($1.name == "DEREF")
		{	
			string post_type = $2.type;
			size_t pos_start = post_type.rfind("[");
			size_t pos_end = post_type.rfind("]");
			size_t pos_star = post_type.find("*");
			if($2.is_void()) {

				error(@1, "void can't be dereferenced" + $2.type);
			}
			if(pos_start!=pos_end)
			{
				post_type.erase(pos_start,pos_end-pos_start+1);
				// static_cast<op_binary_astnode*>($$.node)->type = "int";

				$$.type = post_type;
				static_cast<op_unary_astnode*>($$.node)->type = post_type;

			}
			else if(pos_star!=string::npos)
			{
				post_type.erase(pos_star,1);
				static_cast<op_unary_astnode*>($$.node)->type = post_type;
				$$.type= post_type;
			}
			else
			{
				error(@1,"unary oper can't be referenced");
			}
		}
		else if($1.name == "ADDRESS")
		{	
			string post_type = $2.type;
			size_t pos_start = post_type.find("[");
			size_t pos_end = post_type.find("]");
			size_t pos_star = post_type.find("*");
			if(pos_start!=pos_end)
			{
				post_type.insert(pos_start,"(*)");//bracket ka backchodi karna ho toh rfind ka option hai
				static_cast<op_unary_astnode*>($$.node)->type = post_type;
				$$.type = post_type;
			}
			else if(pos_star!=string::npos)
			{
				post_type.insert(pos_star,"*");
				static_cast<op_unary_astnode*>($$.node)->type = post_type;
				$$.type= post_type;
			}
			else
			{
				static_cast<op_unary_astnode*>($$.node)->type = post_type + "*";
				$$.type = post_type + "*";
			}
			if(!$2.is_lvalue) {
				error(@1,"& operand should have lvalue");
			}
		}
		else if($1.name == "NOT"){
			$$.type = "int";
			
		}
		else
		{
			$$.type = $2.type;// -
		}
		if($1.name == "UMINUS") {
			if($2.type == "int" || $2.type == "float") {

			}
			else {
				error(@1, "unary minus operand not int or float");
			}
		}
		static_cast<op_unary_astnode*>($$.node)->op = $1.name;
		static_cast<op_unary_astnode*>($$.node)->a = static_cast<exp_astnode*>($2.node);
		$$.is_lvalue = $1.is_lvalue;
	}

	;

multiplicative_expression:
	unary_expression 
	{
		$$.node = $1.node;
		$$.type = $1.type;
		$$.is_lvalue = $1.is_lvalue;
		$$.is_zero = $1.is_zero;
	}

	| multiplicative_expression '*' unary_expression 
	{
		$$.node = new op_binary_astnode();
		
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);
		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "float";
				static_cast<op_binary_astnode*>($$.node)->op = "MULT_FLOAT";
			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "MULT_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			else {
				error(@1, "Incompatable types");
			}
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "MULT_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			else if($3.type == "int")
			{
				$$.type = $1.type;
				static_cast<op_binary_astnode*>($$.node)->op = "MULT_INT";
			}
			else {
				error(@1, "Incompatable types");
			}
		}
		
		else {
			error(@1, "Incompatable types");
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	| multiplicative_expression '/' unary_expression 
	{
		$$.node = new op_binary_astnode();
		
		static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>($3.node);

		if($1.type == "float")
		{
			if($3.type == "float")
			{
				$$.type = "float";
				static_cast<op_binary_astnode*>($$.node)->op = "DIV_FLOAT";
			}
			else if($3.type == "int")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($3.node);
				static_cast<op_binary_astnode*>($$.node)->op = "DIV_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->b = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			else {
				error(@1, "Incompatable types");
			}
		}
		else if($1.type == "int")
		{
			if($3.type == "float")
			{
				op_unary_astnode* to_float = new op_unary_astnode();
				to_float->op = "TO_FLOAT";
				to_float->a =  static_cast<exp_astnode*>($1.node);
				static_cast<op_binary_astnode*>($$.node)->op = "DIV_FLOAT";
				static_cast<op_binary_astnode*>($$.node)->a = static_cast<exp_astnode*>(to_float);
				$$.type = "float";
			}
			else if($3.type == "int")
			{
				$$.type = $1.type;
				static_cast<op_binary_astnode*>($$.node)->op = "DIV_INT";
			}
			else {
				error(@1, "Incompatable types");
			}
		}
		
		else {
			error(@1, "Incompatable types");
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->a->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->a->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->b->astnode_type == identifier_type || static_cast<op_binary_astnode*>($$.node)->b->astnode_type == intconst_type){
			static_cast<op_binary_astnode*>($$.node)->b->label_node = 1;
		}
		if(static_cast<op_binary_astnode*>($$.node)->a->label_node == static_cast<op_binary_astnode*>($$.node)->b->label_node) {
			static_cast<op_binary_astnode*>($$.node)->label_node = static_cast<op_binary_astnode*>($$.node)->a->label_node + 1;
		}
		else {
			static_cast<op_binary_astnode*>($$.node)->label_node = std::max(static_cast<op_binary_astnode*>($$.node)->a->label_node,static_cast<op_binary_astnode*>($$.node)->b->label_node);
		}
	}

	;

postfix_expression:
	primary_expression 
	{
		$$.node = $1.node;
		$$.type = $1.type;
		$$.is_lvalue = $1.is_lvalue;
		$$.is_zero = $1.is_zero;
	}

	| postfix_expression '[' expression ']' 
	{
		if($3.type != "int")
		{
			error(@1,"array subscript is not an integer");
		}
		if(!$1.is_ptr())
		{
			error(@1,"Subscripted value is neither array nor pointer");
		}

		$$.node = new arrayref_astnode();
		string post_type = $1.type;
		size_t pos_start = post_type.rfind("[");
		size_t pos_end = post_type.rfind("]");
		size_t pos_star = post_type.find("*");
		if(pos_start!=pos_end)
		{
			post_type.erase(pos_start,pos_end-pos_start+1);
			$$.type = post_type;
		}
		else if(pos_star!=string::npos)
		{
			post_type.erase(pos_star,1);
			$$.type= post_type;
		}
		else
		{
			error(@1,"can't be referenced");
		}
		static_cast<arrayref_astnode*>($$.node)->array = static_cast<exp_astnode*>($1.node);
		static_cast<arrayref_astnode*>($$.node)->index = static_cast<exp_astnode*>($3.node);
		$$.is_lvalue = $1.is_lvalue;
	}

	| IDENTIFIER '(' ')' 
	{
		$$.node = new funcall_astnode();
		if(gst.Entries.find($1) == gst.Entries.end())
		{
			//Incorrect scope, handle
			if($1=="printf" || $1 == "scanf");	
			else
				error(@1,"No function of name "+$1 + " exists");
		}
		else
		{
			SymbTab *f_st = gst.Entries[$1].symbtab;
			vector<string> types = f_st->sort1();
			if(types.size()>0)
			{
				error(@1,"Procedure " +$1+" called with too little arguments");
			}
			$$.type = gst.Entries[$1].type;
		}
		identifier_astnode* temp = new identifier_astnode();
		temp->id = $1;
		static_cast<funcall_astnode*>($$.node)->id = temp;
		vector<exp_astnode*> vec;
		vec.clear();
		static_cast<funcall_astnode*>($$.node)->arguments = vec;
		$$.is_lvalue = false;
	}

	| IDENTIFIER '(' expression_list ')' 
	{
		$$.node = new funcall_astnode();
		if(gst.Entries.find($1) == gst.Entries.end())
		{
			if($1=="printf" || $1 == "scanf");	
			else
				error(@1,"No function of name "+$1 + " exists");
		}
		else
		{
			SymbTab *f_st = gst.Entries[$1].symbtab;
			
			vector<string> types = f_st->sort1();
			
			$$.type = gst.Entries[$1].type;
			
			if(types.size()>$3.e_list.size())
			{
				error(@1,"Procedure called with too little arguments");
			}
			else if(types.size()<$3.e_list.size())
			{
				error(@1,"Procedure called with too many arguments");
			}
			else
			{
				for(int i = 0; i< types.size();i++)
				{
					// cout<<i<<types[i]<<$3.e_list[i].type<<endl;
					if(types[i]!=$3.e_list[i].type)
					{
						if(types[i] == "float")
						{
							if($3.e_list[i].type == "int")
							{
								op_unary_astnode* temp = new op_unary_astnode();
								temp->op = "TO_FLOAT";
								temp->a = static_cast<exp_astnode*>(exp_list[i]);
								(exp_list[i]) = static_cast<exp_astnode*>(temp);
							}
							else
							{
									error(@1,"Expected " + types[i] + " but argument is of type "+$3.e_list[i].type);
							}
						}
						else if(types[i] == "int")
							{
								if($3.e_list[i].type == "float")
								{
									
									op_unary_astnode* temp = new op_unary_astnode();
									temp->op = "TO_INT";
									temp->a = static_cast<exp_astnode*>(exp_list[i]);
									(exp_list[i]) = static_cast<exp_astnode*>(temp);
								}
								else
								{
									error(@1,"Expected " + types[i] + " but argument is of type "+$3.e_list[i].type);
								}
							}
						else if(types[i] == "void*" && $3.e_list[i].is_ptr())
						{
							//need to handle when func ret type is ptr and void* ret
						}
						else
						{
							error(@1,"incompatible argument type" + types[i] + " and " + $3.e_list[i].type);
						}
					}
				}
			}

		}
		identifier_astnode* temp = new identifier_astnode();
		temp->id = $1;
		static_cast<funcall_astnode*>($$.node)->id = temp;
		
		static_cast<funcall_astnode*>($$.node)->arguments = exp_list;
		exp_list.clear();
		$$.is_lvalue = false;
	}

	| postfix_expression '.' IDENTIFIER 
	{
		
		$$.node = new member_astnode();
		SymbTab* temp_st = new SymbTab();
		if(gst.Entries.find($1.type) == gst.Entries.end())
		{
			//&& varfun == struct?
			//Incorrect scope, handle
			error(@1,"lhs is not a valid struct");
		}
		else
		{
			
			temp_st = gst.Entries[$1.type].symbtab;
			if(temp_st->Entries.find($3) == temp_st->Entries.end())
			{
				//Incorrect scope, handle
				error(@1,"no member named this");
			}
			else
			{
				
				$$.type = temp_st->Entries[$3].type;
				static_cast<member_astnode*>($$.node)->type = $$.type;

			}
		} 
		static_cast<member_astnode*>($$.node)->structt = static_cast<exp_astnode*>($1.node);
		identifier_astnode* temp = new identifier_astnode();
		temp->id = $3;
		static_cast<member_astnode*>($$.node)->field = temp;
		$$.is_lvalue = $1.is_lvalue;
	}

	| postfix_expression PTR_OP IDENTIFIER 
	{
		$$.node = new arrow_astnode();
		SymbTab* temp_st = new SymbTab();
		string type2 = $1.type;

		size_t pos_start = type2.rfind("[");
		size_t pos_end = type2.rfind("]");
		size_t pos_star = type2.find("*");
		if(pos_start!=pos_end)
		{
			type2.erase(pos_start,pos_end-pos_start+1);
			
		}
		else if(pos_star!=string::npos)
		{
			type2.erase(pos_star,1);
		}
		else
		{
			error(@1,"Left operand of -> is not a pointer to structure");
		}

	


		if(gst.Entries.find(type2) == gst.Entries.end())
		{
			//&& varfun == struct?
			//Incorrect scope, handle
			error(@1,"Left operand of -> is not a pointer to structure");
		}
		else
		{
			temp_st = gst.Entries[type2].symbtab;
			if(temp_st->Entries.find($3) == temp_st->Entries.end())
			{
				//Incorrect scope, handle
				error(@1, type2 + " has no member named  " + $3 );
			}
			else
			{
				$$.type = temp_st->Entries[$3].type;
				static_cast<arrow_astnode*>($$.node)->type = $$.type;

			}
		}
		static_cast<arrow_astnode*>($$.node)->pointerr = static_cast<exp_astnode*>($1.node);
		identifier_astnode* temp = new identifier_astnode();
		temp->id = $3;
		static_cast<arrow_astnode*>($$.node)->field = temp;
		$$.is_lvalue = $1.is_lvalue;
	}

	| postfix_expression INC_OP 
	{
		
		$$.node = new op_unary_astnode();
		if($1.is_lvalue)
		{
			$$.type = $1.type;
			static_cast<op_unary_astnode*>($$.node)->type = $$.type;
 
		}
		else
		{
			error(@1,"Operand of ++ should have a lvalue");
		}
		
		if($1.type == "int" || $1.type == "float" || $1.is_ptr()) {

		}		
		else {
			error(@1, "postifx increment can be done only on int, float or pointer");
		}
		static_cast<op_unary_astnode*>($$.node)->op = "PP";
		static_cast<op_unary_astnode*>($$.node)->a = static_cast<exp_astnode*>($1.node);
		
		$$.is_lvalue = false;
	}
	;

primary_expression:
	IDENTIFIER 
	{
		$$.node = new identifier_astnode();
		if(mera_st->Entries.find($1) == mera_st->Entries.end())
		{
			//Incorrect scope, handle
			error(@1,"variable " + $1 + " not found");
		}
		else
		{
			$$.type = mera_st->Entries[$1].type;
			static_cast<identifier_astnode*>($$.node)->type = $$.type;

		}

		static_cast<identifier_astnode*>($$.node)->id = $1;
		$$.is_lvalue = true;
	}

	| INT_CONSTANT 
	{
		$$.node = new intconst_astnode();
		$$.type = "int";
		static_cast<intconst_astnode*>($$.node)->type = $$.type;

		if(stoi($1)==0) $$.is_zero = true;
		static_cast<intconst_astnode*>($$.node)->a = stoi($1);
		$$.is_lvalue = false;
		

		
	}

	| FLOAT_CONSTANT 
	{
		$$.node = new floatconst_astnode();
		$$.type = "float";
		static_cast<floatconst_astnode*>($$.node)->f = stof($1);
		$$.is_lvalue = false;
	}

	| STRING_LITERAL 
	{
		$$.node = new stringconst_astnode();
		$$.type = "string";
		static_cast<stringconst_astnode*>($$.node)->s = $1;
		$$.is_lvalue = false;
	}

	| '(' expression ')' 
	{
		$$.node = $2.node;
		$$.type = $2.type;
		$$.is_lvalue = $2.is_lvalue;
	}

	;

expression_list:
	expression 
	{
		exp_list.push_back(static_cast<exp_astnode*>($1.node));
		$$.e_list.push_back($1);
	}

	| expression_list ',' expression 
	{
		exp_list.push_back(static_cast<exp_astnode*>($3.node));
		$$.e_list = $1.e_list;
		$$.e_list.push_back($3);
	}

	;

unary_operator:
	'-' 
	{
		$$.name = "UMINUS";
		$$.is_lvalue = false;

	}

	| '!' 
	{
		$$.name = "NOT";
		$$.is_lvalue = false;
	}

	| '&' 
	{
		$$.name = "ADDRESS";
		$$.is_lvalue = false;
	}

	| '*' 
	{
		$$.name = "DEREF";
		$$.is_lvalue = true;
	}

	;

selection_statement:
	IF '(' expression ')' statement ELSE statement 
	{
		$$.node = new if_astnode();
		static_cast<if_astnode*>($$.node)->condition = static_cast<exp_astnode*>($3.node);
		static_cast<if_astnode*>($$.node)->then_stmt = static_cast<statement_astnode*>($5.node);
		static_cast<if_astnode*>($$.node)->else_stmt = static_cast<statement_astnode*>($7.node);
		//$$.node->gencode(code_label_count);

	}

	;

iteration_statement:
	WHILE '(' expression ')' statement 
	{
		$$.node = new while_astnode();
		static_cast<while_astnode*>($$.node)->condition = static_cast<exp_astnode*>($3.node);
		static_cast<while_astnode*>($$.node)->body =static_cast<statement_astnode*>($5.node);
	}

	| FOR '(' assignment_expression ';' expression ';' assignment_expression ')' statement 
	{
		$$.node = new for_astnode();
		static_cast<for_astnode*>($$.node)->init = static_cast<exp_astnode*>($3.node);
		static_cast<for_astnode*>($$.node)->guard =static_cast<exp_astnode*>($5.node);
		static_cast<for_astnode*>($$.node)->step = static_cast<exp_astnode*>($7.node);
		static_cast<for_astnode*>($$.node)->body = static_cast<statement_astnode*>($9.node);
	}

	;

declaration_list:
	declaration 
	{
		$$.node = new statement_astnode();
		$$.size = $1.size;
		$$.is_lvalue = true;
	}

	| declaration_list declaration 
	{
		$$.node = $2.node;
		$$.size = $1.size + $2.size;
		$$.is_lvalue = true;
	}

	;

declaration:
	type_specifier declarator_list ';' 
	{
		
		
		unsigned int vecSize = var_list.size();
		int total_size = 0;
		for (unsigned int var=0;var< vecSize;var++){
			entry* e = new entry();
			// cout<<"Name assigned"<<endl;
			e->name = var_list[var].name;
			//cout<<"Name assigned"<<endl;
			e->varfun = "var";
			e->scope = "local";
			//cout<<var_list[var].size<<endl;

			e->type = $1.type + var_list[var].type;
			if(e->type.find("void")!=string::npos)
			{
				if(e->type.find("*") == string::npos)
					error(@1,"can't declare the variable of void");
			}

			if((e->type.find("struct") != string::npos) && (e->type.find("*")!= string::npos))
			{
				e->size = 4 * var_list[var].size;
			}
			else
			{
				e->size = $1.size * var_list[var].size;
			}
			total_size += e->size;
			if(offset_multiplier == 1)
			{
				// // cout<<"heree at om 1"<<endl;
				e->offset = curr_offset;
				curr_offset +=  e->size;
			}
			else
			{
				curr_offset -= e->size;
				e->offset = curr_offset;
			}
			//cout<<"After all assigning"<<endl;
			e->symbtab = nullptr;
			//cout<<mera_st<<endl;
			if(mera_st->Entries.find(e->name) != mera_st->Entries.end())
			{
				cout<<"inside ewrror";
				error(@1,"\"" + e->name +"\" has a previous declaration");
			}
			mera_st->Entries.insert({e->name,*e});
			//// cout<<"hereee"<<endl;
		}
		$$.size = total_size;
		text = text + "\tsubl\t$" + to_string(total_size)+",%esp\n";

		var_list.clear();
		$$.is_lvalue = true;
	}

	;

declarator_list:
	declarator 
	{
		// cout<<"in declarator";
		var_list.push_back($1);
		$$.is_lvalue = true;
		// cout<<"end of declarator";
	}

	| declarator_list ',' declarator 
	{
		var_list.push_back($3);
		$$.is_lvalue = true;
	}
	;


%%
void IPL::Parser::error( const location_type &l, const std::string &err_message )
{
   std::cout << "Error at line " << l.end.line <<": "<< err_message<<"\n";
   exit(1);
};