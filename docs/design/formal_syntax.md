# Formal Syntax

The grammar for the BMath language is defined below using Extended Backus-Naur Form (EBNF). This file focuses on the formal grammar and lexical tokens.

## Grammar Rules

```ebnf
program          ::= expression

expression       ::= declaration_expression

declaration_expression ::= immutable_declaration
                         | mutable_declaration  
                         | assignment_expression

immutable_declaration ::= IDENTIFIER (':' type_literal)? ':=' expression

mutable_declaration ::= IDENTIFIER (':' type_literal)? ';=' expression

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

access_expression ::= module_access_expression ('[' expression ']')*

module_access_expression ::= call_expression ('::' IDENTIFIER)*

call_expression ::= primary_expression ('(' argument_list? ')')*

primary_expression ::= NUMBER
                     | STRING  
                     | BOOLEAN
                     | IDENTIFIER
                     | module_qualified_identifier
                     | type_literal
                     | function_literal
                     | vector_literal
                     | module_literal
                     | use_expression
                     | block_expression
                     | if_expression
                     | '(' expression ')'

module_qualified_identifier ::= 'this' '::' IDENTIFIER

block_expression ::= '{' block_body '}'

block_body       ::= expression (expression)*

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

Complete precedence table reflecting the updated parser implementation:

1. **Vector indexing**: `[]` *(precedence 80)*
2. **Function calls**: `func()` *(precedence 80)*
3. **Module access**: `::` *(precedence 78)*
4. **Chain operator**: `->` *(precedence 75)*
5. **Unary operators**: `-`, `!` *(precedence 70)*
6. **Exponentiation**: `^` *(precedence 60, right associative)*
7. **Multiplicative**: `*`, `/`, `%` *(precedence 50)*
8. **Additive**: `+`, `-` *(precedence 40)*
9. **Relational**: `<`, `<=`, `>`, `>=` *(precedence 30)*
10. **Equality**: `==`, `!=`, `is` *(precedence 25)*
11. **Logical AND**: `&` *(precedence 20)*
12. **Logical OR**: `|` *(precedence 15)*
13. **Assignment**: `=` *(precedence 5, right associative)*
14. **Mutable declaration**: `;=` *(precedence 1, right associative)*
15. **Immutable declaration**: `:=` *(precedence 1, right associative)*

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

### Declaration vs Assignment

- **Immutable declaration**: `:=` creates a new immutable binding
- **Mutable declaration**: `;=` creates a new mutable binding  
- **Assignment**: `=` modifies existing mutable bindings only

### Dual-Purpose `|` Token

- **Prefix context**: Function parameter delimiter `|param| body`
- **Infix context**: Logical OR operator `a | b`

### Expression-Oriented Design

- Every construct evaluates to a value
- Blocks return their last expression's value
- Declarations return the declared value
- Conditionals require `else` clause and return chosen branch value

### Right-Associative Operators

- **Exponentiation**: `2^3^4` → `2^(3^4)`
- **Assignment**: `a = b = c` → `a = (b = c)`
- **Declarations**: `a := b := c` → `a := (b := c)`

### Postfix Operators

- **Function calls**: `func(args)` - multiple calls chain left-to-right
- **Array indexing**: `arr[index]` - multiple indices chain left-to-right
- **Module access**: `module::member` - accesses module members

### Block Syntax

- **Required braces**: `{` and `}` delimit block boundaries
- **No semicolons**: Expressions are separated by newlines only
- **Scoped**: Creates new lexical scope for variables
- **Non-empty**: Must contain at least one expression

### Conditional Syntax

- **Mandatory parentheses**: Conditions must be wrapped in `()`
- **Required else**: All conditionals must have an `else` clause
- **Expression form**: Can be used anywhere an expression is expected
- **Chaining**: `elif` allows multiple conditions

### Use Expression Syntax

- **Parenthesized target**: Always uses `use(target)` form
- **Flexible imports**: Supports simple, aliased, and destructured imports
- **Automatic binding**: Creates immutable bindings for imported identifiers
- **Nested access**: Supports `module::sub::member` patterns

### Module Access Syntax

- **Explicit module access**: `this::identifier` for accessing module-level variables
- **High precedence**: Module access binds tighter than most operators
- **Chained access**: Can be combined with regular member access

## Operator Changes from Previous Version

### Removed Operators

- **Closure capture**: `!` (postfix) - removed in favor of implicit capture

### Modified Operators

- **Declaration operators**: Added `:=` (immutable) and `;=` (mutable)
- **Module access**: `this::` added for explicit module scope access

### Precedence Updates

- **Closure capture**: Removed from precedence table
- **Declaration operators**: Added at lowest precedence level
- **Module access**: Clarified precedence for `this::` syntax

## Expression Parsing Examples

```bmath
# Immutable declarations
pi := 3.14159
name := "BMath"

# Mutable declarations  
counter ;= 0
data ;= [1, 2, 3]

# Assignments (only to mutable variables)
counter = counter + 1
data[0] = 10

# Module access in functions
my_func := |x| this::pi * x

# Chained operations
result := data->map(|x| x * 2)->filter(|x| x > 5)

# Complex expressions with precedence
value := a := b + c->func() * 2  # parsed as: value := (a := ((b + (c->func())) * 2))
```
