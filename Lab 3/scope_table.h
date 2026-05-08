#include "symbol_info.h"
#include <vector>
#include <list>
#include <string>
#include <fstream>
#include <iostream>
using namespace std;

class scope_table
{
private:
    int bucket_count; //hash table a koto gulo index ase
    int unique_id; //hash table ar unique id represent korte hobe
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        unsigned long long hash = 5381;
        for (unsigned char c : name) {
            hash = ((hash << 5) + hash) + c;
        }
        return (int)(hash % (unsigned long long)bucket_count);
    }

public:
    scope_table(); //default constructor empty scope table generate kore disse 
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope() //current scope table theke parent scope table a jabo
    {
    return parent_scope;
    }
    int get_unique_id()
    {
    return unique_id;
    }
    
    //lookup
    symbol_info *lookup_in_scope(symbol_info* symbol) //symbol info onject ar pointer symbol
    {
    string name = symbol->get_name();

    int index = hash_function(symbol->get_name());

    for(auto *symbol_info_pointer : table[index])
    {
        if(symbol_info_pointer->get_name() == name)
        {
            return symbol_info_pointer;
        }
    }
    return NULL;
    }


    //insert
    bool insert_in_scope(symbol_info* symbol)
    {
        string name = symbol->get_name();
        int index = hash_function(name);

        for(auto *symbol_info_pointer : table[index])
        {
            if(symbol_info_pointer->get_name() == name)
            {
                return false; //insertion failed
            }
        }
        table[index].push_back(symbol);
        return true; //insert successful 
        

    }


    //delete
    bool delete_from_scope(symbol_info* symbol)
    {
        
        string name = symbol->get_name();
        int index = hash_function(name);
        for(auto iterate = table[index].begin(); iterate != table[index].end();)
        {
            if((*iterate)->get_name() == name)
            {
                delete *iterate; //free the memory
                iterate = table[index].erase(iterate); //erase from the list
                return true;
          
            }
            else
            {
                ++iterate;
            }
        }
        return false; //not found
        
    } 


//for uniqueness checking multiple declarations in same scope
    symbol_info* lookup_in_scope_by_name(const string& name) {
        int index = hash_function(name);
        for (auto *sym : table[index]) { //iterate through all symbols in hash bucket
            if (sym->get_name() == name) {
                return sym;
            }
        }


        return NULL;
}


    //more work needs to be done
    void print_scope_table(ofstream& outlog)
    {
        outlog << "ScopeTable # "<< unique_id << '\n'; 

        for (int index = 0; index < bucket_count; index++)
        {
            if(table[index].empty())
            {
                continue;
            }
            outlog << index << "--> \n";

            for(auto *symbol_info_pointer :table[index])
            {
                outlog << "<" <<symbol_info_pointer->get_name() << ":" << symbol_info_pointer->get_type() << ">\n";

            }
            outlog << "\n";
        } 

    }

    // destructor
    ~scope_table()
    {
        for(int index = 0; index<bucket_count; index++)
        {
            for(symbol_info *sym : table[index])
            {
                delete sym;
            }
        }
    }

    // you can add more methods if you need
};

// complete the methods of scope_table class

scope_table ::scope_table()
{
    bucket_count = 0;
    unique_id = 0;
    parent_scope = NULL;

}

scope_table :: scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
{
    this->bucket_count = bucket_count;
    this->unique_id = unique_id;
    this->parent_scope = parent_scope;
    table.resize(bucket_count);

}
