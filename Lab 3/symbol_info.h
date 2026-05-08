#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H
#include<bits/stdc++.h>
#include <vector>
#include <string>
using namespace std;

class symbol_info
{

private:
    string name;
    string type;

    // Write necessary attributes to store what type of symbol it is (variable/array/function)
    string identifier_name;
    // Write necessary attributes to store the type/return type of the symbol (int/float/void/...)
    string identifier_type;

    // Write necessary attributes to store the parameters of a function
    vector<string> parameters;


    // Write necessary attributes to store the array size if the symbol is an array
    int array_size;

    //new
    bool is_array;
    bool is_function;
    string return_type;
    int parameter_count;
    string expr_type;



//Constructor
public:

    symbol_info(string name, string type) //symbol info constructor
    {
        this->name = name;
        this->type = type;
        this->identifier_name = "";
        this->identifier_type = "";
        // this->parameters = parameters;
        
        
        this->array_size = 0;
        this->is_array = false;
        this->is_function = false;
        this->return_type = "";
        this->parameter_count = 0;
        this->expr_type = "";

    }

//get methods
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

    bool get_is_array()
    {
        return is_array;
    }

    bool get_is_function()
    {
        return is_function;
    }

    string get_return_type()
    {
        return return_type;
    }

    int get_parameter_count()
    {
        return parameter_count;
    }

    string get_expr_type()
    {
        return expr_type;
    }


//set methods
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    // set here
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

    void set_is_array(bool is_array)
    {
        this->is_array = is_array;
    }

    void set_is_function(bool is_function)
    {
        this->is_function = is_function;
    }

    void set_return_type(string return_type)
    {
        this->return_type = return_type;
    }

    void set_parameter_count(int parameter_count)
    {
        this->parameter_count = parameter_count;
    }

    void set_expr_type(string expr_type)
    {
        this->expr_type = expr_type;
    }
 
    ~symbol_info() //descructor
    {
        // Write necessary code to deallocate memory, if necessary
    }
};

#endif
