<!-- Auto-generated from stdlib_signatures.json - DO NOT EDIT MANUALLY -->
<!-- Version: 0.12.0 -->

## Assertions

### `assert`

Assert condition is true

**Signature:**

```bmath
|condition: Bool, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Parameters:**

- `condition: Bool`: Condition to check
- `failureMessage: String` (optional): Message to display on failure
- `successMessage: String` (optional): Message to return on success

**Returns:** `Bool | String`

---

### `assert_eq`

Assert two values are equal

**Signature:**

```bmath
|expected: Any, actual: Any, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_neq`

Assert two values are not equal

**Signature:**

```bmath
|first: Any, second: Any, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_lt`

Assert first value is less than second

**Signature:**

```bmath
|a: Any, b: Any, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_gt`

Assert first value is greater than second

**Signature:**

```bmath
|a: Any, b: Any, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_type`

Assert value has expected type

**Signature:**

```bmath
|value: Any, expected_type: Type, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---

### `assert_error`

Assert function throws an error

**Signature:**

```bmath
|fn: Function, failureMessage?: String, successMessage?: String| -> Bool | String
```

**Returns:** `Bool | String`

---
