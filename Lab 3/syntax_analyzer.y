%{

// Includes your symbol table implementation.
#include "symbol_table.h"
#include <cstdlib>
#include <cmath>
#include <string>

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
ofstream outerror;
int semantic_error_count = 0;

string current_type;            // Stores the current variable type being declared.(eg int, float, void)
vector<string> param_types;     // Stores the types of the parameters of the current function being parsed. (eg int, float, void) 
vector<string> param_names;     // Stores the names of the parameters of the current function being parsed. (eg a, b, c)
string func_name;

static void sem_log_error(int line, const string &msg)
{
    if (outerror.is_open())
        outerror << "At line no: " << line << " " << msg << endl;
    semantic_error_count++;
}

static void sem_log_warning(int line, const string &msg)
{
    if (outerror.is_open())
        outerror << "At line no: " << line << " Warning: " << msg << endl;
    semantic_error_count++;
}

static bool is_int_t(const string &t) { return t == "int"; }
static bool is_float_t(const string &t) { return t == "float"; }
static bool is_void_t(const string &t) { return t == "void"; }
static bool is_err_t(const string &t) { return t == "error"; }
static bool is_numeric_t(const string &t) { return is_int_t(t) || is_float_t(t); }

static string promote_numeric(const string &a, const string &b)
{
    if (is_err_t(a) || is_err_t(b)) return "error";
    if (is_float_t(a) || is_float_t(b)) return "float";
    if (is_int_t(a) && is_int_t(b)) return "int";
    return "error";
}

static string param_type_from_formal(const string &detail)
{
    size_t sp = detail.find(' ');
    if (sp == string::npos) return detail;
    return detail.substr(0, sp);
}

static bool arg_matches_param(const string &param_t, const string &arg_t)
{
    if (param_t == arg_t) return true;
    if (param_t == "float" && arg_t == "int") return true;
    return false;
}

static bool is_zero_literal(symbol_info *s)
{
    if (!s) return false;
    if (s->get_type() == "INT" && s->get_name() == "0") return true;
    if (s->get_type() == "FLOAT")
    {
        double v = atof(s->get_name().c_str());
        return fabs(v) < 1e-12;
    }
    return false;
}

static symbol_info *lookup_symbol(const string &name)
{
    symbol_info probe(name, "ID");
    return symtab->lookup(&probe);
}

void yyerror(char *s)
{
    outlog<<"At line "<<lines<<" "<<s<<endl<<endl;
    if (outerror.is_open())
        outerror << "At line no: " << lines << " " << s << endl;
    semantic_error_count++;
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
func_definition : type_specifier ID LPAREN { func_name = $2->get_name(); } parameter_list RPAREN
        {
            symbol_info *func = new symbol_info($2->get_name(), "ID");
            func->set_identifier_name("Function Definition");
            func->set_identifier_type($1->get_name());
            vector<string> param_details;
            for (int i = 0; i < (int)param_types.size(); i++) {
                if (i < (int)param_names.size() && param_names[i] != "") param_details.push_back(param_types[i] + " " + param_names[i]);
                else param_details.push_back(param_types[i]);
            }
            func->set_parameters(param_details);
            if (!symtab->insert(func)) {
                sem_log_error($2->get_line_no(), "Multiple declaration of function " + $2->get_name());
                delete func;
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
    | type_specifier ID LPAREN { func_name = $2->get_name(); } RPAREN
        {
            symbol_info *func = new symbol_info($2->get_name(), "ID");
            func->set_identifier_name("Function Definition");
            func->set_identifier_type($1->get_name());
            func->set_parameters(vector<string>());
            if (!symtab->insert(func)) {
                sem_log_error($2->get_line_no(), "Multiple declaration of function " + $2->get_name());
                delete func;
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

        for (size_t i = 0; i < param_names.size(); i++) {
            if (param_names[i] != "" && param_names[i] == $4->get_name()) {
                sem_log_error($4->get_line_no(), "Multiple declaration of variable " + $4->get_name() + " in parameter of " + func_name);
                break;
            }
        }
        param_types.push_back($3->get_name());
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
                    if (!symtab->insert(p)) {
                        sem_log_error(lines, "Multiple declaration of variable " + param_names[i] + " in parameter of " + func_name);
                        delete p;
                    }
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

        if (current_type == "void") {
            sem_log_error($3->get_line_no(), "variable type can not be void");
        } else {
            symbol_info *sym = new symbol_info($3->get_name(), current_type);
            sym->set_identifier_name("Variable");
            sym->set_identifier_type(current_type);
            if (!symtab->insert(sym)) {
                sem_log_error($3->get_line_no(), "Multiple declaration of variable " + $3->get_name());
                delete sym;
            }
        }
        $$ = new symbol_info($1->get_name()+","+$3->get_name(),"decl_list");

    }
    // Example input: int a, float b[10]
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
        outlog<< $1->get_name() <<","<< $3->get_name() <<"["<<$5->get_name()<<"]"<<endl<<endl;

        if (current_type == "void") {
            sem_log_error($3->get_line_no(), "variable type can not be void");
        } else {
            symbol_info *sym = new symbol_info($3->get_name(), current_type);
            sym->set_identifier_name("Array");
            sym->set_identifier_type(current_type);
            sym->set_array_size(stoi($5->get_name()));
            if (!symtab->insert(sym)) {
                sem_log_error($3->get_line_no(), "Multiple declaration of variable " + $3->get_name());
                delete sym;
            }
        }
        $$ = new symbol_info($1->get_name()+","+$3->get_name()+"["+$5->get_name()+"]","decl_list");

    }
    // Example input: int a
    | ID
    {
        outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;

        if (current_type == "void") {
            sem_log_error($1->get_line_no(), "variable type can not be void");
        } else {
            symbol_info *sym = new symbol_info($1->get_name(), current_type);
            sym->set_identifier_name("Variable");
            sym->set_identifier_type(current_type);
            if (!symtab->insert(sym)) {
                sem_log_error($1->get_line_no(), "Multiple declaration of variable " + $1->get_name());
                delete sym;
            }
        }
        $$ = new symbol_info($1->get_name(),"decl_list");
    }
    // Example input: float b[10]
    | ID LTHIRD CONST_INT RTHIRD
    {
        outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
        outlog<< $1->get_name() <<"["<<$3->get_name()<<"]"<<endl<<endl;

        if (current_type == "void") {
            sem_log_error($1->get_line_no(), "variable type can not be void");
        } else {
            symbol_info *sym = new symbol_info($1->get_name(), current_type);
            sym->set_identifier_name("Array");
            sym->set_identifier_type(current_type);
            sym->set_array_size(stoi($3->get_name()));
            if (!symtab->insert(sym)) {
                sem_log_error($1->get_line_no(), "Multiple declaration of variable " + $1->get_name());
                delete sym;
            }
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
        symbol_info *sym = lookup_symbol($3->get_name());
        if (!sym || sym->get_identifier_name() == "Function Definition")
            sem_log_error($3->get_line_no(), "Undeclared variable " + $3->get_name());
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
        symbol_info *sym = lookup_symbol($1->get_name());
        $$ = new symbol_info($1->get_name(),"varbl");
        $$->set_line_no($1->get_line_no());
        if (!sym) {
            sem_log_error($1->get_line_no(), "Undeclared variable " + $1->get_name());
            $$->set_expr_data_type("error");
        } else if (sym->get_identifier_name() == "Function Definition") {
            sem_log_error($1->get_line_no(), "Undeclared variable " + $1->get_name());
            $$->set_expr_data_type("error");
        } else if (sym->get_identifier_name() == "Array") {
            sem_log_error($1->get_line_no(), "variable is of array type : " + $1->get_name());
            $$->set_expr_data_type("error");
        } else {
            $$->set_expr_data_type(sym->get_identifier_type());
        }
    }    
    | ID LTHIRD expression RTHIRD 
    {
        outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
        outlog<< $1->get_name() <<"["<<$3->get_name()<<"]"<<endl<<endl;
        symbol_info *sym = lookup_symbol($1->get_name());
        $$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");
        $$->set_line_no($1->get_line_no());
        if (!sym) {
            sem_log_error($1->get_line_no(), "Undeclared variable " + $1->get_name());
            $$->set_expr_data_type("error");
        } else if (sym->get_identifier_name() != "Array") {
            sem_log_error($1->get_line_no(), "variable is not of array type : " + $1->get_name());
            $$->set_expr_data_type("error");
        } else {
            if (!is_int_t($3->get_expr_data_type()))
                sem_log_error($1->get_line_no(), "array index is not of integer type : " + $1->get_name());
            $$->set_expr_data_type(sym->get_identifier_type());
        }
    }
    ;

expression : logic_expression
    {
        outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"expr");
        $$->set_expr_data_type($1->get_expr_data_type());
        $$->set_line_no($1->get_line_no());
    }
    | variable ASSIGNOP logic_expression     
    {
        outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
        outlog<< $1->get_name() <<"="<< $3->get_name()<<endl<<endl;
        $$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");
        $$->set_line_no($2->get_line_no());
        string lt = $1->get_expr_data_type();
        string rt = $3->get_expr_data_type();
        if (is_void_t(rt))
            sem_log_error($2->get_line_no(), "operation on void type");
        else if (!is_err_t(lt) && !is_err_t(rt)) {
            if (is_int_t(lt) && is_float_t(rt))
                sem_log_warning($2->get_line_no(), "Assignment of float value into variable of integer type");
            else if (!is_numeric_t(lt) || !is_numeric_t(rt))
                sem_log_error($2->get_line_no(), "Operands of assignment are inconsistent");
        }
        $$->set_expr_data_type(lt);
    }
    ;

logic_expression : rel_expression
    {
        outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"lgc_expr");
        $$->set_expr_data_type($1->get_expr_data_type());
        $$->set_line_no($1->get_line_no());
    }    
    | rel_expression LOGICOP rel_expression 
    {
        outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");
        $$->set_line_no($2->get_line_no());
        string t1 = $1->get_expr_data_type();
        string t2 = $3->get_expr_data_type();
        if (is_void_t(t1) || is_void_t(t2))
            sem_log_error($2->get_line_no(), "operation on void type");
        $$->set_expr_data_type("int");
    }
    ;

rel_expression : simple_expression
    {
        outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"rel_expr");
        $$->set_expr_data_type($1->get_expr_data_type());
        $$->set_line_no($1->get_line_no());
    }
    | simple_expression RELOP simple_expression
    {
        outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");
        $$->set_line_no($2->get_line_no());
        string t1 = $1->get_expr_data_type();
        string t2 = $3->get_expr_data_type();
        if (is_void_t(t1) || is_void_t(t2))
            sem_log_error($2->get_line_no(), "operation on void type");
        $$->set_expr_data_type("int");
    }
    ;

simple_expression : term
    {
        outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"simp_expr");
        $$->set_expr_data_type($1->get_expr_data_type());
        $$->set_line_no($1->get_line_no());
    }
    | simple_expression ADDOP term 
    {
        outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");
        $$->set_line_no($2->get_line_no());
        string t1 = $1->get_expr_data_type();
        string t2 = $3->get_expr_data_type();
        bool voidop = is_void_t(t1) || is_void_t(t2);
        if (voidop)
            sem_log_error($2->get_line_no(), "operation on void type");
        $$->set_expr_data_type(voidop ? "error" : promote_numeric(t1, t2));
    }
    ;

term : unary_expression  //term can be void because of un_expr->factor
    {
        outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"term");
        $$->set_expr_data_type($1->get_expr_data_type());
        $$->set_line_no($1->get_line_no());
    }
    | term MULOP unary_expression
    {
        outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() << $3->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");
        $$->set_line_no($2->get_line_no());
        string op = $2->get_name();
        string t1 = $1->get_expr_data_type();
        string t2 = $3->get_expr_data_type();
        bool voidop = is_void_t(t1) || is_void_t(t2);
        if (voidop)
            sem_log_error($2->get_line_no(), "operation on void type");
        if (op == "%") {
            if (!voidop) {
                if (!is_int_t(t1) || !is_int_t(t2))
                    sem_log_error($2->get_line_no(), "Modulus operator on non integer type");
                if (is_zero_literal($3))
                    sem_log_error($2->get_line_no(), "Modulus by 0");
            }
            $$->set_expr_data_type(voidop ? "error" : "int");
        } else if (op == "/") {
            if (!voidop && is_zero_literal($3))
                sem_log_error($2->get_line_no(), "Division by 0");
            $$->set_expr_data_type(voidop ? "error" : promote_numeric(t1, t2));
        } else {
            $$->set_expr_data_type(voidop ? "error" : promote_numeric(t1, t2));
        }
    }
    ;

unary_expression : ADDOP unary_expression
    {
        outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
        outlog<< $1->get_name() << $2->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
        $$->set_line_no($1->get_line_no());
        if (is_void_t($2->get_expr_data_type()))
            sem_log_error($1->get_line_no(), "operation on void type");
        $$->set_expr_data_type(is_void_t($2->get_expr_data_type()) ? "error" : $2->get_expr_data_type());
    }
    | NOT unary_expression 
    {
        outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
        outlog<<"!"<< $2->get_name() <<endl<<endl;
        $$ = new symbol_info("!"+$2->get_name(),"un_expr");
        $$->set_line_no($2->get_line_no());
        if (is_void_t($2->get_expr_data_type()))
            sem_log_error($2->get_line_no(), "operation on void type");
        $$->set_expr_data_type("int");
    }
    | factor 
    {
        outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"un_expr");
        $$->set_expr_data_type($1->get_expr_data_type());
        $$->set_line_no($1->get_line_no());
    }
    ;

factor : variable
    {
        outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
        outlog<< $1->get_name() <<endl<<endl;
        $$ = new symbol_info($1->get_name(),"fctr");
        $$->set_expr_data_type($1->get_expr_data_type());
        $$->set_line_no($1->get_line_no());
    }
    | ID LPAREN argument_list RPAREN
    {
        outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
        outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;
        symbol_info *fn = lookup_symbol($1->get_name());
        int ln = $1->get_line_no();
        vector<string> actual = $3->get_arg_types();
        $$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");
        $$->set_line_no(ln);
        if (!fn) {
            sem_log_error(ln, "Undeclared function: " + $1->get_name());
            $$->set_expr_data_type("error");
        } else if (fn->get_identifier_name() != "Function Definition") {
            sem_log_error(ln, "function call cannot be made with non-function type identifier");
            $$->set_expr_data_type("error");
        } else {
            vector<string> formals = fn->get_parameters();
            if ((int)actual.size() != (int)formals.size())
                sem_log_error(ln, "Inconsistencies in number of arguments in function call: " + $1->get_name());
            for (size_t i = 0; i < actual.size() && i < formals.size(); i++) {
                string pt = param_type_from_formal(formals[i]);
                if (!arg_matches_param(pt, actual[i]))
                    sem_log_error(ln, "argument " + to_string((int)i + 1) + " type mismatch in function call: " + $1->get_name());
            }
            $$->set_expr_data_type(fn->get_identifier_type());
        }
    }
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->get_name()<<")"<<endl<<endl;
		$$ = new symbol_info("("+$2->get_name()+")","fctr");
		$$->set_expr_data_type($2->get_expr_data_type());
		$$->set_line_no($2->get_line_no());
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_expr_data_type("int");
		$$->set_line_no($1->get_line_no());
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_expr_data_type("float");
		$$->set_line_no($1->get_line_no());
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->get_name()<<"++"<<endl<<endl;
		if (is_void_t($1->get_expr_data_type()))
		    sem_log_error($1->get_line_no(), "operation on void type");
		$$ = new symbol_info($1->get_name()+"++","fctr");
		$$->set_expr_data_type($1->get_expr_data_type());
		$$->set_line_no($1->get_line_no());
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->get_name()<<"--"<<endl<<endl;
		if (is_void_t($1->get_expr_data_type()))
		    sem_log_error($1->get_line_no(), "operation on void type");
		$$ = new symbol_info($1->get_name()+"--","fctr");
		$$->set_expr_data_type($1->get_expr_data_type());
		$$->set_line_no($1->get_line_no());
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->get_name()<<endl<<endl;
					$$ = new symbol_info($1->get_name(),"arg_list");
					$$->append_arg_types($1->get_arg_types());
			  }
			  | 
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
					$$ = new symbol_info("","arg_list");
					$$->clear_arg_types();
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");
				$$->append_arg_types($1->get_arg_types());
				$$->add_arg_type($3->get_expr_data_type());
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;
				$$ = new symbol_info($1->get_name(),"arg");
				$$->add_arg_type($1->get_expr_data_type());
		  }
	      ;
 
%%

int main(int argc, char *argv[])
{
	if(argc < 2) 
	{
		cout<<"Usage: "<<argv[0]<<" <input.c> [student_id]"<<endl;
		return 0;
	}
	string student_id = (argc >= 3) ? string(argv[2]) : string("student_id");
	string log_name = student_id + "_log.txt";
	string err_name = student_id + "_error.txt";

	yyin = fopen(argv[1], "r");
	outlog.open(log_name.c_str(), ios::trunc);
	outerror.open(err_name.c_str(), ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}

	symtab->enter_scope();

	yyparse();
	
	outlog << endl << "Total lines: " << lines << endl;
	outlog << "Total errors: " << semantic_error_count << endl;
	if (outerror.is_open())
		outerror << "Total errors: " << semantic_error_count << endl;
	
	outlog.close();
	outerror.close();
	
	fclose(yyin);
	
	return 0;
}