# Formal Syntax

The grammar for the BMath language is defined below using Extended Backus-Naur Form (EBNF). This file focuses on the formal grammar and lexical tokens.

## Grammar Rules

```ebnf
program          ::= expression

expression       ::= local_assignment

local_assignment ::= 'local' IDENTIFIER (':' type_literal)? '=' expression
                   | assignment_expression

assignment_expression ::= logical_or_expression ('=' assignment_expression)?

logical_or_expression ::= logical_and_expression ('|' logical_and_expression)*

logical_and_expression ::= equality_expression ('&' equality_expression)*

equality_expression ::= relational_expression (('==' | '!=' | 'is') relational_expression)*

relational_expression ::= additive_expression (('<' | '<=' | '>' | '>=') additive_expression)*

additive_expression ::= multiplicative_expression (('+' | '-') multiplicative_expression)*

multiplicative_expression ::= exponentiation_expression (('*' | '/' | '%') exponentiation_expression)*

exponentiation_expression ::= pipeline_expression ('^' exponentiation_expression)?

pipeline_expression ::= unary_expression ('->' unary_expression)*

unary_expression ::= ('-' | '!')? access_expression

access_expression ::= module_access_expression ('[' expression ']' | '!')*

module_access_expression ::= call_expression ('::' IDENTIFIER)*

call_expression ::= primary_expression ('(' argument_list? ')')*

primary_expression ::= NUMBER
                     | STRING  
                     | BOOLEAN
                     | IDENTIFIER
                     | type_literal
                     | function_literal
                     | vector_literal
                     | module_literal
                     | use_expression
                     | block_expression
                     | if_expression
                     | '(' expression ')'

block_expression ::= '{' block_body '}'

block_body       ::= expression (';'? expression)*

if_expression    ::= 'if' '(' expression ')' expression 
                     ('elif' '(' expression ')' expression)* 
                     'else' expression

function_literal ::= '|' parameter_list? '|' ('=>' type_literal)? expression

parameter_list   ::= parameter (',' parameter)*
parameter        ::= IDENTIFIER (':' type_literal)?

vector_literal   ::= '[' (expression (',' expression)*)? ']'

module_literal   ::= 'mod' IDENTIFIER? block_expression

use_expression   ::= 'use' '(' use_target ')'

use_target       ::= (STRING | qualified_name) use_specifier?

use_specifier    ::= '::' use_members
                   | 'as' IDENTIFIER

use_members      ::= use_member
                   | '{' use_member_list '}'

use_member_list  ::= use_member (',' use_member)*
use_member       ::= IDENTIFIER ('as' IDENTIFIER)? ('::' use_members)?

qualified_name   ::= IDENTIFIER ('::' IDENTIFIER)*

argument_list    ::= expression (',' expression)*

type_literal     ::= 'Int' | 'Real' | 'Complex' | 'Bool' | 'Vec' | 'Seq' 
                   | 'Function' | 'Any' | 'Number' | 'Type' | 'String' | 'Module'
```

## Lexical Rules

```ebnf
IDENTIFIER       ::= [a-zA-Z_][a-zA-Z0-9_]*

NUMBER           ::= integer | real | complex
integer          ::= [0-9]+
real             ::= [0-9]* '.' [0-9]+ (exponent)?
                   | [0-9]+ exponent
complex          ::= (integer | real) [iI]
                   | [iI]
exponent         ::= [eE] [+-]? [0-9]+

STRING           ::= '"' string_char* '"'
string_char      ::= [^"\\] | escape_sequence
escape_sequence  ::= '\\' [ntr"\\]

BOOLEAN          ::= 'true' | 'false'

WHITESPACE       ::= [ \t\r]+
NEWLINE          ::= '\n'
COMMENT          ::= '#' [^\n]*

LINE_CONTINUATION ::= '\\' NEWLINE
```

## Operator Precedence (highest to lowest)

Complete precedence table reflecting actual parser implementation:

1. **Array indexing**: `[]` *(precedence 85)*
2. **Closure capture**: `!` *(precedence 82)*
3. **Function calls**: `func()` *(precedence 80)*
4. **Module access**: `::` *(precedence 78)*
5. **Chain operator**: `->` *(precedence 75)*
6. **Unary operators**: `-`, `!` *(precedence 70)*
7. **Exponentiation**: `^` *(precedence 60, right associative)*
8. **Multiplicative**: `*`, `/`, `%` *(precedence 50)*
9. **Additive**: `+`, `-` *(precedence 40)*
10. **Relational**: `<`, `<=`, `>`, `>=` *(precedence 30)*
11. **Equality**: `==`, `!=`, `is` *(precedence 25)*
12. **Logical AND**: `&` *(precedence 20)*
13. **Logical OR**: `|` *(precedence 15)*
14. **Assignment**: `=` *(precedence 5, right associative)*

## Lexical Notes

- **Identifiers**: Start with letter or underscore, followed by letters, digits, or underscores
- **Numbers**: Support integers, floating point, and complex (with trailing `i` or `I`)
- **Complex numbers**: `5i`, `3.14i`, or `i` (equivalent to `1i`)
- **Scientific notation**: `1e5`, `2.5e-3`, `1.5e+10`
- **Strings**: Use double quotes with escape sequences: `\n`, `\t`, `\r`, `\"`, `\\`
- **Line continuation**: Backslash `\` allows expressions to span multiple lines
- **Comments**: Hash `#` extends to end of line
- **Whitespace**: Spaces, tabs, and carriage returns are ignored
- **Newlines**: Significant for expression separation outside blocks

## Grammar Notes

### Dual-Purpose `|` Token

- **Prefix context**: Function parameter delimiter `|param| body`
- **Infix context**: Logical OR operator `a | b`

### Expression-Oriented Design

- Every construct evaluates to a value
- Blocks return their last expression's value
- Assignments return the assigned value
- Conditionals require `else` clause and return chosen branch value

### Right-Associative Operators

- **Exponentiation**: `2^3^4` → `2^(3^4)`
- **Assignment**: `a = b = c` → `a = (b = c)`

### Postfix Operators

- **Function calls**: `func(args)` - multiple calls chain left-to-right
- **Array indexing**: `arr[index]` - multiple indices chain left-to-right
- **Closure capture**: `var!` - captures variable from outer scope
- **Module access**: `module::member` - accesses module members

### Block Syntax

- **Required braces**: `{` and `}` delimit block boundaries
- **Optional semicolons**: Expressions can be separated by `;` or newlines
- **Scoped**: Creates new lexical scope for local variables
- **Non-empty**: Must contain at least one expression

### Conditional Syntax

- **Mandatory parentheses**: Conditions must be wrapped in `()`
- **Required else**: All conditionals must have an `else` clause
- **Expression form**: Can be used anywhere an expression is expected
- **Chaining**: `elif` allows multiple conditions

### Use Expression Syntax

- **Parenthesized target**: Always uses `use(target)` form
- **Flexible imports**: Supports simple, aliased, and destructured imports
- **Automatic binding**: Creates local variables for imported identifiers
- **Nested access**: Supports `module::sub::member` patterns
