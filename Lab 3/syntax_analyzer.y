%{
#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

symbol_table *symtab = new symbol_table(10);
string current_type; 
vector<string> param_types; 
vector<string> param_names; 
string func_name;
vector<string> arg_types;   
int arg_count;  

int lines = 1;
int error_count = 0;

ofstream outlog;
ofstream outerror;



void yyerror(const char *s)
{
    outerror<<"At line no: "<<lines<<" "<<s<<endl;
    error_count++;
}
%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
    {
        outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
        outlog<<"Symbol Table"<<endl<<endl;

        symtab->print_all_scopes(outlog);

    
    }
    ;

program : program unit
    {
        outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
        outlog<<$1->get_name()+"\n"+$2->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"program");
        
    }
    | unit
    {
        outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"program");
    }
    ;

unit : var_declaration
    {
        outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"unit");
    }
    | func_definition
    {
        outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"unit");
    }
    ;

function_head : type_specifier ID LPAREN parameter_list RPAREN
    {
        func_name = $2->get_name();
        symbol_info *func = new symbol_info(func_name, $1->get_name());
        func->set_is_function(true);
        func->set_return_type($1->get_name());
        func->set_parameters(param_types);
        func->set_parameter_count((int)param_types.size());
        symtab->insert(func);
        symtab->enter_scope();
        for (size_t i = 0; i < param_names.size() && i < param_types.size(); i++) {
            symbol_info *p = new symbol_info(param_names[i], param_types[i]);
            symtab->insert(p);
        }
        param_types.clear();
        param_names.clear();
        $$ = new symbol_info($1->get_name()+" "+$2->get_name()+"("+$4->get_name()+")","func_head");
    }
    | type_specifier ID LPAREN RPAREN
    {
        func_name = $2->get_name();
        symbol_info *func = new symbol_info(func_name, $1->get_name());
        func->set_is_function(true);
        func->set_return_type($1->get_name());
        func->set_parameter_count(0);
        symtab->insert(func);
        symtab->enter_scope();
        $$ = new symbol_info($1->get_name()+" "+$2->get_name()+"()","func_head");
    }
    ;

func_definition : function_head compound_statement
    {
        outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
        outlog<<$1->get_name()<<"\n"<<$2->get_name()<<endl<<endl;
        symtab->exit_scope();
        $$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"func_def");
    }
    ;

parameter_list : parameter_list COMMA type_specifier ID
    {
        outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
        outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;

        param_types.push_back($3->get_name()); 
        param_names.push_back($4->get_name());
        $$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");

        

    }
    | parameter_list COMMA type_specifier
    {
        outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
        outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");


    }
    | type_specifier ID
    {
        outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
        outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;

        param_types.push_back(current_type);
        param_names.push_back($2->get_name());
        $$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");    

    }
    | type_specifier
    {
        outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name(),"param_list");

        // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table

    }
    ;

open_block :
    {
        symtab->enter_scope();
    }
    ;

compound_statement : LCURL open_block statements RCURL
    {
        outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
        outlog<<"{\n"+$3->get_name()+"\n}"<<endl<<endl;
        $$ = new symbol_info("{\n"+$3->get_name()+"\n}","comp_stmnt");
        symtab->print_current_scope(outlog);
        symtab->exit_scope();
    }
    | LCURL open_block RCURL
    {
        outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
        outlog<<"{\n}"<<endl<<endl;
        $$ = new symbol_info("{\n}","comp_stmnt");
        symtab->print_current_scope(outlog);
        symtab->exit_scope();
    }
    ;

var_declaration : type_specifier declaration_list SEMICOLON
    {
        outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
        outlog<< $1->get_name() <<" "<< $2->get_name() <<";"<<endl<<endl;

        if(current_type == "void") {
            yyerror("variable type can not be void");
        }

        $$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");
    }
    ;

type_specifier : INT
    {
        outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
        outlog<<"int"<<endl<<endl;

        current_type = "int";

        $$ = new symbol_info("int","type");
    }
    | FLOAT
    {
        outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
        outlog<<"float"<<endl<<endl;

        current_type = "float";

        $$ = new symbol_info("float","type");
    }
    | VOID
    {
        outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
        outlog<<"void"<<endl<<endl;

         current_type = "void";

        $$ = new symbol_info("void","type");
    }
    ;



declaration_list : declaration_list COMMA ID //normal
    {
        outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
        outlog<< $1->get_name() <<","<< $3->get_name() <<endl<<endl;


//multiple declaration check
        symbol_info* existing = symtab->lookup_current_scope($3->get_name());
        if(existing != NULL) {
            string e = "Multiple declaration of variable " + $3->get_name();
            yyerror(e.c_str());
        } else {
            symbol_info *sym = new symbol_info($3->get_name(), current_type);
            symtab->insert(sym);
        }

        $$ = new symbol_info($1->get_name()+","+$3->get_name(),"decl_list");

    }


    
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD  //array
    {
        outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
        outlog<< $1->get_name() <<","<< $3->get_name() <<"["<<$5->get_name()<<"]"<<endl<<endl;

        symbol_info* existing = symtab->lookup_current_scope($3->get_name());
        if(existing != NULL) {
            string e = "Multiple declaration of variable " + $3->get_name();
            yyerror(e.c_str());
        } else {
            symbol_info *sym = new symbol_info($3->get_name(), current_type);
            sym->set_array_size(stoi($5->get_name()));
            sym->set_is_array(true); 
            symtab->insert(sym);
        }

        $$ = new symbol_info($1->get_name()+","+$3->get_name()+"["+$5->get_name()+"]","decl_list");
    }


    | ID //normal
    {
        outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;


        symbol_info* existing = symtab->lookup_current_scope($1->get_name());
        if(existing != NULL) {
            string e = "Multiple declaration of variable " + $1->get_name();
            yyerror(e.c_str());
        } else {
            symbol_info *sym = new symbol_info($1->get_name(), current_type);
            symtab->insert(sym);
        }

        $$ = new symbol_info($1->get_name(),"decl_list");


        
    }
    | ID LTHIRD CONST_INT RTHIRD //array
    {
        outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
        outlog<< $1->get_name() <<"["<<$3->get_name()<<"]"<<endl<<endl;


        symbol_info* existing = symtab->lookup_current_scope($1->get_name());
        if(existing != NULL) {
            string e = "Multiple declaration of variable " + $1->get_name();
            yyerror(e.c_str());
        } else {
            symbol_info *sym = new symbol_info($1->get_name(), current_type);
            sym->set_array_size(stoi($3->get_name()));
            sym->set_is_array(true); 
            symtab->insert(sym);
        }

        $$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","decl_list");

    }
      

    
    ;

statements : statement
    {
        outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"stmnts");
    }
    | statements statement
    {
        outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
        outlog<< $1->get_name() <<"\n"<< $2->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"stmnts");
    }
    ;

statement : var_declaration
    {
        outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"stmnt");
    }
    | func_definition
    {
        outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"stmnt");
    }
    | expression_statement
    {
        outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"stmnt");
    }
    | compound_statement
    {
        outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"stmnt");
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    {
        outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
        outlog<<"for("<<$3->get_name()<<$4->get_name()<<$5->get_name()<<")\n"<<$7->get_name()<<endl<<endl;
        $$ = new symbol_info("for("+$3->get_name()+$4->get_name()+$5->get_name()+")\n"+$7->get_name(),"stmnt");
    }
    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
    {
        outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
        outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
        $$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
        outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<"\nelse\n"<<$7->get_name()<<endl<<endl;
        $$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name()+"\nelse\n"+$7->get_name(),"stmnt");
    }
    | WHILE LPAREN expression RPAREN statement
    {
        outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
        outlog<<"while("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
        $$ = new symbol_info("while("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    {
        outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
        outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl; 
        $$ = new symbol_info("printf("+$3->get_name()+");","stmnt");
    }
    | RETURN expression SEMICOLON
    {
        outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
        outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;
        $$ = new symbol_info("return "+$2->get_name()+";","stmnt");
    }
    ;

expression_statement : SEMICOLON
    {
        outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
        outlog<<";"<<endl<<endl;
        $$ = new symbol_info(";","expr_stmt");
    }
    | expression SEMICOLON 
    {
        outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
        outlog<<$1->get_name()<<";"<<endl<<endl;
        $$ = new symbol_info($1->get_name()+";","expr_stmt");
    }
    ;

variable : ID    
    {
        outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;


//Undeclared var check

        symbol_info* existing = symtab->lookup_all_scopes($1->get_name());
        if(existing == NULL) {
            string e = "Undeclared variable " + $1->get_name();
            yyerror(e.c_str());
        }

//if index used array check
        else if(existing->get_is_array()) {
            string e = "variable is of array type : " + $1->get_name();
            yyerror(e.c_str());
        }

        $$ = new symbol_info($1->get_name(),"varbl");

        if(existing) 
        {
            $$->set_expr_type(existing->get_type());

        }
    } 



//array idx check inside 

    | ID LTHIRD expression RTHIRD 
    {
        outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
        outlog<< $1->get_name() <<"["<<$3->get_name()<<"]"<<endl<<endl;

        
        symbol_info* existing = symtab->lookup_all_scopes($1->get_name());
        if(existing == NULL) {
            string e = "Undeclared variable " + $1->get_name();
            yyerror(e.c_str());
        }

//if index used non-array

        else if(!existing->get_is_array()) {
            string e = "variable is not of array type : " + existing->get_name();
            yyerror(e.c_str());
        }

//aray index checking
        if($3->get_expr_type() != "int") {
            string e = "array index is not of integer type : " + $1->get_name();
            yyerror(e.c_str());
        }

        
        $$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");

        if(existing) 
        {
            $$->set_expr_type(existing->get_type());

        }
    }
    ;

expression : logic_expression
    {
        outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"expr");
        $$->set_expr_type($1->get_expr_type());
    }




//assignment_op type check

    | variable ASSIGNOP logic_expression     
    {
        outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
        outlog<< $1->get_name() <<"="<< $3->get_name()<<endl<<endl;

        
        string var_type = $1->get_expr_type();
        string expr_type = $3->get_expr_type();

        if(!var_type.empty()) {

//check if float is on int type   

        if(var_type == "int" && expr_type == "float") {
            yyerror("Warning: Assignment of float value into variable of integer type ");
        }


// Check for types
        else if(var_type != expr_type && !(var_type == "float" && expr_type == "int")) {  //when var float and ex_type is not int
            yyerror("Type mismatch in assignment");
        }

        }
    
        $$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");
        $$->set_expr_type(var_type); 

    }
    ;



//new
logic_expression : rel_expression
    {
        outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"lgc_expr");
        $$->set_expr_type($1->get_expr_type());

    }    

//logicop set to int

    | rel_expression LOGICOP rel_expression 
    {
        outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");
        $$->set_expr_type("int");
    }
    ;



rel_expression : simple_expression
    {
        outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"rel_expr");
        $$->set_expr_type($1->get_expr_type());
    }


//Relop result int

    | simple_expression RELOP simple_expression
    {
        outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");
        $$->set_expr_type("int");  
    }
    ;





simple_expression : term
    {
        outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"simp_expr");
        $$->set_expr_type($1->get_expr_type());
    }
    | simple_expression ADDOP term 

    {
        outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");
        
        string type1 = $1->get_expr_type();
        string type2 = $3->get_expr_type();
        if(type1 == "float" || type2 == "float")
        {
            $$->set_expr_type("float");
        } else if(type1 == "int" && type2 == "int")
        {
            $$->set_expr_type("int");
        }
    }
    ;



//new
term : unary_expression
    {
        outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"term");
        $$->set_expr_type($1->get_expr_type());
    }



//mod op making int

    | term MULOP unary_expression

    {
        outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;


//mod and div checking
         string op = $2->get_name();
        

// Modulus op int
        
        if(op == "%") {
        if($1->get_expr_type() != "int" || $3->get_expr_type() != "int") {
            yyerror("Modulus operator on non integer type ");
        }
    }


//mod 0

        if(op == "%") {
            string right_operand = $3->get_name();
            if(right_operand == "0" || right_operand == "0.0") {
                yyerror("Modulus by 0");
        }
    }

//division by 0 

        else if(op == "/") {
            string right_operand = $3->get_name();
            if(right_operand == "0" || right_operand == "0.0") {
                yyerror("Division by zero");
            }
        }

        $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");

        string type1 = $1->get_expr_type();
        string type2 = $3->get_expr_type();
        if(op == "%") {
            $$->set_expr_type("int");
        } else if(type1 == "float" || type2 == "float") {
            $$->set_expr_type("float");
        } else if(type1 == "int" && type2 == "int") {
            $$->set_expr_type("int");
        }


    }
    ;


//new

unary_expression : ADDOP unary_expression
    {
        outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
        $$->set_expr_type($2->get_expr_type());
    }
    | NOT unary_expression 
    {
        outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
        outlog<<"!"<< $2->get_name() <<endl<<endl;
        $$ = new symbol_info("!"+$2->get_name(),"un_expr");
        $$->set_expr_type("int");
    }
    | factor 
    {
        outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"un_expr");
        $$->set_expr_type($1->get_expr_type());
    }
    ;

factor : variable
    {
        outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"fctr");
        $$->set_expr_type($1->get_expr_type());

    }



//func cal argu

    | ID LPAREN argument_list RPAREN
    {
        outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
        outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;

//func declaration

        symbol_info* existing = symtab->lookup_all_scopes($1->get_name());
        if(existing == NULL) {
            string e = "Undeclared function " + $1->get_name();
            yyerror(e.c_str());
        } 
        else if(!existing->get_is_function()) {
            string e = $1->get_name() + " is not a function";
            yyerror(e.c_str());
        }

//void func check
        else if(existing->get_return_type() == "void") {
            yyerror("operation on void type");
        }


//check expected param
        else {
            int expected_params = existing->get_parameter_count();
            if(arg_count != expected_params) {
                string e = "Inconsistencies in number of arguments in function call: " + $1->get_name();
                yyerror(e.c_str());

//param type check

            } else {
                vector<string> param_types_list = existing->get_parameters();
                for(int i = 0; i < arg_count; i++) {
                    if(i < (int)param_types_list.size()) { //size return unsigned. so int
                        if(arg_types[i] != param_types_list[i]) {
                            if(!(arg_types[i] == "int" && param_types_list[i] == "float")) {
                                string e = "argument " + to_string(i+1) + " type mismatch in function call: " + $1->get_name();
                                yyerror(e.c_str());
                            }
                        }
                    }
                }
            }
        

        }

       


        arg_count = 0;
        arg_types.clear();


		$$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");
        if(existing) {
            $$->set_expr_type(existing->get_return_type());
}
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->get_name()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->get_name()+")","fctr");
        $$->set_expr_type($2->get_expr_type());

	}



	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
        $$->set_expr_type("int");
	}



	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
         $$->set_expr_type("float");
	}



	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->get_name()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"++","fctr");
        $$->set_expr_type($1->get_expr_type());

	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->get_name()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"--","fctr");
        $$->set_expr_type($1->get_expr_type());

	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->get_name()<<endl<<endl;
					$$ = new symbol_info($1->get_name(),"arg_list");
			  }
			  | 
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;

                    arg_count = 0;  
                    arg_types.clear();
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

                arg_count++;  //func declaration    
                arg_types.push_back($3->get_expr_type()); //argument type track

				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

                arg_count = 1;
                arg_types.clear();
                arg_types.push_back($1->get_expr_type());
						
				$$ = new symbol_info($1->get_name(),"arg");
		  }
	      ;
 
%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("log.txt", ios::app);
    outerror.open("error.txt", ios::app);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}

	symtab->enter_scope();

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
    outlog<<"Total errors: "<<error_count<<endl;
    outerror<<endl<<"Total errors: "<<error_count<<endl; 
	
	outlog.close();
    outerror.close();
	
	fclose(yyin);
	
	return 0;
}