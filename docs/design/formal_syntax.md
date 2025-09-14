# Formal Syntax

The grammar for the BMath language is defined below using Extended Backus-Naur Form (EBNF). This file focuses on the formal grammar and lexical tokens.

## Grammar Rules

```ebnf
program          ::= expression*

expression       ::= assignment

block            ::= '{' expression ('\n' expression)* '}'

assignment       ::= ('local')? (IDENTIFIER '=')* logical_or

if_expression    ::= 'if' '(' expression ')' expression 
                     ('elif' '(' expression ')' expression)* 
                     'else' expression

logical_or       ::= logical_and ('|' logical_and)*

logical_and      ::= equality ('&' equality)*

equality         ::= relational (('==' | '!=' | 'is') relational)*

relational       ::= additive (('<' | '<=' | '>' | '>=') additive)*

additive         ::= multiplicative (('+' | '-') multiplicative)*

multiplicative   ::= exponentiation (('*' | '/') exponentiation)*

exponentiation   ::= pipeline ('^' pipeline)*

pipeline         ::= unary ('->' unary)*

unary            ::= ('-')? access

access           ::= module_access ('[' expression ']')*

module_access    ::= primary ('::' IDENTIFIER)*

primary          ::= NUMBER
                   | STRING  
                   | BOOLEAN
                   | IDENTIFIER
                   | type_literal
                   | function_literal
                   | vector_literal
                   | module_literal
                   | use_expression
                   | function_call
                   | block
                   | if_expression
                   | '(' expression ')'

function_call    ::= IDENTIFIER '(' argument_list? ')'
                   | '(' expression ')' '(' argument_list? ')'

argument_list    ::= expression (',' expression)*

function_literal ::= '|' parameter_list? '|' ('=>' type_literal)? expression

parameter_list   ::= parameter (',' parameter)*
parameter        ::= IDENTIFIER (':' type_literal)?

vector_literal   ::= '[' (expression (',' expression)*)? ']'

module_literal   ::= 'mod' IDENTIFIER? block

use_expression   ::= 'use' '(' use_target ')' ('as' IDENTIFIER)?

use_target       ::= STRING
                   | qualified_name
                   | STRING '::' IDENTIFIER
                   | qualified_name '::' IDENTIFIER
                   | STRING '::' '{' import_list '}'
                   | qualified_name '::' '{' import_list '}'

qualified_name   ::= IDENTIFIER ('::' IDENTIFIER)*

import_list      ::= import_item (',' import_item)*
import_item      ::= IDENTIFIER ('as' IDENTIFIER)?

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
complex          ::= (integer | real) 'i'
                   | 'i'
exponent         ::= [eE] [+-]? [0-9]+

STRING           ::= '"' string_char* '"'
string_char      ::= [^"\\] | escape_sequence
escape_sequence  ::= '\\' .

BOOLEAN          ::= 'true' | 'false'

WHITESPACE       ::= [ \t\r]+
NEWLINE          ::= '\n'
COMMENT          ::= '#' [^\n]*

LINE_CONTINUATION ::= '\\'
```

Lexical notes:

- Identifiers start with a letter or underscore and are followed by letters, digits or underscores.
- Numbers may be integers, floating point or complex (with trailing `i`).
- Strings use double quotes and support standard backslash escapes.
- Complex number parsing: `5i`, `3.14i`, or `i` (equivalent to `1i`).
- Scientific notation is supported: `1e5`, `2.5e-3`.
- Line continuation with backslash allows expressions to span multiple lines.
- Comments extend from `#` to end of line.

## Operator Precedence (highest to lowest)

1. Postfix operators: `[]` (indexing)
2. Binary operators: `::` (module access)
3. Unary operators: `-` (negation)
4. Pipeline: `->` (left associative)
5. Exponentiation: `^` (right associative)
6. Multiplicative: `*`, `/` (left associative)
7. Additive: `+`, `-` (left associative)
8. Relational: `<`, `<=`, `>`, `>=` (left associative)
9. Equality: `==`, `!=`, `is` (left associative)
10. Logical AND: `&` (left associative)
11. Logical OR: `|` (left associative)
12. Assignment: `=` (right associative)

Design note: module (`mod`) and `use` semantics, and higher-level indexing/assignment behavior for the bracket operator are design-level concerns and are documented in `docs/design/constructs.md` (they are not part of the formal grammar here).

Semantic note: `use` expressions now always use a parenthesized target; for example `use("module"::member)` or `use(module::{a, b})`. `use` with qualified names and destructured imports automatically create variable bindings for the imported identifiers. This automatic binding behavior improves developer experience while maintaining expression-oriented design—the expressions still return values that can be used in larger expressions.
