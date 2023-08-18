#include "symbtab.hh"

bool cmp(pair<string,entry> e1,pair<string,entry> e2)
{
    return e1.second.offset > e2.second.offset;
}

void SymbTab::print(){
    cout<<"["<<endl;
    for(auto e = Entries.begin(); e!=Entries.end(); ++e){
        cout<<"[";
        cout<<"\t\""<<e->second.name<<"\",";
        cout<<"\t\""<<e->second.varfun<<"\",";
        cout<<"\t\""<<e->second.scope<<"\",";
        cout<<"\t"<<e->second.size<<",";
        if(e->second.varfun!="struct")
            cout<<"\t"<<e->second.offset<<",";
        else
            cout<<"\t"<<"\"-\""<<",";
        cout<<"\t\""<<e->second.type<<"\"";
        cout<<endl;
        cout<<"]";
        if(next(e,1)!=Entries.end())
        {
            cout<<",";
        }
        cout<<endl;
    }
    cout<<"]"<<endl;
}


void SymbTab::printgst(){
    cout<<"[";
    for(auto e = Entries.begin(); e!=Entries.end(); ++e){
        cout<<"[";
        cout<<"\t\""<<e->second.name<<"\",";
        cout<<"\t\""<<e->second.varfun<<"\",";
        cout<<"\t\""<<e->second.scope<<"\",";
        cout<<"\t"<<e->second.size<<",";
        if(e->second.varfun!="struct")
            cout<<"\t"<<e->second.offset<<",";
        else
            cout<<"\t"<<"\"-\""<<",";
        cout<<"\t\""<<e->second.type<<"\"";
        cout<<endl;
        cout<<"]";
        if(next(e,1)!=Entries.end())
        {
            cout<<",";
        }
        cout<<endl;
    }
    cout<<"]"<<endl;
}



vector<string> SymbTab::sort1()
{
    vector<pair<string,entry>> A;
    for(auto &it: Entries)
    {
        if(it.second.scope=="param")
            A.push_back(it);
    }
    sort(A.begin(),A.end(),cmp);
    vector<string> types;
    for(auto &it: A)
    {
        types.push_back(it.second.type);
    }
    return types;

    
}