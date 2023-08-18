
#include <vector>
#include<iostream>
#include <string>
#include <map>
#include<algorithm>
#ifndef SYMBTAB_HH
#define SYMBTAB_HH
using namespace std;
class entry;
class SymbTab;

class entry{
    public:

    string name;
    string varfun;
    string scope;
    int size;
    int offset;
    string type;
    SymbTab* symbtab;
};
class SymbTab {
public:
    SymbTab(){};

    map<string,entry> Entries;
    void printgst();
    void print();
    // static bool cmp(pair<string,entry>,pair<string,entry>);
    vector<string> sort1();
};

#endif