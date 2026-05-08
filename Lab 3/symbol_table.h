#include "scope_table.h"
#include <fstream>
using namespace std;

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:
    symbol_table(int bucket_count){
        this->bucket_count = bucket_count;
        this->current_scope = NULL;
        this->current_scope_id = 0;
    }

    ~symbol_table(){
        while (current_scope != NULL)
        {
            exit_scope();
        }
    }
    void enter_scope(){
        scope_table *temp = new scope_table(bucket_count, current_scope_id, current_scope);
        current_scope = temp;
        current_scope_id++;
        
    }
    void exit_scope(){
       if(current_scope != NULL){
            scope_table *temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;
       }
       else{
           return;
       }
    }
    bool insert(symbol_info* symbol){
        if(current_scope == NULL){
            return false;
        }
        return current_scope->insert_in_scope(symbol);
    }
    

    symbol_info* lookup_in_all_scopes(const string& name) {
    scope_table *temp = current_scope;
    while (temp != NULL) {
        symbol_info *symbol_info_pointer = temp->lookup_in_scope_by_name(name);
        if(symbol_info_pointer != NULL){
            return symbol_info_pointer;
        }
        temp = temp->get_parent_scope();
    }
    return NULL;
}

    bool remove(symbol_info* symbol){
        if(current_scope == NULL){
            return false;
        }
        return current_scope->delete_from_scope(symbol);
    }

    
//new for uniqueness
    symbol_info* lookup_current_scope(string name) {
    if(current_scope == NULL) return NULL;
        
    return current_scope->lookup_in_scope_by_name(name);
}

    symbol_info* lookup_all_scopes(string name) {
        return lookup_in_all_scopes(name);
}
    void print_current_scope(ofstream &outlog){
        outlog<<"------------------"<<endl<<endl;

        if (current_scope != NULL)
        {
            current_scope->print_scope_table(outlog);
        }
        outlog<<"--------------------"<<endl<<endl;
    }
    void print_all_scopes(ofstream &outlog){
        outlog<<"------------------"<<endl<<endl;
        scope_table *temp = current_scope;
        while (temp != NULL)
        {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }
        outlog<<"--------------------"<<endl<<endl;
    }

    
}; 