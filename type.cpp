#ifndef KUCH_CLASS
#define KUCH_CLASS
#include<string>
#include<vector>
#include<algorithm>


using namespace std;



class kuch_class{
    public:
    kuch_class(){
        node = new statement_astnode();
    };
    int size;
    string type;
    string name;
    abstract_astnode* node;
    vector<statement_astnode*>stat_list;
    vector<kuch_class> e_list;
    bool is_zero = false;
    bool is_lvalue = false;
    
    int is_ptr()//returns depth of pointer
    {
        int num_stars = count(type.begin(),type.end(),'*');
        int num_braks = count(type.begin(),type.end(),'[');
        return num_stars + num_braks;
    }
    bool is_int() {
        return type.find("int") == 0;
    }
    bool is_float() {
        return type.find("float") == 0 ;
    }
    bool is_void() {
        return type.find("void") == 0;
    }
    bool is_struct() {
        return type.find("struct") == 0;
    }
    string mtype()
    {
        size_t pos_start = type.find("[");
        size_t pos_end = type.find("]");
        size_t pos_star = type.rfind("*");;
        size_t pos_brac = type.find("(");
        string m_type = type;
        if(pos_brac!=string::npos)
        {
            ;
        }
        else if(pos_start!=pos_end)
        {
            
            m_type.erase(pos_start,pos_end-pos_start+1);
            m_type.insert(pos_start ,"(*)");
        }
        else if(pos_star!=string::npos)
        {
            m_type.erase(pos_star,1);
            m_type.insert(pos_star,"(*)");
        }
        else
        {
            ;
        }
        return m_type;
    }
};

#endif

