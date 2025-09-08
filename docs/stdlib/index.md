# Math CLI Language Standard Library Index

This index provides links to all sections of the standard library documentation.

## Table of Contents

- [General Functions](general-functions.md)
- [Arithmetic Functions](arithmetic.md)
- [Comparison and Logical Operators](comparison-logical.md)
- [Mathematical Constants](constants.md)
- [Trigonometric and Mathematical Functions](trigonometric.md)
- [Vector Operations](vector-operations.md)
- [Sequence Operations](sequence-operations.md)
- [Functional Utilities](functional.md)
- [Types](types.md)

## General Notes

- All built-in functions are registered in the global environment and are protected from being overwritten.
- Functions are first-class citizens, implemented as inline lambda expressions. Parameters are local, and closures capture references to variables.
- Operators follow promotion rules: when operating on numbers of different types (e.g., integer, float, complex), the system promotes the operand to the higher type (int → float → complex) to ensure consistent results.
- Vector operations perform element-wise computations with proper dimensionality checks.
- Sequences provide lazy evaluation, enabling efficient processing and transformation without immediate materialization.
- Division (/) and Modulo (%) operations raise an exception if the divisor is zero.
- Comparison operators do not support complex numbers; attempting such comparisons raises an exception.
- The square root of negative real numbers returns a complex number rather than raising an error.
- Several functions have distinct behaviors depending on whether they operate on a concrete vector or a lazy sequence (e.g., `map`, `filter`, `collect`).
