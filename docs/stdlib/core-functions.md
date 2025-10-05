<!-- Auto-generated from stdlib_signatures.json - DO NOT EDIT MANUALLY -->
<!-- Version: 0.12.0 -->

## Core Functions

### `exit`

Exits the program with an optional exit code

**Signature:**

```bmath
|code?: Int| -> Any
```

**Parameters:**

- `code: Int` (optional): Exit code (defaults to 0)

**Returns:** `Any`

---

### `try_or`

Executes a function and returns its result, or a default value if an exception occurs

**Signature:**

```bmath
|fn: Function, default: Any| -> Any
```

**Parameters:**

- `fn: Function`: Function to try executing
- `default: Any`: Default value to return on error

**Returns:** `Any`

---

### `try_catch`

Executes a function and returns its result, or passes the exception to a handler function

**Signature:**

```bmath
|fn: Function, handler: Function| -> Any
```

**Parameters:**

- `fn: Function`: Function to try executing
- `handler: Function`: Handler function that receives error

**Returns:** `Any`

---

### `print`

Prints any number of values separated by a single space

**Signature:**

```bmath
|...values: Any| -> Any | Vec
```

**Parameters:**

- `values: Any` (variadic): Values to print

**Returns:** `Any | Vec`

---

### `help`

Display help information for a function or value

**Signature:**

```bmath
|value?: Any| -> String
```

**Parameters:**

- `value: Any` (optional): Function or value to get help for

**Returns:** `String`

**Examples:**

```bm
help(sqrt)
```

```bm
help(print)
```

```bm
help(map)
```

---
