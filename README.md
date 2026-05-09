# CSE420 — Compiler Design

Course repository for **Compiler Design (CSE420)**. The labs build a compiler pipeline for a **C-like subset** using **Flex** (lexical analysis), **Yacc/Bison** (parsing), and **C++** for the driver, symbol tables, and—by the final lab—an abstract syntax tree and three-address code generation.

Each lab is self-contained with its own source files, build script, and documentation.

---

## Repository overview

| Lab | Focus | Highlights |
|-----|--------|------------|
| [**Lab 1**](Lab%201/) | Lexical & syntax analysis | Flex lexer, Bison grammar, token/trace logging |
| [**Lab 2**](Lab%202/) | Front end + symbol tables | Scoped hash-based symbol tables, `my_log.txt` |
| [**Lab 3**](Lab%203/) | Syntax & semantic analysis | Semantic checks, `log.txt` / `error.txt` |
| [**Lab 4**](Lab%204/) | Two-pass compiler | AST (`ast.h`), three-address code (`three_addr_code.h`, `code.txt`) |

For build commands, sample inputs, and file-level descriptions, open the **README.md** inside each lab directory.

---

## Prerequisites

Install these tools and ensure they are on your `PATH`:

- **Flex** (`flex`)
- **Yacc** or **GNU Bison** (often invoked as `yacc -y` or `bison -y`)
- **G++** with C++11 or later

**Linux (Debian/Ubuntu):**

```bash
sudo apt update
sudo apt install flex bison gcc g++
```

**macOS (Homebrew):**

```bash
brew install flex bison gcc
```

**Windows:** Use [WSL](https://learn.microsoft.com/en-us/windows/wsl/), [MSYS2](https://www.msys2.org/), or Git Bash with Flex, Bison, and MinGW-w64 `g++` installed so shell scripts and generated executables (e.g. `a.exe`) work as documented in each lab.

---

## Quick start

1. Open the lab you need (e.g. `Lab 4/`).
2. Read that lab’s `README.md` for exact outputs and flags.
3. From that lab’s directory, run the provided build script (typically `bash script.sh` or `./script.sh` after `chmod +x script.sh` on Unix).

Generated artifacts vary by lab (for example: `my_log.txt`, `log.txt`, `error.txt`, `code.txt`, and the executable name). The per-lab README lists what to expect.

---

## Project structure (high level)

```
CSE420-Compiler-Design/
├── README.md                 # This file
├── Lab 1/                    # Lexer + parser; Lexical_Analyzer.l, Syntax_Analyzer.y
├── Lab 2/                    # MiniCompiler: lex, yacc, scoped symbol tables
├── Lab 3/                    # Semantic analysis; log/error files
├── Lab 4/                    # AST + three-address code; two_pass_compiler
```

Sample programs and reference-style outputs are under each lab’s `InputOutput/` folder where present.

---

## Disclaimer

This codebase is **educational**: it targets a restricted subset of C, emphasizes compiler front-end concepts, and is not intended as a production compiler.
