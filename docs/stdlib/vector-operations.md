<!-- Auto-generated from stdlib_signatures.json - DO NOT EDIT MANUALLY -->
<!-- Version: 0.12.0 -->

## Vector Operations

### `vec`

Create a vector of specified length

**Signature:**

```bmath
|length: Int, fn_or_value: Any| -> Vec
```

**Parameters:**

- `length: Int`: Length of the vector
- `fn_or_value: Any`: Function to apply to each index or value to repeat

**Returns:** `Vec`

---

### `dot`

Dot product of two vectors

**Signature:**

```bmath
|a: Vec, b: Vec| -> Number
```

**Returns:** `Number`

---

### `first`

First element of a vector

**Signature:**

```bmath
|vector: Vec| -> Any
```

**Returns:** `Any`

---

### `last`

Last element of a vector

**Signature:**

```bmath
|vector: Vec| -> Any
```

**Returns:** `Any`

---

### `len`

Length of a vector

**Signature:**

```bmath
|vector: Vec| -> Int
```

**Returns:** `Int`

---

### `merge`

Merge two vectors

**Signature:**

```bmath
|a: Vec, b: Vec| -> Vec
```

**Returns:** `Vec`

---

### `slice`

Extract a slice from a vector

**Signatures:**

```bmath
|vector: Vec, end: Int| -> Vec
```

**Parameters:**

- `end: Int`: End index (when only 2 args)

**Returns:** `Vec`

```bmath
|vector: Vec, start: Int, end: Int| -> Vec
```

**Parameters:**

- `start: Int`: Start index
- `end: Int`: End index

**Returns:** `Vec`

---

### `set`

Set an element in a vector

**Signature:**

```bmath
|vector: Vec, index: Int, value: Any| -> Vec
```

**Returns:** `Vec`

---
