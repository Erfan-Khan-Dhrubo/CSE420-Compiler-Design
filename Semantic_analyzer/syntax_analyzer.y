%{

// Includes your symbol table implementation.
#include "symbol_table.h"

// Every grammar symbol will store a pointer to symbol_info.
#define YYSTYPE symbol_info* 

extern FILE *yyin;
int yyparse(void);   // gets tokens from Flex
int yylex(void); // builds syntax tree using grammar
extern YYSTYPE yylval;

// symtab → pointer to a symbol_table object 
// new symbol_table(10) → creates a symbol table with 10 hash buckets
symbol_table *symtab = new symbol_table(10);


int lines = 1;

ofstream outlog;

string current_type;            // Stores the current variable type being declared.(eg int, float, void)
vector<string> param_types;     // Stores the types of the parameters of the current function being parsed. (eg int, float, void) 
vector<string> param_names;     // Stores the names of the parameters of the current function being parsed. (eg a, b, c)
string func_name;

bool is_int_type(const string &t) {
    return t == "int";
}

bool is_float_type(const string &t) {
    return t == "float";
}

bool is_numeric_type(const string &t) {
    return is_int_type(t) || is_float_type(t);
}

bool is_zero_constant(const string &value) {
    return value == "0" || value == "0.0" || value == "0.00" || value == "0.000";
}

void semantic_error(const string &msg) {
    outlog << "Error at line " << lines << ": " << msg << endl << endl;
}

void semantic_warning(const string &msg) {
    outlog << "Warning at line " << lines << ": " << msg << endl << endl;
}

symbol_info *lookup_symbol(symbol_info *id) {
    symbol_info temp(id->get_name(), "ID");
    symbol_info *sym = symtab->lookup(&temp);
    if (sym == NULL) {
        semantic_error("'" + id->get_name() + "' undeclared");
    }
    return sym;
}

symbol_info *make_expr(const string &name, const string &type, const string &node_type = "expr") {
    symbol_info *s = new symbol_info(name, node_type);
    s->set_identifier_type(type);
    return s;
}

void yyerror(char *s)
{
    outlog<<"At line "<<lines<<" "<<s<<endl<<endl;
    
    // you may need to reinitialize variables if you find an error

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

        // This ensures that your symbol table exists before you try to print all scopes.
        if(symtab != nullptr) {
        symtab->print_all_scopes(outlog);
        }
   
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

// function_definition →
//     return_type function_name ( parameters ) { function_body }
// Example input:
//      int func(int a, float b) {
//          return a+b;
//      }
// Matching parts:
//      $1	type_specifier → int
//      $2	ID → func
//      $3	(
//      $4	parameter_list → int a, float b
//      $5	)
//      $6	compound_statement → function body
func_definition : type_specifier ID LPAREN parameter_list RPAREN
        {
            func_name = $2->get_name();
            symbol_info *func = new symbol_info(func_name, "ID");
            func->set_identifier_name("Function Definition");
            func->set_identifier_type($1->get_name());
            vector<string> param_details;
            for (int i = 0; i < (int)param_types.size(); i++) {
                if (i < (int)param_names.size() && param_names[i] != "") param_details.push_back(param_types[i] + " " + param_names[i]);
                else param_details.push_back(param_types[i]);
            }
            func->set_parameters(param_details);
            if (!symtab->insert(func)) {
                semantic_error("Redeclaration of function '" + func_name + "' in the same scope");
            }
        }
        compound_statement
    {
        outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
        outlog<<$1->get_name()<<" "<<$2->get_name()<<"("<<$4->get_name()<<")\n"<<$6->get_name()<<endl<<endl;
        param_names.clear();
        param_types.clear();
        $$ = new symbol_info($1->get_name()+" "+$2->get_name()+"("+$4->get_name()+")\n"+$6->get_name(),"func_def");
    }
    | type_specifier ID LPAREN RPAREN
        {
            func_name = $2->get_name();
            symbol_info *func = new symbol_info(func_name, "ID");
            func->set_identifier_name("Function Definition");
            func->set_identifier_type($1->get_name());
            func->set_parameters(vector<string>());
            if (!symtab->insert(func)) {
                semantic_error("Redeclaration of function '" + func_name + "' in the same scope");
            }
        }
        compound_statement
    {
        outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
        outlog<<$1->get_name()<<" "<<$2->get_name()<<"()\n"<<$5->get_name()<<endl<<endl;
        param_names.clear();
        param_types.clear();
        $$ = new symbol_info($1->get_name()+" "+$2->get_name()+"()\n"+$5->get_name(),"func_def");
    }
    ;

// Example input: int func(int a, float b)
parameter_list : parameter_list COMMA type_specifier ID
    {
        outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
        outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;

        // Store parameter type: param_types = ["int","float"]
        param_types.push_back($3->get_name());

        // Store parameter name: param_names = ["a","b"]
        param_names.push_back($4->get_name());

        $$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");       
    }
    | parameter_list COMMA type_specifier
    {
        outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
        outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

        param_types.push_back($3->get_name());
        param_names.push_back("");
        $$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");
    }
    | type_specifier ID
    {
        outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
        outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;

        param_types.push_back($1->get_name());
        param_names.push_back($2->get_name());
        $$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");    

    }
    | type_specifier
    {
        outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
        outlog<<$1->get_name()<<endl<<endl;

        param_types.push_back($1->get_name());
        param_names.push_back("");
        $$ = new symbol_info($1->get_name(),"param_list");

    }
    ;

// Meaning: { statements }
// Where:
//      LCURL	{
//      statements	code inside the block
//      RCURL	}
compound_statement : LCURL
        {
            symtab->enter_scope();
            for (int i = 0; i < (int)param_names.size() && i < (int)param_types.size(); i++) {
                if (param_names[i] != "") {
                    symbol_info *p = new symbol_info(param_names[i], "ID");
                    p->set_identifier_name("Variable");
                    p->set_identifier_type(param_types[i]);
                    symtab->insert(p);
                }
            }
        }
        statements RCURL
    {
        outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
        outlog<<"{\n"+$3->get_name()+"\n}"<<endl<<endl;
        $$ = new symbol_info("{\n"+$3->get_name()+"\n}","comp_stmnt");
        symtab->print_current_scope(outlog);
        symtab->exit_scope();
    }
    | LCURL
        {
            symtab->enter_scope();
        }
        RCURL
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

// Example input: int a, float b
declaration_list : declaration_list COMMA ID
    {
        outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
        outlog<< $1->get_name() <<","<< $3->get_name() <<endl<<endl;

        symbol_info *sym = new symbol_info($3->get_name(), current_type);
        sym->set_identifier_name("Variable");
        sym->set_identifier_type(current_type);
        if (!symtab->insert(sym)) {
            semantic_error("Redeclaration of variable '" + $3->get_name() + "' in the same scope");
        }
        $$ = new symbol_info($1->get_name()+","+$3->get_name(),"decl_list");

    }
    // Example input: int a, float b[10]
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
        outlog<< $1->get_name() <<","<< $3->get_name() <<"["<<$5->get_name()<<"]"<<endl<<endl;

        symbol_info *sym = new symbol_info($3->get_name(), current_type);
        sym->set_identifier_name("Array");
        sym->set_identifier_type(current_type);
        sym->set_array_size(stoi($5->get_name()));
        if (!symtab->insert(sym)) {
            semantic_error("Redeclaration of array '" + $3->get_name() + "' in the same scope");
        }
        $$ = new symbol_info($1->get_name()+","+$3->get_name()+"["+$5->get_name()+"]","decl_list");

    }
    // Example input: int a
    | ID
    {
        outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;

        symbol_info *sym = new symbol_info($1->get_name(), current_type);
        sym->set_identifier_name("Variable");
        sym->set_identifier_type(current_type);
        if (!symtab->insert(sym)) {
            semantic_error("Redeclaration of variable '" + $1->get_name() + "' in the same scope");
        }
        $$ = new symbol_info($1->get_name(),"decl_list");
    }
    // Example input: float b[10]
    | ID LTHIRD CONST_INT RTHIRD
    {
        outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
        outlog<< $1->get_name() <<"["<<$3->get_name()<<"]"<<endl<<endl;

        symbol_info *sym = new symbol_info($1->get_name(), current_type);
        sym->set_identifier_name("Array");
        sym->set_identifier_type(current_type);
        // stoi() is a function that converts a string to an integer:
        sym->set_array_size(stoi($3->get_name()));
        if (!symtab->insert(sym)) {
            semantic_error("Redeclaration of array '" + $1->get_name() + "' in the same scope");
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
        symbol_info *sym = lookup_symbol($3);
        if (sym != NULL && sym->get_identifier_name() == "Function Definition") {
            semantic_error("Function '" + $3->get_name() + "' cannot be used as an argument to printf");
        }
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
        symbol_info *sym = lookup_symbol($1);
        string var_type = "";
        if (sym != NULL) {
            if (sym->get_identifier_name() == "Function Definition") {
                semantic_error("Function '" + $1->get_name() + "' cannot be used as a variable");
            }
            if (sym->get_identifier_name() == "Array") {
                semantic_warning("Array '" + $1->get_name() + "' used without index");
            }
            var_type = sym->get_identifier_type();
        }
        $$ = new symbol_info($1->get_name(),"varbl");
        $$.set_identifier_type(var_type);
        $$.set_identifier_name("Variable");
    }    
    | ID LTHIRD expression RTHIRD 
    {
        outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
        outlog<< $1->get_name() <<"["<<$3->get_name()<<"]"<<endl<<endl;
        symbol_info *sym = lookup_symbol($1);
        string element_type = "";
        if (sym != NULL) {
            if (sym->get_identifier_name() != "Array") {
                semantic_error("'" + $1->get_name() + "' is not declared as an array");
            }
            element_type = sym->get_identifier_type();
        }
        if ($3->get_identifier_type() != "int" && $3->get_identifier_type() != "") {
            semantic_error("Array index must be an integer, found '" + $3->get_identifier_type() + "'");
        }
        $$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");
        $$.set_identifier_type(element_type);
        $$.set_identifier_name("ArrayElement");
    }
    ;

expression : logic_expression
    {
        outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = make_expr($1->get_name(), $1->get_identifier_type(), "expr");
    }
    | variable ASSIGNOP logic_expression     
    {
        outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
        outlog<< $1->get_name() <<"="<< $3->get_name()<<endl<<endl;
        string left_type = $1->get_identifier_type();
        string right_type = $3->get_identifier_type();
        if (left_type == "" || right_type == "") {
            // if we don't know the type due to earlier errors, skip comparison
        } else if (left_type == "int" && right_type == "float") {
            semantic_warning("Possible loss of precision: assigning float expression to int variable '") ;
            semantic_warning("'" + $1->get_name() + "'");
        } else if (!((left_type == "float" && is_numeric_type(right_type)) ||
                     (left_type == "int" && is_numeric_type(right_type)) ||
                     (left_type == right_type))) {
            semantic_error("Assignment type mismatch: cannot assign '" + right_type + "' to '" + left_type + "'");
        }
        $$ = make_expr($1->get_name()+"="+$3->get_name(), left_type == "" ? right_type : left_type, "expr");
    }
    ;

logic_expression : rel_expression
    {
        outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = make_expr($1->get_name(), $1->get_identifier_type(), "lgc_expr");
    }    
    | rel_expression LOGICOP rel_expression 
    {
        outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        string left_type = $1->get_identifier_type();
        string right_type = $3->get_identifier_type();
        if (!is_numeric_type(left_type) || !is_numeric_type(right_type)) {
            semantic_error("Logical operator operands must be numeric types");
        }
        $$ = make_expr($1->get_name()+$2->get_name()+$3->get_name(), "int", "lgc_expr");
    }
    ;

rel_expression : simple_expression
    {
        outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = make_expr($1->get_name(), $1->get_identifier_type(), "rel_expr");
    }
    | simple_expression RELOP simple_expression
    {
        outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        string left_type = $1->get_identifier_type();
        string right_type = $3->get_identifier_type();
        if (!is_numeric_type(left_type) || !is_numeric_type(right_type)) {
            semantic_error("Relational operator operands must be numeric types");
        }
        $$ = make_expr($1->get_name()+$2->get_name()+$3->get_name(), "int", "rel_expr");
    }
    ;

simple_expression : term
    {
        outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = make_expr($1->get_name(), $1->get_identifier_type(), "simp_expr");
    }
    | simple_expression ADDOP term 
    {
        outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        string left_type = $1->get_identifier_type();
        string right_type = $3->get_identifier_type();
        if (!is_numeric_type(left_type) || !is_numeric_type(right_type)) {
            semantic_error("Additive operator operands must be numeric types");
        }
        string result_type = (is_float_type(left_type) || is_float_type(right_type)) ? "float" : "int";
        $$ = make_expr($1->get_name()+$2->get_name()+$3->get_name(), result_type, "simp_expr");
    }
    ;

term : unary_expression  //term can be void because of un_expr->factor
    {
        outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = make_expr($1->get_name(), $1->get_identifier_type(), "term");
    }
    | term MULOP unary_expression
    {
        outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        string left_type = $1->get_identifier_type();
        string right_type = $3->get_identifier_type();
        string op = $2->get_name();
        if (!is_numeric_type(left_type) || !is_numeric_type(right_type)) {
            semantic_error("Multiplicative operator operands must be numeric types");
        }
        if (op == "%") {
            if (!is_int_type(left_type) || !is_int_type(right_type)) {
                semantic_error("Modulus operator operands must be integers");
            }
        }
        if ((op == "/" || op == "%") && is_zero_constant($3->get_name())) {
            semantic_error("Division or modulus by zero detected");
        }
        string result_type;
        if (op == "%") {
            result_type = "int";
        } else {
            result_type = (is_float_type(left_type) || is_float_type(right_type)) ? "float" : "int";
        }
        $$ = make_expr($1->get_name()+$2->get_name()+$3->get_name(), result_type, "term");
    }
    ;

unary_expression : ADDOP unary_expression
    {
        outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() <<endl<<endl;
        string operand_type = $2->get_identifier_type();
        if (!is_numeric_type(operand_type)) {
            semantic_error("Unary plus/minus requires a numeric operand");
        }
        $$ = make_expr($1->get_name()+$2->get_name(), operand_type, "un_expr");
    }
    | NOT unary_expression 
    {
        outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
        outlog<<"!"<< $2->get_name() <<endl<<endl;
        if (!is_numeric_type($2->get_identifier_type())) {
            semantic_error("Logical not operand must be numeric");
        }
        $$ = make_expr("!"+$2->get_name(), "int", "un_expr");
    }
    | factor 
    {
        outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = make_expr($1->get_name(), $1->get_identifier_type(), "un_expr");
    }
    ;

factor : variable
    {
        outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"fctr");
    }
    | ID LPAREN argument_list RPAREN
    {
        outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
        outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;
	
		$$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->get_name()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->get_name()+")","fctr");
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->get_name()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"++","fctr");
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->get_name()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"--","fctr");
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
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
						
				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;
						
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
	outlog.open("my_log.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}

	symtab->enter_scope();

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	
	outlog.close();
	
	fclose(yyin);
	
	return 0;
}