#include "symbol_info.h"
#include <vector>
#include <list>
#include <string>
#include <fstream>
#include <iostream>
using namespace std;

class scope_table                       // This class represents a single scope in the symbol table.
{
private:
    int bucket_count;                   //Number of index
    int unique_id;                      //Each scope has a unique ID.
    scope_table *parent_scope = NULL;   // Parent Scope Pointer
    vector<list<symbol_info *>> table;  // Hash Table. implements the hash table where each bucket 
                                        // contains a list of symbol entries to handle collisions.

    int hash_function(string name)
    {
        int p = 31;
        int m = 1e9 + 9;
        long long hash = 0, power = 1;

        for (char c : name) {
            hash = (hash + (c - 'a' + 1) * power) % m;
            power = (power * p) % m;
        }
        return hash % bucket_count;
    }

public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);

    scope_table *get_parent_scope()  // It returns a pointer to the parent scope table.
    {
        return parent_scope;
    }

    int get_unique_id()             // Get the unique ID of the current scope.
    {
        return unique_id;
    }
    
    //lookup
    symbol_info *lookup_in_scope(symbol_info* symbol)   // A pointer to a symbol_info object
    {
    string name = symbol->get_name();                   // Get the name of the symbol. Every symbol has a name (like "a", "func", "b")

    int index = hash_function(symbol->get_name());      // Get the index of the symbol in the hash table.

    for(auto *symbol_info_pointer : table[index])
    {
        if(symbol_info_pointer->get_name() == name)
        {
            return symbol_info_pointer;                 // If the symbol is found, return a pointer to the symbol_info object.
        }
    }
    return NULL;                                        // If the symbol is not found, return NULL.    
    }


    //insert
    bool insert_in_scope(symbol_info* symbol)
    {
        string name = symbol->get_name();
        int index = hash_function(name);

        // auto = “compiler, figure out the type for me automatically.”
        for(auto *symbol_info_pointer : table[index])       // table[index] gives the list at this hash bucket.
        {                                                   // symbol_info_pointer will iterate over each symbol pointer in that list.
            if(symbol_info_pointer->get_name() == name)
            {
                return false;   // insertion failed
            }
        }
        table[index].push_back(symbol);
        return true;            // insert successful
    }

    
    // This function removes a symbol from the current scope table if it exists, and frees its memory.
    bool delete_from_scope(symbol_info* symbol)
    {
        
        string name = symbol->get_name();
        int index = hash_function(name);
        for(auto iterate = table[index].begin(); iterate != table[index].end();)
        // .begin() → returns an iterator pointing to the first element
        // .end() points after the last element. So the loop runs until iterator reaches end.
        {
            if((*iterate)->get_name() == name)
            {
                delete *iterate;                            // frees the memory of the symbol object.
                iterate = table[index].erase(iterate);      // removes the element from the list.
                return true;                                // deletion successful.
          
            }
            else
            {
                ++iterate;          // If the name doesn’t match, just move to the next symbol in the list.
            }
        }
        return false;               //not found
        
    } 
 

    void print_scope_table(ofstream& outlog)                    // ofstream& outlog → a reference to a file output stream.
    {
        outlog << "ScopeTable # "<< unique_id << '\n';          // Print the scope ID

        for (int index = 0; index < bucket_count; index++)
        {
            if(table[index].empty())  // Skip empty buckets
            {
                continue;
            }
            outlog << index << "--> \n";

            for(auto *symbol_info_pointer : table[index])
            {
                if (symbol_info_pointer == NULL) continue;
                outlog << "< " << symbol_info_pointer->get_name() << " : ID >\n";
                string id_name = symbol_info_pointer->get_identifier_name();
                if (id_name == "Function Definition")
                {
                    outlog << "Function Definition\n";
                    outlog << "Return Type: " << symbol_info_pointer->get_identifier_type() << "\n";
                    vector<string> params = symbol_info_pointer->get_parameters();
                    outlog << "Number of Parameters: " << params.size() << "\n";
                    string details;
                    for (int i = 0; i < (int)params.size(); i++)
                    {
                        if (i > 0) details += ", ";
                        details += params[i];
                    }
                    outlog << "Parameter Details: " << details << "\n";
                }
                else if (id_name == "Array")
                {
                    outlog << "Array\n";
                    outlog << "Type: " << symbol_info_pointer->get_identifier_type() << "\n";
                    outlog << "Size: " << symbol_info_pointer->get_array_size() << "\n";
                }
                else
                {
                    outlog << "Variable\n";
                    outlog << "Type: " << symbol_info_pointer->get_identifier_type() << "\n";
                }
                outlog << "\n";
            }
        }
        outlog << "\n";
    }

    // ~scope_table() is the destructor of the class scope_table.
    // A destructor is automatically called when an object is deleted or goes out of scope.
    ~scope_table()
    {
        for(int index = 0; index < bucket_count && index < (int)table.size(); index++)
        {
            for(symbol_info *sym : table[index]) // sym is a pointer to a symbol_info object.
            {
                if (sym != NULL) delete sym;
            }
        }
    }

};



// ClassName :: functionName()
scope_table ::scope_table() // Default Constructor
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
    table.resize(bucket_count); // Remember this variable: vector<list<symbol_info *>> table;
                                // This is the hash table. If bucket_count = 10
                                //Then table.resize(10) creates 10 buckets.
}
