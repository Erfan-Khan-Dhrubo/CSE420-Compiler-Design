# Lab 3 — Syntax & Semantic Analyzer (C-like subset)

Course project for **CSE420 Compiler Design**: a **Flex** scanner and **Yacc** parser that recognize a restricted C-style language, build **scoped symbol tables**, and perform **semantic checks** while logging the parse and reporting errors.

## What it does

- **Lexical analysis** (`lex_analyzer.l`): tokenizes keywords, identifiers, literals, operators, and punctuation for the grammar used in `syntax_analyzer.y`.
- **Syntax analysis** (`syntax_analyzer.y`): LALR grammar for declarations, functions, statements, and expressions.
- **Symbol tables** (`symbol_table.h`, `scope_table.h`, `symbol_info.h`): stack of scopes (e.g. global, function body, nested blocks) backed by hash buckets; supports insert, lookup in current scope, and lookup up the scope chain.
- **Outputs**:
  - **`log.txt`** — rule reductions / trace information and printed symbol tables (opened in append mode).
  - **`error.txt`** — messages from `yyerror` and semantic errors (append mode).

The driver expects **exactly one argument**: the path to a source file.

## Prerequisites

- **Flex** (`flex`)
- **Yacc** (POSIX `yacc`, or **Bison** used as Yacc, e.g. `bison -y`)
- **G++** with C++11 or later (project uses `std::vector`, `std::string`, etc.)

On Windows, a typical setup is **MSYS2** / **MinGW-w64** so `g++` produces `a.exe` and shell scripts run in Git Bash or MSYS.

## Build

### Using the provided script

From this directory:

```bash
bash script.sh
```

The script runs `yacc` on `syntax_analyzer.y`, `flex` on `lex_analyzer.l`, compiles `y.tab.c` and `lex.yy.c` to objects, links them into an executable, then runs `./a.exe input.c` as a sample.

Adjust the last line of `script.sh` if you want a different input file, or run the executable manually after a successful link.

### Manual build (same steps as `script.sh`)

```bash
yacc -d -y --debug --verbose syntax_analyzer.y
flex lex_analyzer.l
g++ -w -c -o y.o y.tab.c
g++ -fpermissive -w -c -o l.o lex.yy.c
g++ y.o l.o -o analyzer
```

On MinGW the default output may be `a.exe` instead of `analyzer` if you use `g++ y.o l.o` with no `-o` flag.

## Run

```bash
./analyzer your_program.c
```

If you built without `-o`:

```bash
./a.exe your_program.c    # Windows / MinGW
./a.out your_program.c    # typical Linux default name
```

Without exactly one filename, the program prints `Please input file name` and exits. If the file cannot be opened, it prints `Couldn't open file`.

After a run, inspect **`log.txt`** and **`error.txt`** in the **current working directory** (they are opened with append, so repeated runs accumulate unless you delete or truncate them first).

## Project layout

| File / folder       | Role                                                           |
| ------------------- | -------------------------------------------------------------- |
| `lex_analyzer.l`    | Flex specification (tokens → parser)                           |
| `syntax_analyzer.y` | Yacc grammar, semantic actions, `main()`                       |
| `symbol_info.h`     | Symbol metadata (name, type, function flags, parameters, etc.) |
| `scope_table.h`     | Per-scope hash table of symbols                                |
| `symbol_table.h`    | Scope stack: enter/exit scope, insert, lookup                  |
| `script.sh`         | Build and sample run                                           |
| `input.c`           | Default sample input used by the script                        |
| `InputOutput/`      | Extra sample sources and reference `log*.txt` / `error*.txt`   |
