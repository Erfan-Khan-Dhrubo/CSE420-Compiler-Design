# Lexical and Syntax Analyzer for C-like Language

## Overview

This project implements a lexical analyzer and syntax analyzer for a subset of the C programming language using Flex (lexical analyzer generator) and Bison (parser generator). The analyzer can parse and validate C-like programs, generating tokens and parsing trees while logging the process.

## Features

- **Lexical Analysis**: Tokenizes input source code into keywords, identifiers, constants, operators, and punctuation.
- **Syntax Analysis**: Parses the tokenized input according to a defined grammar for a C-like language.
- **Logging**: Generates detailed logs of token recognition and parsing steps.
- **Error Handling**: Reports syntax errors with line numbers.
- **Support for**: Variables, functions, arrays, control structures (if-else, for, while), expressions, and basic I/O (printf).

## Supported Language Constructs

### Data Types

- `int`, `float`, `void`, `char`, `double`

### Control Structures

- `if` / `else if` / `else`
- `for` loops
- `while` loops
- `switch` / `case` / `default` (tokens defined, but parsing may be limited)

### Operators

- Arithmetic: `+`, `-`, `*`, `/`, `%`
- Relational: `<`, `>`, `<=`, `>=`, `==`, `!=`
- Logical: `&&`, `||`, `!`
- Assignment: `=`
- Increment/Decrement: `++`, `--`

### Other Features

- Function definitions and calls
- Variable declarations (including arrays)
- Expressions with proper precedence
- `printf` statements
- `return` statements

## File Structure

- `Lexical_Analyzer.l`: Flex specification file defining lexical rules and token patterns
- `Syntax_Analyzer.y`: Bison grammar file defining the syntax rules for the language
- `symbol_info.h`: Header file containing the `symbol_info` class for storing symbol information
- `script.sh`: Bash script to compile and run the analyzer
- `input.txt`, `input1.txt`, `input2.txt`: Sample input files for testing
- `README.md`: This documentation file

## Requirements

- Flex (lexical analyzer generator)
- Bison (parser generator)
- GCC (GNU Compiler Collection) with C++ support
- Bash shell (for running the script)

### Installation on Ubuntu/Debian

```bash
sudo apt update
sudo apt install flex bison gcc g++
```

### Installation on macOS

```bash
brew install flex bison gcc
```

### Installation on Windows

- Install Flex and Bison via MSYS2 or Cygwin
- Or use WSL (Windows Subsystem for Linux)

## How to Run

1. Make the script executable:

   ```bash
   chmod +x script.sh
   ```

2. Run the script with an input file:
   ```bash
   ./script.sh input.txt
   ```
   Replace `input.txt` with `input1.txt` or `input2.txt` for other test cases.

The script will:

- Generate the parser files using Bison
- Generate the lexer files using Flex
- Compile the C++ code
- Run the analyzer on the specified input file
- Output parsing logs to `my_log.txt`
- Display token recognition and parsing steps on the console

## Output

- **Console Output**: Shows token recognition with line numbers and lexemes
- **Log File (`my_log.txt`)**: Contains detailed parsing information including:
  - Grammar rule reductions
  - Symbol information
  - Line counts
  - Error messages (if any)

## Example Usage

```bash
$ ./script.sh input1.txt
Generated the parser C file as well the header file
Generated the parser object file
Generated the scanner C file
Generated the scanner object file
All ready, running
Line no 1: Token <INT> Lexeme int found

... (token output continues)

At line no: 1 start : program

... (parsing output continues)

Number of lines: 15
```

## Understanding the Code

### Lexical Analyzer (`Lexical_Analyzer.l`)

- Defines regular expressions for tokens
- Uses `symbol_info` objects to pass semantic values
- Tracks line numbers for error reporting
- Outputs token information to console and log

### Syntax Analyzer (`Syntax_Analyzer.y`)

- Defines grammar rules for the C-like language
- Uses a recursive descent parsing approach
- Builds abstract syntax trees using `symbol_info` objects
- Logs each grammar rule reduction

### Symbol Info (`symbol_info.h`)

- Simple class to store symbol names and types
- Used throughout the parsing process to maintain symbol information

## Limitations

- Limited error recovery
- No semantic analysis (type checking, etc.)
- Subset of C language features implemented
- No code generation
- Basic `printf` support only
