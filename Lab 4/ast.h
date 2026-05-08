#ifndef AST_H
#define AST_H

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <map>

using namespace std;

class ASTNode {
public:
    virtual ~ASTNode() {}
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp, int& temp_count, int& label_count) const = 0;
};

// Expression node types

class ExprNode : public ASTNode {
protected:
    string node_type; // Type information (int, float, void, etc.)
public:
    ExprNode(string type) : node_type(type) {}
    virtual string get_type() const { return node_type; }
};

// Variable node (for ID references)

class VarNode : public ExprNode {
private:
    string name;
    ExprNode* index; // For array access, nullptr for simple variables

public:
    VarNode(string name, string type, ExprNode* idx = nullptr)
        : ExprNode(type), name(name), index(idx) {}
    
    ~VarNode() { if(index) delete index; }
    
    bool has_index() const { return index != nullptr; }
    
    string generate_index_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                              int& temp_count, int& label_count) const {
        // TODO: Implement this method
        // Should generate code to calculate the array index and return the temp variable
        if (index)
            return index->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        return "";
        
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // For scalar variables, load once into a temp and reuse it.
        if (index) {
            string idx = index->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            string t = "t" + to_string(temp_count++);
            outcode << t << " = " << name << "[" << idx << "]" << endl;
            return t;
        }

        if (!symbol_to_temp.count(name)) {
            symbol_to_temp[name] = "";
        }

        if (symbol_to_temp[name].empty()) {
            string t = "t" + to_string(temp_count++);
            symbol_to_temp[name] = t;
            outcode << t << " = " << name << endl;
        }

        return symbol_to_temp[name];
        
    }
    
    string get_name() const { return name; }
};

// Constant node

class ConstNode : public ExprNode {
private:
    string value;

public:
    ConstNode(string val, string type) : ExprNode(type), value(val) {}
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for constant values
        string t = "t" + to_string(temp_count++);
        outcode << t << " = " << value << endl;
        return t;
        
    }
};

// Binary operation node

class BinaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* left;
    ExprNode* right;

public:
    BinaryOpNode(string op, ExprNode* left, ExprNode* right, string result_type)
        : ExprNode(result_type), op(op), left(left), right(right) {}
    
    ~BinaryOpNode() {
        delete left;
        delete right;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for binary operations
        string l = left->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string r = right->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        string t = "t" + to_string(temp_count++);
        outcode << t << " = " << l << " " << op << " " << r << endl;
        return t;
    }
};

// Unary operation node

class UnaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* expr;

public:
    UnaryOpNode(string op, ExprNode* expr, string result_type)
        : ExprNode(result_type), op(op), expr(expr) {}
    
    ~UnaryOpNode() { delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for unary operations
        string e = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string t = "t" + to_string(temp_count++);
        outcode << t << " = " << op << e << endl;
        return t;

    }
};

// Assignment node

class AssignNode : public ExprNode {
private:
    VarNode* lhs;
    ExprNode* rhs;

public:
    AssignNode(VarNode* lhs, ExprNode* rhs, string result_type)
        : ExprNode(result_type), lhs(lhs), rhs(rhs) {}
    
    ~AssignNode() {
        delete lhs;
        delete rhs;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for assignment operations
        string l = lhs->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string r = rhs->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        outcode << l << " = " << r << endl;
        return l;

    }
};

// Statement node types

class StmtNode : public ASTNode {
public:
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                                int& temp_count, int& label_count) const = 0;
};

// Expression statement node

class ExprStmtNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ExprStmtNode(ExprNode* e) : expr(e) {}
    ~ExprStmtNode() { if(expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for expression statements
        if (expr)
            expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        return "";
    }
};

// Block (compound statement) node

class BlockNode : public StmtNode {
private:
    vector<StmtNode*> statements;

public:
    ~BlockNode() {
        for (auto stmt : statements) {
            delete stmt;
        }
    }
    
    void add_statement(StmtNode* stmt) {
        if (stmt) statements.push_back(stmt);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for all statements in the block
        for (auto stmt : statements) {
            stmt->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

// If statement node

class IfNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* then_block;
    StmtNode* else_block; // nullptr if no else part

public:
    IfNode(ExprNode* cond, StmtNode* then_stmt, StmtNode* else_stmt = nullptr)
        : condition(cond), then_block(then_stmt), else_block(else_stmt) {}
    
    ~IfNode() {
        delete condition;
        delete then_block;
        if (else_block) delete else_block;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string cond = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        if (else_block) {
            string Lthen = "L" + to_string(label_count++);
            string Lelse = "L" + to_string(label_count++);
            string Lend = "L" + to_string(label_count++);

            outcode << "if " << cond << " goto " << Lthen << endl;
            outcode << "goto " << Lelse << endl;
            outcode << Lthen << ":" << endl;
            then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "goto " << Lend << endl;
            outcode << Lelse << ":" << endl;
            else_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << Lend << ":" << endl;
        } else {
            string Lthen = "L" + to_string(label_count++);
            string Lfalse = "L" + to_string(label_count++);
            string Lafter = "L" + to_string(label_count++);

            outcode << "if " << cond << " goto " << Lthen << endl;
            outcode << "goto " << Lfalse << endl;
            outcode << Lthen << ":" << endl;
            then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "goto " << Lafter << endl;
            outcode << Lfalse << ":" << endl;
            outcode << Lafter << ":" << endl;
        }
        return "";
    }
};

// While statement node

class WhileNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* body;

public:
    WhileNode(ExprNode* cond, StmtNode* body_stmt)
        : condition(cond), body(body_stmt) {}
    
    ~WhileNode() {
        delete condition;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for while loops
        string Lstart = "L" + to_string(label_count++);
        string Lend   = "L" + to_string(label_count++);

        outcode << Lstart << ":" << endl;
        string cond = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "ifFalse " << cond << " goto " << Lend << endl;

        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << Lstart << endl;
        outcode << Lend << ":" << endl;
        
        return "";
    }
};

// For statement node

class ForNode : public StmtNode {
private:
    ExprNode* init;
    ExprNode* condition;
    ExprNode* update;
    StmtNode* body;

public:
    ForNode(ExprNode* init_expr, ExprNode* cond_expr, ExprNode* update_expr, StmtNode* body_stmt)
        : init(init_expr), condition(cond_expr), update(update_expr), body(body_stmt) {}
    
    ~ForNode() {
        if (init) delete init;
        if (condition) delete condition;
        if (update) delete update;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for for loops
        if (init)
            init->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        string Lcond = "L" + to_string(label_count++);
        string Lend  = "L" + to_string(label_count++);

        outcode << Lcond << ":" << endl;
        string cond = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "ifFalse " << cond << " goto " << Lend << endl;

        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (update)
            update->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        outcode << "goto " << Lcond << endl;
        outcode << Lend << ":" << endl;

        return "";
    }
};

// Return statement node

class ReturnNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ReturnNode(ExprNode* e) : expr(e) {}
    ~ReturnNode() { if (expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for return statements
        if (expr) {
            string r = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "return " << r << endl;
        } else {
            outcode << "return" << endl;
        }

        return "";
    }
};

// Declaration node

class DeclNode : public StmtNode {
private:
    string type;
    vector<pair<string, int>> vars; // Variable name and array size (0 for regular vars)

public:
    DeclNode(string t) : type(t) {}
    
    void add_var(string name, int array_size = 0) {
        vars.push_back(make_pair(name, array_size));
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto& v : vars) {
            outcode << "// Declaration: " << type << " " << v.first << endl;
            if (symbol_to_temp.count(v.first)) {
                // Keep temp numbering aligned for shadowed declarations.
                temp_count++;
            } else {
                // Mark as declared; first use allocates the actual temp.
                symbol_to_temp[v.first] = "";
            }
        }

        return "";
    }
    
    string get_type() const { return type; }
    const vector<pair<string, int>>& get_vars() const { return vars; }
};

// Function declaration node

class FuncDeclNode : public ASTNode {
private:
    string return_type;
    string name;
    vector<pair<string, string>> params; // Parameter type and name
    BlockNode* body;

public:
    FuncDeclNode(string ret_type, string n) : return_type(ret_type), name(n), body(nullptr) {}
    ~FuncDeclNode() { if (body) delete body; }
    
    void add_param(string type, string name) {
        params.push_back(make_pair(type, name));
    }
    
    void set_body(BlockNode* b) {
        body = b;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        outcode << "// Function: " << return_type << " " << name << "()" << endl;

        for (auto& p : params) {
            symbol_to_temp[p.second] = p.second;
            outcode << "param " << p.second << endl;
        }

        if (body)
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        return "";
    }
};

// Helper class for function arguments

class ArgumentsNode : public ASTNode {
private:
    vector<ExprNode*> args;

public:
    ~ArgumentsNode() {
        // Don't delete args here - they'll be transferred to FuncCallNode
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) args.push_back(arg);
    }
    
    ExprNode* get_argument(int index) const {
        if (index >= 0 && index < args.size()) {
            return args[index];
        }
        return nullptr;
    }
    
    size_t size() const {
        return args.size();
    }
    
    const vector<ExprNode*>& get_arguments() const {
        return args;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // This node doesn't generate code directly
        return "";
    }
};

// Function call node

class FuncCallNode : public ExprNode {
private:
    string func_name;
    vector<ExprNode*> arguments;

public:
    FuncCallNode(string name, string result_type)
        : ExprNode(result_type), func_name(name) {}
    
    ~FuncCallNode() {
        for (auto arg : arguments) {
            delete arg;
        }
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) arguments.push_back(arg);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for function calls

        for (auto arg : arguments) {
            string a = arg->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "param " << a << endl;
}

        string t = "t" + to_string(temp_count++);
        outcode << t << " = call " << func_name << ", " << arguments.size() << endl;
        return t;
    }
};

// Program node (root of AST)

class ProgramNode : public ASTNode {
private:
    vector<ASTNode*> units;

public:
    ~ProgramNode() {
        for (auto unit : units) {
            delete unit;
        }
    }
    
    void add_unit(ASTNode* unit) {
        if (unit) units.push_back(unit);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for the entire program
        for (auto unit : units)
            unit->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        return "";
    }
};

#endif // AST_H