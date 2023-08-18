#include<iostream>
#include <vector>
#include<stack>
#include <string>
#include <map>
#include "symbtab.hh"
using namespace std;
#ifndef AST_H
#define AST_H

extern SymbTab* mera_st;
extern SymbTab gst;
extern string text;
extern string rodata;
extern stack<string>rstack;
extern int LC_count;
extern int total_regs;
extern map<string,string> op_instr;
extern int Llabel;
// extern vector<exp_astnode*>exp_list;

enum typeExp {
abstract_type,
statement_type,
exp_type,
empty_type,
seq_type,
assignS_type,
return_type,
if_type,
while_type,
for_type,
proccall_type,
ref_type,
op_binary_type,
op_unary_type,
assignE_type,
funcall_type,
intconst_type,
floatconst_type,
stringconst_type,
identifier_type,
arrayref_type,
member_type,
arrow_type
};





class abstract_astnode {
public:
    abstract_astnode()
    {
        this->astnode_type = abstract_type;
    }

    virtual void print(int blanks) = 0;
    enum typeExp astnode_type;
	virtual void gencode(){
		;
	}
		
	

};

class statement_astnode : public abstract_astnode {
public:
    statement_astnode()
	{
		this->astnode_type = statement_type;
	}

	void print(int blanks){

	}
	virtual void gencode()
	{
		// cout<<"statement ka call ho raha hai"<<endl;
	}
};

class exp_astnode : public abstract_astnode {
public:
    exp_astnode()
	{
		this->astnode_type = exp_type;
	}
	string type;
	int label_node;
	void print(int blanks){}
	virtual void gencode()
	{
		// cout<<"exp ka call ho raha hai"<<endl;
	}
};

extern void get_loc(exp_astnode* e);




class empty_astnode : public statement_astnode {
public:
    empty_astnode()
	{
		this->astnode_type = empty_type;
	}


	void print(int blanks){
		cout<<"\"empty\""<<endl;
	}
	void gencode()
	{
		// cout<<"empty ka call ho raha hai"<<endl;
	}
};

class seq_astnode : public statement_astnode {
public:
    seq_astnode()
	{
		this->astnode_type = seq_type;
	}

    vector<statement_astnode*> statements;
    
	void print(int blanks){
		cout<<"{\n\"seq\": ["<<endl;
		for(int i=0;i<statements.size();i++) {
			statements[i]->print(blanks);
			if(i!=statements.size()-1) {
			cout<<","<<endl;
			}
		}
		cout<<"\n\n]\n}"<<endl;
	}
	void gencode()
	{
		
		for(int i=0;i<statements.size();i++) {
			// cout<<"here"<<endl;
			statements[i]->gencode();
		}
	}
};
class ref_astnode : public exp_astnode {
public:
ref_astnode()
	{
		this->astnode_type = ref_type;
	}


	void print(int blanks){}
};
class identifier_astnode : public ref_astnode {
public:
identifier_astnode()
	{
		this->astnode_type = identifier_type;
	}

    string id;
	void print(int blanks){
		cout<<"{\n\"identifier\": \""<<id<<"\""<<endl;
		cout<<"}"<<endl;
	}
	void gencode()
	{
		int offset = mera_st->Entries[id].offset;
		text += "\tmovl\t" + to_string(offset)+"(%ebp),\t" + rstack.top() + "\n"; 
		
	}
};
class assignS_astnode : public statement_astnode {
public:
    assignS_astnode()
	{
		this->astnode_type = assignS_type;
	}


    exp_astnode *lhs;
    exp_astnode *rhs;

	void print(int blanks){
		cout<<"{ \"assignS\": {\n\"left\": "<<endl;
		lhs->print(blanks);
		cout<<",\n\"right\": "<<endl;
		rhs->print(blanks);
		cout<<"}\n}"<<endl;
	}
	void gencode()
	{
		// // cout<<"hereq"<<endl;
		// if(lhs->astnode_type==identifier_type)
		// {
		// 	// // cout<<"hereqadsa"<<endl;
		// 	// cout<<rhs->astnode_type<<endl;
		// 	identifier_astnode* a = (identifier_astnode*) lhs;
		// 	int offset = mera_st->Entries[a->id].offset;
		// 	rhs->gencode(mera_st);
		// 	text+="\tmovl\t" + rstack.top() + ",\t"+to_string(offset)+"(%ebp)\n";
		// }
		// else if(lhs->astnode_type==member_astnode)
		// {

		// }

		
		rhs->gencode();
		string R = rstack.top();
		rstack.pop();
		// cout<<"here2"<<endl;
		get_loc(lhs);
		text = text + "\tmovl\t" + R + ",\t(" + rstack.top() + ")\n";
		rstack.push(R);
		
		// cout<<"here2"<<endl;
	}
};

class return_astnode : public statement_astnode {
public:
return_astnode()
	{
		this->astnode_type = return_type;
	}


    exp_astnode *return_exp;

	void print(int blanks){
		cout<<"{\n\"return\": "<<endl;
		return_exp->print(blanks);
		cout<<"}"<<endl;
	}
	void gencode() {
		return_exp->gencode();
		// int total_func_size = 16+12;
		// for(const auto &[k,v] : mera_st->Entries)
		// {
		// 	if(v.scope=="param")
		// 	{
		// 		total_func_size += v.size;
		// 	}
		// }

		text = text + "\tmovl\t" + rstack.top() + ",\t" + "%eax\n";
	}
};

class if_astnode : public statement_astnode {
public:
if_astnode()
	{
		this->astnode_type = if_type;
	}


    exp_astnode *condition;
    statement_astnode *then_stmt;
    statement_astnode *else_stmt;
	void print(int blanks){
		cout<<"{ \"if\": {\n\"cond\": "<<endl;
		condition->print(blanks);
		cout<<",\n\"then\": "<<endl;
		then_stmt->print(blanks);
		cout<<",\n\"else\": "<<endl;
		else_stmt->print(blanks);
		cout<<"}\n}"<<endl;
	}

	void gencode(){
		int temp_label = Llabel;
		Llabel+=2;
		
		condition->gencode();
		
		text = text + "\tcmp $0, " + rstack.top() +"\n\tje .L"+to_string(temp_label+1)+ "\n";
	
		then_stmt->gencode();
		text = text + "\tjmp .L" + to_string(temp_label) + "\n.L" + to_string(temp_label+1)+":\n";
		else_stmt->gencode();
		
		text = text + ".L" + to_string(temp_label)+":\n";

		// count_code_label+=1;
	}
};

class while_astnode : public statement_astnode {
public:
while_astnode()
	{
		this->astnode_type = while_type;
	}


    exp_astnode *condition;
    statement_astnode *body;

	void print(int blanks){
		cout<<"{ \"while\": {\n\"cond\":"<<endl;
		condition->print(blanks);
		cout<<",\n\"stmt\":"<<endl;
		body->print(blanks);
		cout<<"}\n}"<<endl;

	}
	void gencode() {
		int temp_label = Llabel;
		text = text + "\tjmp .L" + to_string(temp_label)+"\n.L"+to_string(temp_label+1)+":\n";
		//cout<<body->astnode_type;
		Llabel+=2;
		body->gencode();
		text = text + ".L"+to_string(temp_label)+":\n"; 
		condition->gencode();
		text = text + "\tcmpl $0, "+ rstack.top() + "\n\tjne .L" + to_string(temp_label+1) + "\n";
		
	}
};
class for_astnode : public statement_astnode {
public:
for_astnode()
	{
		this->astnode_type = for_type;
	}


    exp_astnode *init;
    exp_astnode *guard;
    exp_astnode *step;
    statement_astnode *body;

	void print(int blanks){
		cout<<"{ \"for\": {\n\"init\": "<<endl;
		init->print(blanks);
		cout<<",\n\"guard\": "<<endl;
		guard->print(blanks);
		cout<<",\n\"step\": "<<endl;
		step->print(blanks);
		cout<<",\n\"body\": "<<endl;
		body->print(blanks);
		cout<<"}\n}"<<endl;
	}

	void gencode() {
		int temp = Llabel;
		Llabel+=2;
		init->gencode();

		text = text + "\tjmp .L" + to_string(temp)+"\n.L"+to_string(temp+1)+":\n";
		
		body->gencode();
		step->gencode();
		text = text + ".L"+to_string(temp)+":\n"; 
		guard->gencode();
		text = text + "\tcmpl $0, "+ rstack.top() + "\n\tjne .L" + to_string(temp+1) + "\n";
	}
};

class stringconst_astnode : public exp_astnode {
public:
stringconst_astnode()
	{
		this->astnode_type = stringconst_type;
	}

    string s;
	void print(int blanks){
		cout<<"{\n\"stringconst\": "<<s<<endl;
		cout<<"}"<<endl;
	}
	void gencode() {
	
	}

};

class proccall_astnode : public statement_astnode {
public:
proccall_astnode()
	{
		this->astnode_type = proccall_type;
	}
	
	identifier_astnode* fname;
    vector<exp_astnode*> arguments;
	void print(int blanks){
		cout<<"{ \"proccall\": {\n\"fname\": "<<endl;
		fname->print(blanks);
		cout<<",\n\"params\": ["<<endl;
		for(unsigned int i=0;i<arguments.size();i++)
		{
			arguments[i]->print(blanks);
			if(i!= (arguments.size()-1))
				cout<<",";
			cout<<endl;
		}
		cout<<"]"<<endl;
		
		cout<<"}\n}"<<endl;
	}
	void gencode() {
		
		if(static_cast<identifier_astnode*>(fname)->id == "printf") {
			rodata = rodata + ".LC"+to_string(LC_count)+":"+"\n\t.string "+static_cast<stringconst_astnode*>(arguments[arguments.size()-1])->s+"\n";
			if(arguments.size() != 1) {
				for(int i=arguments.size()-2;i>=0;i--) {
					arguments[i]->gencode();
					text = text + "\tpushl "+rstack.top()+"\n";
				}
			}

			text = text + "\t" + "pushl	$.LC" + to_string(LC_count) + "\n"+ "\tcall\tprintf\n\taddl\t$"+to_string((arguments.size()-1)*4+4)+", %esp\n";
			LC_count+=1;
		}
	else {
		string ret_type = gst.Entries[fname->id].type;
		// if(ret_type=="void")
		// {

		// }
		// else if(ret_type=="int")
		// {
		// 	text = text + "\tsubl\t$4,%esp\n"; //return value
		// }
		// else
		// {
		// 	int ret_size = gst.Entries[ret_type].size;
		// 	text = text + "\tsubl\t$"+to_string(ret_size)+",%esp\n"; //return value
		// }
		text = text + "\tpushl\t%eax\n\tpushl\t%edx\n\tpushl\t%ebx\n\tpushl\t%ecx\n"; //caller saved reg
		string n="";
		if(!rstack.empty()) {
			n = rstack.top();
		}
		
		if(rstack.empty())
		{
			rstack.push("%ecx");
			rstack.push("%ebx");
			rstack.push("%edx");
			rstack.push("%eax");
		}
		else if(rstack.top() == "%edx") {		
			rstack.push("%eax");
		}
		else if(rstack.top() == "%ebx") {
			rstack.push("%edx");
			rstack.push("%eax");
		}
		else if(rstack.top() == "%ecx") {
			rstack.push("%ebx");
			rstack.push("%edx");
			rstack.push("%eax");
		}

		else {
			rstack.push("%ecx");
			rstack.push("%ebx");
			rstack.push("%edx");
			rstack.push("%eax");
		}
		//full rstack
		for(int i=0;i<arguments.size();i++) {
			arguments[i]->gencode();	
	  		text = text + "\tpushl "+rstack.top()+"\n"; //arguments
		}
		text = text + "\tpushl $0\n";
		int total_func_size = 0;

		for(const auto &[k,v] : gst.Entries[fname->id].symbtab->Entries){
		
			if(v.scope=="param")
			{
				total_func_size += v.size;
			}
		}
		text =text + "\tcall\t" + fname->id + "\n"; // called func and removed args
		while(!rstack.empty())
		{
			rstack.pop();
		}
		if(ret_type=="void")
		{

		}
		else 
		{
			text += "\tpushl\t%eax\n";
			int tr = total_func_size + 4 + 4;
			text = text +"\tmovl\t" + to_string(tr)+ "(%esp),\t%ecx\n\t\tmovl\t" +to_string(tr+4) +"(%esp),\t%ebx\n\tmovl\t" + to_string(tr+8) + "(%esp),\t%edx\n\tmovl\t" + to_string(tr+12) + "(%esp),\t%eax\n";
			if(n == "%eax") {
			rstack.push("%ecx");
			rstack.push("%ebx");
			rstack.push("%edx");
			rstack.push("%eax");
		}
		else if(n == "%edx") {
			rstack.push("%ecx");
			rstack.push("%ebx");
			rstack.push("%edx");
		}
		else if(n == "%ebx") {
			rstack.push("%ecx");
			rstack.push("%ebx");
		}
		else {
			rstack.push("%ecx");			
		}
		text += "\tpopl\t"+rstack.top()+"\n";
		text+="\taddl\t$" + to_string(tr+12)+", %esp\n";
		}
		
		}


			
	}

};



class op_binary_astnode : public exp_astnode {
public:
op_binary_astnode()
	{
		this->astnode_type = op_binary_type;
	}

    string op;
    exp_astnode* a;
    exp_astnode* b;


	void print(int blanks){
		cout<<"{ \"op_binary\": {\n\"op\": \""<<op<<"\""<<endl;
		cout<<",\n\"left\": "<<endl;
		a->print(blanks);
		cout<<",\n\"right\": "<<endl;
		b->print(blanks);
		cout<<"}\n}"<<endl;
	}
	void gencode()
	{
		// if(a->label_node == 0)
		// {
		// 	if(a->astnode_type == identifier_astnode)
		// 	{
		// 		int offset = symbtab.Entries[a->id].offset;
		// 		cout<<"movl\t"<<offset<<"(%ebp),\t"<<rstack.top()<<endl;
		// 	}
		// 	else if(a->astnode_type == intconst_type)
		// 	{
		// 		cout<<"movl\t$"<<a->a<<",\t"<<rstack.top()<<endl;
		// 	}
		// }
		// if(b->label_node == 0)
		// {
		// 	a->gencode(mera_st);
		// 	if(op=="PLUS_INT" || op=="MULT_INT" || op=="MINUS_INT")
		// 	{
		// 		if(b->astnode_type == identifier_astnode)
		// 		{
		// 			int offset = symbtab.Entries[a->id].offset;
		// 			text = text + op_instr[op] + "\t" + to_string(offset) + "(%ebp),\t" + rstack.top() + "\n";
		// 		}
		// 		else if(b->astnode_type == intconst_type)
		// 		{
		// 			text = text + op_instr[op] + "\t$" + to_string(b->a) + ",\t" + rstack.top() + "\n";
		// 		} 
		// 	}
		// 	else if()
		// 	{

		// 	}
		// }
		int temp = Llabel;
		
		if(a->label_node >= b->label_node && b->label_node < total_regs)
		{
			if(op == "AND_OP"){
				Llabel+=2;
			}
			else if(op == "OR_OP") {
				Llabel+=3;
			}
			a->gencode();
			string R = rstack.top();
			rstack.pop();
			b->gencode();
			// cout<<op<<endl;
			if(op=="PLUS_INT" || op =="MULT_INT" || op=="MINUS_INT")
			{
				text = text + "\t" + op_instr[op] + "\t" + rstack.top() + ",\t" + R + "\n";
			}
			else if(op=="DIV_INT")
			{
				// See for store
				string R2 = rstack.top();
				rstack.pop();
				bool changed = false;
				if(R2=="%edx" || R2 == "%eax")
				{
					text = text + "\tmovl\t"+R2+",  %ecx\n";
					changed = true;
					
				}
				if(R!="%eax")
				{
					text = text + "\tpushl\t%eax\n"; 
					text = text + "\tmovl\t" + R + "\t,%eax\n";
				}
				// if(R2=="%edx")
				// {
				// 	text = text + "\tpushl\t%edx\n";
				// }
				text = text + "\tcltd\n";
				
				if(changed)
				{
					text = text + "\tidivl\t" + "%ecx" + "\n";

					text = text + "\tmovl\t%ecx,  "+R2+"\n";
					
				}
				else
				{
					text = text + "\tidivl\t" + R2 + "\n";
				}
				rstack.push(R2);
				if(R!="%eax")
				{
					text = text + "\tmovl\t%eax,\t" + R + "\n";
					text = text + "\tpopl\t%eax\n";
				}
				

			}
			else if(op=="GE_OP_INT" || op=="LE_OP_INT" || op=="NE_OP_INT" || op== "EQ_OP_INT" || op=="GT_OP_INT" || op=="LT_OP_INT")
			{
				// cout<<op<<endl;
				text = text + "\tcmpl\t" + rstack.top() + ",\t" + R + "\n";
				text = text + "\tpushl\t%eax\n";
				text = text + "\t"+op_instr[op] + "\t%al\n";
				text = text + "\tmovzbl\t%al,\t" + R + "\n";
				if(R=="%eax")
				{
					text = text + "\taddl\t$4,%esp\n";
				}
				else
				{
					text = text + "\tpopl\t%eax\n";
				}
			}
			else if(op=="AND_OP")
			{
				
				text += "\tcmpl\t$0,\t"+R+"\n";
				text += "\tje .L" + to_string(temp) + "\n";
				text += "\tcmpl\t$0,\t"+rstack.top()+"\n";
				text += "\tje .L" + to_string(temp) + "\n";
				text += "\tmovl\t$1,\t" + R + "\n";
				text += "\tjmp\t.L" + to_string(temp+1) + "\n";
				text += ".L"+to_string(temp)+":\n";
				text += "\tmovl\t$0,"+ R + "\n";
				text += ".L"+to_string(temp+1)+":\n";				
			}
			else if(op=="OR_OP")
			{
				
				text += "\tcmpl\t$0,\t"+R+"\n";
				text += "\tjne .L" + to_string(temp) + "\n";
				text += "\tcmpl\t$0,\t"+rstack.top()+"\n";
				text += "\tje .L" + to_string(temp+1) + "\n";
				text += ".L"+to_string(temp)+":\n";
				text += "\tmovl\t$1,\t" + R + "\n";
				text += "\tjmp\t.L" + to_string(temp+2) + "\n";
				text += ".L"+to_string(temp+1)+":\n";				
				text += "\tmovl\t$0,"+ R + "\n";
				text += ".L"+to_string(temp+2)+":\n";				
			}
			rstack.push(R);
		}
		else if( a->label_node < b->label_node && a->label_node < total_regs)
		{
			if(op == "AND_OP"){
				Llabel+=2;
			}
			else if(op == "OR_OP") {
				Llabel+=3;
			}
			string R1 = rstack.top();
			rstack.pop();
			swap(R1,rstack.top());
			rstack.push(R1);

			b->gencode();
			string R = rstack.top();
			rstack.pop();
			a->gencode();
			if(op=="PLUS_INT" || op =="MULT_INT" || op=="MINUS_INT")
			{
				text = text + "\t" + op_instr[op] + "\t" + R + ",\t" + rstack.top() + "\n";
			}
			else if(op=="DIV_INT")
			{
				// See for store
				string R2 = R;
				
				bool changed = false;
				if(R2=="%edx" || R2 == "%eax")
				{
					text = text + "\tmovl\t"+R2+",  %ecx\n";
					changed = true;
					
				}
				if(rstack.top()!="%eax")
				{
					text = text + "\tpushl\t%eax\n"; 
					text = text + "\tmovl\t" + rstack.top() + "\t,%eax\n";
				}
				// if(R2=="%edx")
				// {
				// 	text = text + "\tpushl\t%edx\n";
				// }
				text = text + "\tcltd\n";
				
				// if(R2=="%edx")
				// {
				// 	text = text + "\tpopl\t%edx\n";
				// }
				if(changed)
				{
					text = text + "\tidivl\t" + "%ecx" + "\n";

					text = text + "\tmovl\t%ecx,  "+R2+"\n";
					
				}
				else
				{
				text = text + "\tidivl\t" + R2 + "\n";
				}
				if(rstack.top()!="%eax")
				{
					text = text + "\tmovl\t%eax,\t" + rstack.top() + "\n";
					text = text + "\tpopl\t%eax\n";
				}
				

			}
			else if(op=="GE_OP_INT" || op=="LE_OP_INT" || op=="NE_OP_INT" || op== "EQ_OP_INT" || op=="GT_OP_INT" || op=="LT_OP_INT")
			{
				// cout<<op<<endl;
				text = text + "\tcmpl\t" + R + ",\t" + rstack.top() + "\n";
				text = text + "\tpushl\t%eax\n";
				text = text + "\t"+op_instr[op] + "\t%al\n";
				text = text + "\tmovzbl\t%al,\t" + rstack.top() + "\n"; 
				if(rstack.top()=="%eax")
				{
					text = text + "\taddl\t$4,%esp\n";
				}
				else
				{
					text = text + "\tpopl\t%eax\n";
				}
			}
			else if(op=="AND_OP")
			{
				
				text += "\tcmpl\t$0,\t"+rstack.top()+"\n";
				text += "\tje .L" + to_string(temp) + "\n";
				text += "\tcmpl\t$0,\t"+R+"\n";
				text += "\tje .L" + to_string(temp) + "\n";
				text += "\tmovl\t$1,\t" + rstack.top() + "\n";
				text += "\tjmp\t.L" + to_string(temp+1) + "\n";
				text += ".L"+to_string(temp)+":\n";
				text += "\tmovl\t$0,"+ rstack.top() + "\n";
				text += ".L"+to_string(temp+1)+":\n";				
			}
			else if(op=="OR_OP")
			{
				
				text += "\tcmpl\t$0,\t"+rstack.top()+"\n";
				text += "\tjne .L" + to_string(temp) + "\n";
				text += "\tcmpl\t$0,\t"+R+"\n";
				text += "\tje .L" + to_string(temp+1) + "\n";
				text += ".L"+to_string(temp)+":\n";
				text += "\tmovl\t$1,\t" + rstack.top() + "\n";
				text += "\tjmp\t.L" + to_string(temp+2) + "\n";
				text += ".L"+to_string(temp+1)+":\n";				
				text += "\tmovl\t$0,"+ rstack.top() + "\n";
				text += ".L"+to_string(temp+2)+":\n";				
			}
			rstack.push(R);

			R1 = rstack.top();
			rstack.pop();
			swap(R1,rstack.top());
			rstack.push(R1);
		}
		else if(b->label_node >= total_regs && a->label_node >= total_regs)
		{
			if(op == "AND_OP"){
				Llabel+=2;
			}
			else if(op == "OR_OP") {
				Llabel+=3;
			}
			b->gencode();
			text = text + "\tpushl\t"+rstack.top()+"\n";
			a->gencode();
			string R = rstack.top();
			rstack.pop();
			text = text + "\tpopl\t" + rstack.top()+"\n";
			if(op=="PLUS_INT" || op =="MULT_INT" || op=="MINUS_INT")
			{
				text = text + "\t" + op_instr[op] + "\t" + rstack.top() + ",\t" + R + "\n";
			}
			else if(op=="DIV_INT")
			{
				// See for store
				string R2 = rstack.top();
				rstack.pop();
				bool changed = false;
				if(R2=="%edx" || R2 == "%eax")
				{
					text = text + "\tmovl\t"+R2+",  %ecx\n";
					changed = true;
					
				}
				if(R!="%eax")
				{
					text = text + "\tpushl\t%eax\n"; 
					text = text + "\tmovl\t" + R + "\t,%eax\n";
				}
				// if(R2=="%edx")
				// {
				// 	text = text + "\tpushl\t%edx\n";
				// }
				text = text + "\tcltd\n";
				
				// if(R2=="%edx")
				// {
				// 	text = text + "\tpopl\t%edx\n";
				// }
				if(changed)
				{
					text = text + "\tidivl\t" + "%ecx" + "\n";

					text = text + "\tmovl\t%ecx,  "+R2+"\n";
					
				}
				else
				{
				text = text + "\tidivl\t" + R2 + "\n";
				}
				rstack.push(R2);
				if(R!="%eax")
				{
					text = text + "\tmovl\t%eax,\t" + R + "\n";
					text = text + "\tpopl\t%eax\n";
				}
				

			}
			else if(op=="GE_OP_INT" || op=="LE_OP_INT" || op=="NE_OP_INT" || op== "EQ_OP_INT" || op=="GT_OP_INT" || op=="LT_OP_INT")
			{
				// cout<<op<<endl;
				text = text + "\tcmpl\t" + rstack.top() + ",\t" + R + "\n";
				text = text + "\tpushl\t%eax\n";
				text = text + "\t"+op_instr[op] + "\t%al\n";
				text = text + "\tmovzbl\t%al,\t" + R + "\n";
				if(R=="%eax")
				{
					text = text + "\taddl\t$4,%esp\n";
				}
				else
				{
					text = text + "\tpopl\t%eax\n";
				} 
			}
			else if(op=="AND_OP")
			{
				int label_count = 1;
				text += "\tcmpl\t$0,\t"+R+"\n";
				text += "\tje .L" + to_string(temp) + "\n";
				text += "\tcmpl\t$0,\t"+rstack.top()+"\n";
				text += "\tje .L" + to_string(temp) + "\n";
				text += "\tmovl\t$1,\t" + R + "\n";
				text += "\tjmp\t.L" + to_string(temp+1) + "\n";
				text += ".L"+to_string(temp)+":\n";
				text += "\tmovl\t$0,"+ R + "\n";
				text += ".L"+to_string(temp+1)+":\n";				
			}
			else if(op=="OR_OP")
			{
				
				text += "\tcmpl\t$0,\t"+R+"\n";
				text += "\tjne .L" + to_string(temp) + "\n";
				text += "\tcmpl\t$0,\t"+rstack.top()+"\n";
				text += "\tje .L" + to_string(temp+1) + "\n";
				text += ".L"+to_string(temp)+":\n";
				text += "\tmovl\t$1,\t" + R + "\n";
				text += "\tjmp\t.L" + to_string(temp+2) + "\n";
				text += ".L"+to_string(temp+1)+":\n";				
				text += "\tmovl\t$0,"+ R + "\n";
				text += ".L"+to_string(temp+2)+":\n";				
			}
			rstack.push(R);
		}
		else
		{
			cout<<"Sethi ullman hag raha hai, sare cases dekh"<<endl;
		}

	}
};


class op_unary_astnode : public exp_astnode {
public:
op_unary_astnode()
	{
		this->astnode_type = op_unary_type;
	}

    string op;
    exp_astnode* a;

	void print(int blanks){
		cout<<" { \"op_unary\": {"<<endl;
		cout<<"\"op\": \""<<op<<"\"\n,\n\"child\":\n";
		a->print(blanks);
		cout<<"\n}\n}"<<endl;
	}

	void gencode()
	{
		
		if(op == "NOT")
		{
			a->gencode();
			text = text + "\ttestl\t"+rstack.top()+",  "+rstack.top()+"\n";
			text = text + "\tpushl\t%eax\n";
			text = text + "\tsete\t%al\n";
			text = text + "\tmovzbl\t%al,  "+rstack.top()+ "\n";
			if(rstack.top()=="%eax")
				{
					text = text + "\taddl\t$4,%esp\n";
				}
				else
				{
					text = text + "\tpopl\t%eax\n";
				}
		}
		else if(op=="UMINUS")
		{
			a->gencode();
			text = text + "\tnegl\t" + rstack.top()+"\n";
		}
		else if(op=="PP")
		{
			a->gencode();
			string R = rstack.top();
			text = text + "\tpushl\t" + R + "\n";
			text = text + "\taddl\t$1,  " + R +"\n";
			text = text + "\tpopl\t" + R + "\n";
			
		}
		else if(op=="ADDRESS")
		{
			get_loc(a);
		}
		else if(op=="DEREF")
		{
			get_loc(a);
			text = text + "\tmovl\t(" + rstack.top() + "),\t" + rstack.top() + "\n";
			text = text + "\tmovl\t(" + rstack.top() + "),\t" + rstack.top() + "\n";
		}
	}
};

class assignE_astnode : public exp_astnode {
public:
assignE_astnode()
	{
		this->astnode_type = assignE_type;
	}

    exp_astnode* lhs;
    exp_astnode* rhs;

	void print(int blanks){
		cout<<"{ \"assignE\": {\n\"left\": "<<endl;
		lhs->print(blanks);
		cout<<",\n\"right\": "<<endl;
		rhs->print(blanks);
		cout<<"}\n}"<<endl;
	}
	void gencode()
	{
		// if(lhs->astnode_type==identifier_type)
		// {
		// 	identifier_astnode* a = (identifier_astnode*) lhs;
		// 	int offset = mera_st->Entries[a->id].offset;
		// 	rhs->gencode(mera_st);
		// 	text+="\tmovl\t" + rstack.top() + ",\t"+to_string(offset)+"(%ebp)\n";
		// }
		
		rhs->gencode();
		string R = rstack.top();
		rstack.pop();
		// cout<<"here2"<<endl;
		get_loc(lhs);
		text = text + "\tmovl\t" + R + ",\t(" + rstack.top() + ")\n";
		rstack.push(R);

	}
};



class funcall_astnode : public exp_astnode {
public:
funcall_astnode()
	{
		this->astnode_type = funcall_type;
	}

    vector<exp_astnode*> arguments;
	identifier_astnode* id;

	void print(int blanks){
		cout<<"{ \"funcall\": {\n\"fname\": "<<endl;
		id->print(blanks);
		cout<<",\n\"params\": ["<<endl;
		for(int i=0;i<arguments.size();i++) {
			arguments[i]->print(blanks);
			if(i!=arguments.size()-1)
				cout<<",";
			cout<<endl;
		}
		cout<<endl;
		cout<<"]\n}\n}"<<endl;
	}
	void gencode() {
		
		{
		string ret_type = gst.Entries[id->id].type;
		// if(ret_type=="void")
		// {

		// }
		// else if(ret_type=="int")
		// {
		// 	text = text + "\tsubl\t$4,%esp\n"; //return value
		// }
		// else
		// {
		// 	int ret_size = gst.Entries[ret_type].size;
		// 	text = text + "\tsubl\t$"+to_string(ret_size)+",%esp\n"; //return value
		// }
		text = text + "\tpushl\t%eax\n\tpushl\t%edx\n\tpushl\t%ebx\n\tpushl\t%ecx\n"; //caller saved reg
		string n="";
		if(!rstack.empty()) {
			n = rstack.top();
		}
		
		if(rstack.empty())
		{
			rstack.push("%ecx");
			rstack.push("%ebx");
			rstack.push("%edx");
			rstack.push("%eax");
		}
		else if(rstack.top() == "%edx") {		
			rstack.push("%eax");
		}
		else if(rstack.top() == "%ebx") {
			rstack.push("%edx");
			rstack.push("%eax");
		}
		else if(rstack.top() == "%ecx") {
			rstack.push("%ebx");
			rstack.push("%edx");
			rstack.push("%eax");
		}

		else {
			rstack.push("%ecx");
			rstack.push("%ebx");
			rstack.push("%edx");
			rstack.push("%eax");
		}
		//full rstack
		for(int i=0;i<arguments.size();i++) {
			arguments[i]->gencode();	
	  		text = text + "\tpushl "+rstack.top()+"\n"; //arguments
		}
		text = text + "\tpushl $0\n";
		int total_func_size = 0;

		for(const auto &[k,v] : gst.Entries[id->id].symbtab->Entries)
		{
			if(v.scope=="param")
			{
				total_func_size += v.size;
			}
		}
		text =text + "\tcall\t" + id->id + "\n"; // called func and removed args
		while(!rstack.empty())
		{
			rstack.pop();
		}
		if(ret_type=="void")
		{

		}
		else 
		{
			text += "\tpushl\t%eax\n";
			int tr = total_func_size + 4 + 4;
			text = text +"\tmovl\t" + to_string(tr)+ "(%esp),\t%ecx\n\t\tmovl\t" +to_string(tr+4) +"(%esp),\t%ebx\n\tmovl\t" + to_string(tr+8) + "(%esp),\t%edx\n\tmovl\t" + to_string(tr+12) + "(%esp),\t%eax\n";
			if(n == "%eax") {
			rstack.push("%ecx");
			rstack.push("%ebx");
			rstack.push("%edx");
			rstack.push("%eax");
		}
		else if(n == "%edx") {
			rstack.push("%ecx");
			rstack.push("%ebx");
			rstack.push("%edx");
		}
		else if(n == "%ebx") {
			rstack.push("%ecx");
			rstack.push("%ebx");
		}
		else {
			rstack.push("%ecx");			
		}
		text += "\tpopl\t"+rstack.top()+"\n";
		text+="\taddl\t$" + to_string(tr+12)+", %esp\n";
		}
		
		

		// if(ret_type=="void")
		// {

		// }
		// else if(ret_type=="int")
		// {
		// 	text += "\tpopl\t"+rstack.top()+"\n";
		// }
		// else
		// {
		// 	int ret_size = gst.Entries[ret_type].size;
		// 	text = text + "\tsubl\t$"+to_string(ret_size)+",%esp\n"; //return value
		// }
	  	// //rstack reloaded to value
		// }
		// else {
		// 	for(int i=0;i<arguments.size();i++) {
		// 		arguments[i]->gencode(label_count);
		// 		text = text + "\tpushl "+rstack.top()+"\n";
		// 	}
		// 		text =text + "\tcall\t" + id->id + "\n\taddl\t$"+to_string(arguments.size()*4)+", %esp\n";
		//}

		}
			
	}
};

class intconst_astnode : public exp_astnode {
public:
intconst_astnode()
	{
		this->astnode_type = intconst_type;
	}

    int a;
	void print(int blanks){
		cout<<"{\n\"intconst\": "<<a<<"}"<<endl;
	}
	void gencode()
	{	
		

		// // cout<<"hereadaddcwdfve"<<endl;
		text = text + "\tmovl\t$" + to_string(a) + ",\t" + rstack.top() + "\n"; 
	}
};

class floatconst_astnode : public exp_astnode {
public:
floatconst_astnode()
	{
		this->astnode_type = floatconst_type;
	}

    float f;
	void print(int blanks){
		cout<<"{\n\"floatconst\": "<<f<<"}"<<endl;
		
	}
};





class arrayref_astnode : public ref_astnode {
public:
arrayref_astnode()
	{
		this->astnode_type = arrayref_type;
	}

    exp_astnode* array;
    exp_astnode* index;
	void print(int blanks){
		cout<<"{ \"arrayref\": {\n\"array\": "<<endl;
		array->print(blanks);
		cout<<",\n\"index\": "<<endl;
		index->print(blanks);
		cout<<"}\n}"<<endl;
	}
	void gencode() {
		;
	}
};

class member_astnode : public ref_astnode {
public:
member_astnode()
	{
		this->astnode_type = member_type;
	}

    exp_astnode* structt;
    identifier_astnode* field;
	void print(int blanks){
		cout<<"{ \"member\": {\n\"struct\": "<<endl;
		structt->print(blanks);
		cout<<",\n\"field\": "<<endl;
		field->print(blanks);
		cout<<"}\n}"<<endl;
	}
	void gencode(){
		
		get_loc(this);
		text = text + "\tmovl\t(" + rstack.top() + "),\t" + rstack.top() + "\n";
	}
};
class arrow_astnode : public ref_astnode {
public:
arrow_astnode()
	{
		this->astnode_type = arrow_type;
	}


    exp_astnode* pointerr;
    identifier_astnode* field;


	void print(int blanks){
		cout<<"{ \"arrow\": {\n\"pointer\": "<<endl;
		pointerr->print(blanks);
		cout<<",\n\"field\": "<<endl;
		field->print(blanks);
		cout<<"}\n}"<<endl;


	}
	void gencode() {
		pointerr->gencode();
		string type = pointerr->type;
		type.erase(type.find("*"),1);
		int offset = gst.Entries[type].symbtab->Entries[field->id].offset;
		text = text + "\taddl\t$"+to_string(offset)+",  "+rstack.top()+"\n";
		text = text + "\tmovl\t("+rstack.top()+"),  "+rstack.top()+"\n"; 		
	}
};



#endif