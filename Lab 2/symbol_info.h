// The lexer only recognizes identifiers as ID. The parser determines whether the identifier is a variable, 
// array, or function based on grammar rules and then stores that information in the symbol_info object.

#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H
#include<bits/stdc++.h>     // This header includes almost all standard C++ libraries at once.
#include <vector>           // Used for storing function parameters
#include <string>           // Used for identifier names and types
using namespace std;        // This allows writing: string name instead of std::string name


class symbol_info
{
private:
    string name;                // These variables store symbol attributes. (a, sum, arr)
    string type;                // This variable stores the token type  (ID, ADDOP, MULOP,CONST_INT)
    string identifier_name;     // This variable stores the identifier type (variable/array/function)
    string identifier_type;     // This variable stores the identifier data type (int/float/void)
    int array_size;             // This variable stores the size of the array if the symbol is an array
    vector<string> parameters;  // Used only when the symbol is a function.
                                // Example: int sum(int a, float b) Parameters stored: ["int","float"]


public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->identifier_name = "";
        this->identifier_type = "";
        // this->parameters = parameters;
        this->array_size = 0;
    }

    // Getter Functions
    string get_name()
    {
        return name;
    }

    string get_type()
    {
        return type;
    }

    string get_identifier_name()
    {
        return identifier_name;
    }

    string get_identifier_type()
    {
        return identifier_type;
    }

    vector<string> get_parameters()
    {
        return parameters;
    }

    int get_array_size()
    {
        return array_size;
    }

    // Setter Functions
    void set_name(string name)
    {
        this->name = name;
    }

    void set_type(string type)
    {
        this->type = type;
    }
    
    void set_identifier_name(string identifier_name) 
    {
        this->identifier_name = identifier_name;
    }

    void set_identifier_type(string identifier_type)
    {
        this->identifier_type = identifier_type;
    }

    void set_parameters(vector<string> parameters)
    {
        this->parameters = parameters;
    }

    void set_array_size(int array_size)
    {
        this->array_size = array_size;
    }

    ~symbol_info() // Destructor runs when an object is destroyed.
    {
        // Write necessary code to deallocate memory, if necessary
    }
};

#endif