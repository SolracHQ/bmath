<!-- Auto-generated from stdlib_signatures.json - DO NOT EDIT MANUALLY -->
<!-- Version: 0.12.0 -->

## Functional

### `map`

Apply a function to each element of a collection

**Signatures:**

```bmath
|collection: Vec, fn: Function| -> Vec
```

**Parameters:**

- `collection: Vec`: Vector to map over
- `fn: Function`: Function to apply to each element

**Returns:** `Vec`

```bmath
|collection: Seq, fn: Function| -> Seq
```

**Parameters:**

- `collection: Seq`: Sequence to map over
- `fn: Function`: Function to apply to each element

**Returns:** `Seq`

---

### `filter`

Filter elements by predicate function

**Signatures:**

```bmath
|collection: Vec, fn: Function| -> Seq
```

**Parameters:**

- `collection: Vec`: Vector to filter
- `fn: Function`: Predicate function

**Returns:** `Seq`

```bmath
|collection: Seq, fn: Function| -> Seq
```

**Parameters:**

- `collection: Seq`: Sequence to filter
- `fn: Function`: Predicate function

**Returns:** `Seq`

---

### `reduce`

Reduce collection with accumulator function

**Signatures:**

```bmath
|collection: Vec, initial: Any, fn: Function| -> Any
```

**Parameters:**

- `collection: Vec`: Vector to reduce
- `initial: Any`: Initial accumulator value
- `fn: Function`: Binary accumulator function

**Returns:** `Any`

```bmath
|collection: Seq, initial: Any, fn: Function| -> Any
```

**Parameters:**

- `collection: Seq`: Sequence to reduce
- `initial: Any`: Initial accumulator value
- `fn: Function`: Binary accumulator function

**Returns:** `Any`

---

### `sum`

Sum all numeric elements in a collection

**Signature:**

```bmath
|a: Vec | Seq| -> Number
```

**Returns:** `Number`

---

### `any`

Check if any element is truthy

**Signature:**

```bmath
|a: Vec | Seq| -> Bool
```

**Returns:** `Bool`

---

### `all`

Check if all elements are truthy

**Signature:**

```bmath
|a: Vec | Seq| -> Bool
```

**Returns:** `Bool`

---

### `nth`

Get nth element from a vector or sequence

**Signature:**

```bmath
|value: Vec | Seq, index: Int| -> Any
```

**Returns:** `Any`

---

### `at`

Alias for nth - get element at index

**Signature:**

```bmath
|sequence: Vec | Seq, index: Int| -> Any
```

**Returns:** `Any`

---
