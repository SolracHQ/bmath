# Documentation for Math CLI Language Standard Library

## Core Functions
- **exit**  
  Terminates the program immediately.  
  **Accepted Types:** No parameters.  
  **Example:** `exit()`

- **pow**  
  Raises a number to the power of another. Supports integers, floats, and complex numbers.  
  **Accepted Types:** Two numeric values (integer, float, or complex).  
  **Example:**  
  ```bm
  pow(3.2, 5)
  ```

- **sqrt**  
  Calculates the square root of a non-negative number. When provided a complex number with a non-zero imaginary part, returns the complex square root.  
  **Accepted Types:** A single numeric value (integer, float, or complex). Note that for real inputs, negative values will raise an exception.  
  **Example:** `sqrt(16)`

- **floor**  
  Returns the greatest integer less than or equal to a given number.  
  **Accepted Types:** A single numeric value (integer or float).  
  **Example:** `floor(3.7)`

- **ceil**  
  Returns the smallest integer greater than or equal to a given number.  
  **Accepted Types:** A single numeric value (integer or float).  
  **Example:** `ceil(3.2)`

- **round**  
  Rounds a number to the nearest whole number.  
  **Accepted Types:** A single numeric value (integer or float).  
  **Example:** `round(3.5)`

- **dot**  
  Computes the dot product of two vectors of numbers.  
  **Accepted Types:** Two vectors of numeric values (each vector can contain integers, floats, or complex numbers, but they must be of the same length).  
  **Example:** `dot([1, 2, 3], [4, 5, 6])`

- **nth**  
  Retrieves the element at the specified index from a vector.  
  **Accepted Types:** A vector and an integer index value.  
  **Example:** `nth([10, 20, 30], 1)`

- **first**  
  Retrieves the first element of a vector.  
  **Accepted Types:** A single vector.  
  **Example:** `first([10, 20, 30])`

- **last**  
  Retrieves the last element of a vector.  
  **Accepted Types:** A single vector.  
  **Example:** `last([10, 20, 30])`

- **vec**  
  Constructs a new vector by specifying its size and a function or constant value used to generate its elements. Internally implemented as `createVector`.  
  **Accepted Types:** An integer size and either a function (returning a number) or a constant value (which can be numeric or otherwise).  
  **Example:** `vec(5, |x| x * 2)`

- **createSeq**  
  Constructs a new lazy-evaluated sequence by specifying a size and a function or constant value to generate its elements.  
  **Accepted Types:** An integer size and either a function (returning a value) or a constant value.  
  **Example:** `createSeq(5, |x| x + 1)`

- **sin**  
  Computes the sine of a given number (angle in radians). Supports complex numbers as well.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** `sin(1.5708)`

- **cos**  
  Computes the cosine of a given number (angle in radians). Supports complex numbers.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** `cos(0)`

- **tan**  
  Computes the tangent of a given number (angle in radians). Supports complex numbers.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** `tan(0.7854)`

- **log**  
  Computes the logarithm of a number with respect to a given base. Supports complex numbers if either argument is complex.  
  **Accepted Types:** Two numeric values (integer, float, or complex).  
  **Example:** `log(100, 10)`

- **exp**  
  Computes the exponential (e^x) of a given number. Supports complex numbers.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** `exp(1)`

## Arithmetic Operators
- **Addition (+)**  
  Adds numbers or performs element-wise addition for vectors. When operating on numbers with different types (integer, float, complex), promotion rules apply (int → float → complex).  
  **Accepted Types:** Numeric values (or vectors of numeric types).  
  **Example:** `3 + 4` or `4 + [3, 4]`

- **Subtraction (-)**  
  **Binary:** Subtracts one numeric value from another or performs element-wise subtraction for vectors.  
  **Unary:** Negates a numeric value.  
  **Accepted Types:** Numeric values (or vectors for binary operations).  
  **Example:** `7 - 2` or `-5`

- **Multiplication (*)**  
  Multiplies numbers or performs scalar multiplication with vectors. Supports automatic promotion among numeric types including complex numbers.  
  **Accepted Types:** Numeric values and combinations of a vector and a scalar.  
  **Example:** `3 * 4` or `2 * [1, 2, 3]`

- **Division (/)**  
  Divides one number by another. Always performs floating-point division for numbers; when operating on complex numbers, standard complex division is applied.  
  **Accepted Types:** Two numeric values (integer, float, or complex).  
  **Exception:** Raises an exception if the divisor is 0.  
  **Example:** `10 / 2`

- **Modulo (%)**  
  Computes the remainder of an integer division. If one or both operands are floats, they are promoted appropriately before the operation.  
  **Accepted Types:** Numeric values (primarily integers, with promotion as needed).  
  **Exception:** Raises an exception if the divisor is 0.  
  **Example:** `10 % 3`

- **Exponentiation (^)**  
  Raises a number to the power of another. For negative exponents on integers, the result is promoted to a float. When complex numbers are involved, complex exponentiation is performed.  
  **Accepted Types:** Two numeric values (integer, float, or complex).  
  **Example:** `2 ^ 3`

## Comparison Operators
- **Equality (==)**  
  Compares two values for equality with type promotion (e.g., between integers and floats) and supports numeric types.  
  **Accepted Types:** Numeric values and other comparable types.  
  **Example:** `3 == 3` or `3 == 3.0`

- **Inequality (!=)**  
  Returns the negation of an equality check.  
  **Accepted Types:** Numeric values and other comparable types.  
  **Example:** `3 != 4`

- **Less Than (<)**  
  Checks if the left operand is less than the right operand. Note: comparisons involving complex numbers raise an exception.  
  **Accepted Types:** Numeric values (excluding complex).  
  **Example:** `3 < 5`

- **Less Than or Equal (<=)**  
  Checks if the left operand is less than or equal to the right operand.  
  **Accepted Types:** Numeric values (excluding complex).  
  **Example:** `3 <= 3`

- **Greater Than (>)**  
  Checks if the left operand is greater than the right operand.  
  **Accepted Types:** Numeric values (excluding complex).  
  **Example:** `5 > 3`

- **Greater Than or Equal (>=)**  
  Checks if the left operand is greater than or equal to the right operand.  
  **Accepted Types:** Numeric values (excluding complex).  
  **Example:** `5 >= 5`

## Logical Operators
- **not (!)**  
  Performs logical negation on boolean values.  
  **Accepted Types:** Boolean values.  
  **Example:** `!true`

- **and (&)**  
  Evaluates the logical conjunction of two boolean values.  
  **Accepted Types:** Boolean values.  
  **Example:** `true & false`

- **or (|)**  
  Evaluates the logical disjunction of two boolean values.  
  **Accepted Types:** Boolean values.  
  **Example:** `true | false`

## Sequence and Vector Operations
Sequences offer lazy evaluation while vectors are concrete collections. Many vector operations are extended to sequences.

- **map**  
  Applies a function to each element of a vector or sequence, returning a new lazy sequence.  
  **Accepted Types:** A vector or sequence and a function that takes a value as input and returns a transformed value.  
  **Example:**  
  ```bm
  map([1, 2, 3], |x| x * 2)
  # or using ->
  [1, 2, 3] -> map(|x| x * 2)
  ```

- **filter**  
  Filters a vector or sequence using a predicate function, returning a new lazy sequence containing only the elements that satisfy the predicate.  
  **Accepted Types:** A vector or sequence and a function that takes a value and returns a boolean.  
  **Example:**  
  ```bm
  filter([1, 2, 3, 4], |x| x mod 2 == 0)
  # or using ->
  [1, 2, 3, 4] -> filter(|x| x mod 2 == 0)
  ```

- **reduce**  
  Reduces a vector by applying a binary function to combine its elements into a single result, starting from an initial accumulator value.  
  **Accepted Types:** A non-empty vector or sequence and a binary function that takes two values and returns a value.  
  **Example:**  
  ```bm
  reduce([1, 2, 3, 4], 0, |acc, x| acc + x)
  ```

- **sum**  
  Computes the total sum of all elements in a vector or sequence.  
  **Accepted Types:** A vector or sequence of numeric values.  
  **Example:**  
  ```bm
  sum([1, 2, 3, 4])
  ```

- **any**  
  Returns true if at least one element in a vector or sequence of boolean values is true.  
  **Accepted Types:** A vector or sequence of boolean values.  
  **Example:**  
  ```bm
  any([false, false, true])
  ```

- **all**  
  Returns true only if every element in a vector or sequence of boolean values is true.  
  **Accepted Types:** A vector or sequence of boolean values.  
  **Example:**  
  ```bm
  all([true, true, true])
  ```

- **collect**  
  Forces evaluation of a lazy sequence and collects its elements into a concrete vector.  
  **Accepted Types:** A sequence.  
  **Example:**  
  ```bm
  collect(someLazySeq)
  ```

- **skip**  
  Skips the first n elements of a sequence and returns the subsequent element.  
  **Accepted Types:** A sequence and an integer specifying how many elements to skip.  
  **Example:**  
  ```bm
  skip(someSeq, 2)
  ```

- **hasNext**  
  Checks if a sequence has a next element available.  
  **Accepted Types:** A sequence.  
  **Example:**  
  ```bm
  hasNext(someSeq)
  ```

- **next**  
  Retrieves the next element of a sequence.  
  **Accepted Types:** A sequence.  
  **Example:**  
  ```bm
  next(someSeq)
  ```

## General Notes
- All built-in functions are registered in the global environment and are protected from being overwritten.
- Functions are first-class citizens, implemented as inline lambda expressions. Parameters are local, and closures capture references to variables.
- Operators follow promotion rules: when operating on numbers of different types (e.g., integer, float, complex), the system promotes the operand to the higher type (int → float → complex) to ensure consistent results.
- Vector operations perform element-wise computations with proper dimensionality checks.
- Sequences provide lazy evaluation, enabling efficient processing and transformation without immediate materialization.
- **Division (/) and Modulo (%) operations raise an exception if the divisor is zero.**
- Comparison operators do not support complex numbers; attempting such comparisons raises an exception.
- Several functions have distinct behaviors depending on whether they operate on a concrete vector or a lazy sequence (e.g., `map`, `filter`, `collect`).
