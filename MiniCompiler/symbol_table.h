#include "scope_table.h"    // contains the hash table implementation for one scope.
#include <fstream>          // used for file output (ofstream).
using namespace std;        // namespace std is used to avoid writing std:: before every standard library function.
extern ofstream outlog;

class symbol_table          // This class represents the entire symbol table, containing multiple scope tables.
{
private:
    scope_table *current_scope;    // pointer to the current scope table.
    int bucket_count;              // number of buckets in the hash table.
    int current_scope_id;          // unique ID for the current scope.

public:
    symbol_table(int bucket_count){
        this->bucket_count = bucket_count;
        this->current_scope = NULL;
        this->current_scope_id = 1;
    }

    ~symbol_table(){
        while (current_scope != NULL)
        {
            exit_scope(); // When the symbol table is destroyed: delete all scopes It repeatedly calls exit_scope() until no scopes remain.
        }
    }

    

    void enter_scope(){
        scope_table *temp = new scope_table(bucket_count, current_scope_id, current_scope); // Create a New Scope Table
        current_scope = temp;       // Make It the Current Scope
        current_scope_id++;         // Increment the Scope ID
        
        if (outlog.is_open())
            outlog << "New ScopeTable with ID " << current_scope->get_unique_id() << " created" << endl << endl;
    }

    void exit_scope(){
       if(current_scope != NULL){                                   // If there is a current scope, delete it.
            int id = current_scope->get_unique_id();
            scope_table *temp = current_scope;                      // Store the current scope in a temporary variable.
            current_scope = current_scope->get_parent_scope();      // Make the parent scope the current scope.
            delete temp;                                            // Delete the temporary variable.

            if (outlog.is_open())
                outlog << "Scopetable with ID " << id << " removed" << endl << endl;
       }
       else{
           return; // If there is no current scope, do nothing.
       }
    }

    bool insert(symbol_info* symbol){                   // Insert a symbol into the current scope.
        if(current_scope == NULL){
            return false;                               // If there is no current scope, return false.
        }
        return current_scope->insert_in_scope(symbol);  // Insert the symbol into the current scope.
    }

    symbol_info* lookup(symbol_info* symbol){       // Look up a symbol in the current scope.
        scope_table *temp = current_scope;          // Store the current scope in a temporary variable.
        while (temp != NULL)
        {
            symbol_info *symbol_info_pointer = temp->lookup_in_scope(symbol);   // Look up the symbol in the current scope.
            if(symbol_info_pointer != NULL){
                return symbol_info_pointer;                                     // If the symbol is found, return a pointer to the symbol_info object.
            }
            temp = temp->get_parent_scope();                                    // Make the parent scope the current scope.
        }
        return NULL;                                                            // If the symbol is not found, return NULL.
    }

    bool remove(symbol_info* symbol){                       // Remove a symbol from the current scope.
        if(current_scope == NULL){
            return false;                                   // If there is no current scope, return false.
        }
        return current_scope->delete_from_scope(symbol);    // Remove the symbol from the current scope.
    }

    void print_current_scope(ofstream &outlog){         // Print the current scope.
        outlog<<"------------------"<<endl<<endl;

        if (current_scope != NULL)
            current_scope->print_scope_table(outlog);
        scope_table *temp = current_scope ? current_scope->get_parent_scope() : NULL;
        while (temp != NULL)
        {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }
        outlog<<"--------------------"<<endl<<endl;
    }

    void print_all_scopes(ofstream &outlog){        // Print all scopes.
        outlog<<"------------------"<<endl<<endl;
        scope_table *temp = current_scope;          // Store the current scope in a temporary variable.
        while (temp != NULL)
        {
            temp->print_scope_table(outlog);        // Print the current scope.
            temp = temp->get_parent_scope();        // Make the parent scope the current scope.
        }
        outlog<<"--------------------"<<endl<<endl; // Print the end of the scopes.     
    }

    
};

