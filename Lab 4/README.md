# Lab 4 — Two-Pass C Subset Compiler

A **Flex + Yacc/Bison** front end for a small C-like language. It tokenizes and parses source code, maintains **nested scopes** in a symbol table, builds an **abstract syntax tree (AST)**, and emits **three-address code (3AC)** to a text file.

## What it does

- **Lexical analysis** (`lex_analyzer.l`): keywords, identifiers, literals, operators, and punctuation for control flow, types, `printf`-style output, arrays, and common C operators.
- **Syntax + semantic scaffolding** (`syntax_analyzer.y`): grammar actions attach AST nodes, drive scope enter/exit, and log reductions.
- **Symbol table** (`symbol_table.h`, `scope_table.h`, `symbol_info.h`): hierarchical scopes with insert/lookup aligned with block structure.
- **Code generation** (`ast.h`, `three_addr_code.h`): walks the AST and prints 3AC using temporaries (`t0`, `t1`, …) and labels (`L0`, `L1`, …).

## Outputs

When you run the compiler, it writes (by default next to the executable):

| File        | Contents                                       |
| ----------- | ---------------------------------------------- |
| `log.txt`   | Parse trace, scope events, symbol table dump   |
| `error.txt` | Syntax/semantic error messages with line hints |
| `code.txt`  | Generated three-address code                   |

## Prerequisites

- **GNU Bison** or **Berkeley Yacc** (`yacc` producing `y.tab.c` / `y.tab.h`)
- **Flex** (`flex` → `lex.yy.c`)
- **g++** (C++11 or later is typical for this codebase)

On Windows, use **WSL**, **MSYS2/MinGW**, or **Git Bash** with those tools installed so `yacc`, `flex`, and `g++` are on your `PATH`.

## Build and run

### Using the provided script

From this directory:

```bash
chmod +x script.sh   # once, on Unix-like shells
./script.sh
```

The script:

1. Runs `yacc -d -y --debug --verbose syntax_analyzer.y`
2. Runs `flex lex_analyzer.l`
3. Compiles `y.tab.c` and `lex.yy.c` into objects and links **`two_pass_compiler`**
4. Runs `./two_pass_compiler input.c`
5. Prints `log.txt`, `error.txt`, and `code.txt`

### Compile another source file

After a successful build:

```bash
./two_pass_compiler path/to/yourfile.c
```

Replace the filename in `script.sh` or invoke the binary directly as above.

### Manual build (same steps as the script)

```bash
yacc -d -y --debug --verbose syntax_analyzer.y
g++ -w -c -o y.o y.tab.c
flex lex_analyzer.l
g++ -fpermissive -w -c -o l.o lex.yy.c
g++ y.o l.o -o two_pass_compiler
./two_pass_compiler input.c
```

## Project layout

| Path                                               | Role                                                                                |
| -------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `lex_analyzer.l`                                   | Flex specification (tokens → parser)                                                |
| `syntax_analyzer.y`                                | Yacc grammar, AST wiring, symbol table updates                                      |
| `ast.h`                                            | AST node hierarchy and `generate_code` visitors                                     |
| `three_addr_code.h`                                | 3AC driver; delegates to the AST root                                               |
| `symbol_table.h`, `scope_table.h`, `symbol_info.h` | Scopes and symbol metadata                                                          |
| `input.c`                                          | Default sample input for `script.sh`                                                |
| `InputOutput/`                                     | Extra sample inputs and expected-style logs/errors/code (if provided with your lab) |
