
#include "scanner.hh"
#include "parser.tab.hh"
#include "ast.hh"
#include <fstream>
#include<string>
#include<stack>
using namespace std;

SymbTab gst, gstfun, gststruct; 
string filename;
stack<string> rstack;
string rodata = "	.section	.rodata\n";
string text = "\t.text\n";
int total_regs = 4;
int Llabel = 0;
map<string,string> op_instr = {
	{"PLUS_INT","addl"},
	{"MULT_INT","imull"},
	{"MINUS_INT","subl"},
	{"GE_OP_INT","setge"},
	{"LE_OP_INT","setle"},
	{"GT_OP_INT","setg"},
	{"LT_OP_INT","setl"},
	{"EQ_OP_INT","sete"},
	{"NE_OP_INT","setne"}
};
extern std::map<string,abstract_astnode*> ast;
// std::map<std::string, datatype> predefined {
//             {"printf", createtype(VOID_TYPE)},
//             {"scanf", createtype(VOID_TYPE)},
//             {"mod", createtype(INT_TYPE)}
//         };

void get_loc(exp_astnode* e)
{
	// cout<< "here3"<<endl;
	if(e->astnode_type==identifier_type)
	{
		// cout<< "here4"<<endl;

		identifier_astnode* a = (identifier_astnode*) e;
		int offset = mera_st->Entries[a->id].offset;
		
		// cout<< "here5  "<<a->id<<endl;
		text = text + "\tleal\t" + to_string(offset) + "(%ebp), " + rstack.top() + "\n";
		// cout<< "here5"<<endl;

	}
	else if(e->astnode_type==member_type)
	{
		// cout<< "here3"<<endl;

		member_astnode* m = dynamic_cast<member_astnode*> (e);
		exp_astnode* structt = m->structt;
		string id = m->field->id;
		string type = structt->type;

		get_loc(structt);
		// cout<< "here360  "<<type<<"sad"<<id<<endl;

		int offset = gst.Entries[type].symbtab->Entries[id].offset;
		// cout<< "here363"<<endl;

		text = text + "\tleal\t" + to_string(offset) + "("+rstack.top()+"),  " + rstack.top()+"\n";
		
	}
	else if(e->astnode_type==op_unary_type)
	{
		op_unary_astnode* unar = (op_unary_astnode*) e;
		identifier_astnode* id = (identifier_astnode*)unar->a;
		int offset = mera_st->Entries[id->id].offset;
		
		// cout<< "here5  "<<a->id<<endl;
		text = text + "\tleal\t" + to_string(offset) + "(%ebp), " + rstack.top() + "\n";
		text = text + "\tmovl\t(" + rstack.top() + "),\t" + rstack.top() + "\n";
		
		// cout<< "here5"<<endl;
	}
	else if(e->astnode_type == arrow_type)
	{
		arrow_astnode* a = (arrow_astnode*) e;
		exp_astnode* point = a->pointerr;
		string id = a->field->id;
		string type = point->type;
		point->gencode();
		type.erase(type.find("*"),1);
		int offset = gst.Entries[type].symbtab->Entries[id].offset;
		text = text + "\taddl\t$"+to_string(offset)+",  "+rstack.top()+"\n";
		//khatam karna hai
	}
}
int main(int argc, char **argv)
{
	rstack.push("%ecx");
	rstack.push("%ebx");
	rstack.push("%edx");
	rstack.push("%eax");


	fstream in_file, out_file;
	
	in_file.open(argv[1], ios::in);

	IPL::Scanner scanner(in_file);

	IPL::Parser parser(scanner);

#ifdef YYDEBUG
	parser.set_debug_level(1);
#endif
parser.parse();
// create gstfun with function entries only

for (const auto &entry : gst.Entries)
{
	if (entry.second.varfun == "fun")
	gstfun.Entries.insert({entry.first, entry.second});
}
// create gststruct with struct entries only

for (const auto &entry : gst.Entries)
{
	if (entry.second.varfun == "struct")
	gststruct.Entries.insert({entry.first, entry.second});
}
// start the JSON printing

// cout << "{\"globalST\": " << endl;
// gst.printgst();
// cout << "," << endl;

// cout << "  \"structs\": [" << endl;
// for (auto it = gststruct.Entries.begin(); it != gststruct.Entries.end(); ++it)

// {   cout << "{" << endl;
// 	cout << "\"name\": " << "\"" << it->first << "\"," << endl;
// 	cout << "\"localST\": " << endl;
// 	it->second.symbtab->print();
// 	cout << "}" << endl;
// 	if (next(it,1) != gststruct.Entries.end()) 
// 	cout << "," << endl;
// }
// cout << "]," << endl;
// cout << "  \"functions\": [" << endl;

// for (auto it = gstfun.Entries.begin(); it != gstfun.Entries.end(); ++it)

// {
// 	cout << "{" << endl;
// 	cout << "\"name\": " << "\"" << it->first << "\"," << endl;
// 	cout << "\"localST\": " << endl;
// 	it->second.symbtab->print();
// 	cout << "," << endl;
// 	cout << "\"ast\": " << endl;
// 	// cout<<"debugging"<<ast.size()<<it->first<<ast[it->first]<<endl;
// 	ast[it->first]->print(0);
// 	cout << "}" << endl;
// 	if (next(it,1) != gstfun.Entries.end()) cout << "," << endl;
	
// }
// 	cout << "]" << endl;
// 	cout << "}" << endl;

	fclose(stdout);
}
// void printAst(const char *astname, const char *fmt...) // fmt is a format string that tells about the type of the arguments.
// {   
// 	typedef vector<abstract_astnode *>* pv;
// 	va_list args;
// 	va_start(args, fmt);
// 	if ((astname != NULL) && (astname[0] != '\0'))
// 	{
// 		cout << "{ ";
// 		cout << "\"" << astname << "\"" << ": ";
// 	}
// 	cout << "{" << endl;
// 	while (*fmt != '\0')
// 	{
// 		if (*fmt == 'a')
// 		{
// 			char * field = va_arg(args, char *);
// 			abstract_astnode *a = va_arg(args, abstract_astnode *);
// 			cout << "\"" << field << "\": " << endl;
			
// 			a->print(0);
// 		}
// 		else if (*fmt == 's')
// 		{
// 			char * field = va_arg(args, char *);
// 			char *str = va_arg(args, char *);
// 			cout << "\"" << field << "\": ";

// 			cout << str << endl;
// 		}
// 		else if (*fmt == 'i')
// 		{
// 			char * field = va_arg(args, char *);
// 			int i = va_arg(args, int);
// 			cout << "\"" << field << "\": ";

// 			cout << i;
// 		}
// 		else if (*fmt == 'f')
// 		{
// 			char * field = va_arg(args, char *);
// 			double f = va_arg(args, double);
// 			cout << "\"" << field << "\": ";
// 			cout << f;
// 		}
// 		else if (*fmt == 'l')
// 		{
// 			char * field = va_arg(args, char *);
// 			pv f =  va_arg(args, pv);
// 			cout << "\"" << field << "\": ";
// 			cout << "[" << endl;
// 			for (int i = 0; i < (int)f->size(); ++i)
// 			{
// 				(*f)[i]->print(0);
// 				if (i < (int)f->size() - 1)
// 					cout << "," << endl;
// 				else
// 					cout << endl;
// 			}
// 			cout << endl;
// 			cout << "]" << endl;
// 		}
// 		++fmt;
// 		if (*fmt != '\0')
// 			cout << "," << endl;
// 	}
// 	cout << "}" << endl;
// 	if ((astname != NULL) && (astname[0] != '\0'))
// 		cout << "}" << endl;
// 	va_end(args);
// }

