<!-- Auto-generated from stdlib_signatures.json - DO NOT EDIT MANUALLY -->
<!-- Version: 0.12.0 -->

## Sequence Operations

### `seq`

Create a sequence

**Signatures:**

```bmath
|value_or_fn: Any| -> Seq
```

**Parameters:**

- `value_or_fn: Any`: Value for infinite sequence or function with counter

**Returns:** `Seq`

```bmath
|length: Int, fn: Function| -> Seq
```

**Parameters:**

- `length: Int`: Length of finite sequence
- `fn: Function`: Function to generate values

**Returns:** `Seq`

---

### `skip`

Skip n elements from a sequence

**Signature:**

```bmath
|sequence: Seq, n: Int| -> Seq
```

**Returns:** `Seq`

---

### `take`

Take first n elements from a sequence

**Signature:**

```bmath
|sequence: Seq, n: Int| -> Seq
```

**Returns:** `Seq`

---

### `has_next`

Check if sequence has more elements

**Signature:**

```bmath
|sequence: Seq| -> Bool
```

**Returns:** `Bool`

---

### `next`

Get next element from sequence

**Signature:**

```bmath
|sequence: Seq| -> Any
```

**Returns:** `Any`

---

### `collect`

Collect all elements from a sequence into a vector

**Signature:**

```bmath
|s: Seq| -> Vec
```

**Returns:** `Vec`

---

### `zip`

Zip two sequences together

**Signature:**

```bmath
|seq1: Seq, seq2: Seq| -> Seq
```

**Returns:** `Seq`

---
