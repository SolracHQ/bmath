# Documentation for Math CLI Language Standard Library

## Core Functions
- **exit**  
  Terminates the program immediately.  
  **Accepted Types:** No parameters.  
  **Example:** `exit()`

- **pow**  
  Computes the value of a number raised to the power of another.  
  **Accepted Types:** Two numeric values (integers or floats).  
  **Example:**  
  ```bm
  pow(3.2, 5)
  ```

- **sqrt**  
  Calculates the square root of a given number.  
  **Accepted Types:** A single numeric value (integer or float).  
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
  Computes the dot product of two vectors.  
  **Accepted Types:** Two vectors of numbers (both vectors must have the same length).  
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
  Constructs a new vector by specifying a size and a function or value to generate its elements.  
  **Accepted Types:** An integer size and either a function (returning a number) or a constant value.  
  **Example:** `vec(5, x -> x * 2)`

- **createSeq**  
  Constructs a new sequence (lazy evaluated) by specifying a size and a function or constant value to generate its elements.  
  **Accepted Types:** An integer size and either a function (returning a value) or a constant value.  
  **Example:** `createSeq(5, x -> x + 1)`

- **sin**  
  Computes the sine of a given number (angle in radians).  
  **Accepted Types:** A single numeric value (integer or float).  
  **Example:** `sin(1.5708)`

- **cos**  
  Computes the cosine of a given number (angle in radians).  
  **Accepted Types:** A single numeric value (integer or float).  
  **Example:** `cos(0)`

- **tan**  
  Computes the tangent of a given number (angle in radians).  
  **Accepted Types:** A single numeric value (integer or float).  
  **Example:** `tan(0.7854)`

- **log**  
  Computes the logarithm of a number with respect to a given base.  
  **Accepted Types:** Two numeric values (integers or floats).  
  **Example:** `log(100, 10)`

- **exp**  
  Computes the exponential (e^x) of a given number.  
  **Accepted Types:** A single numeric value (integer or float).  
  **Example:** `exp(1)`

## Arithmetic Operators
- **Addition (+)**  
  Performs addition for numbers or element-wise addition for vectors.  
  **Accepted Types:** Numeric values (integers, floats) and vectors (of numeric types).  
  **Example:** `3 + 4` or `4 + [3, 4]`

- **Subtraction (-)**  
  **Binary:** Subtracts one numeric value from another or performs element-wise subtraction for vectors.  
  **Unary:** Negates a numeric value.  
  **Accepted Types:** Numeric values (integers, floats) and vectors for binary operations.  
  **Example:** `7 - 2` or `-5`

- **Multiplication (*)**  
  Multiplies numbers or performs scalar multiplication with vectors.  
  **Accepted Types:** Numeric values (integers, floats) and a combination of a vector and a scalar.  
  **Example:** `3 * 4` or `2 * [1, 2, 3]`

- **Division (/)**  
  Divides one number by another, always returning a float.  
  **Accepted Types:** Two numeric values (integers or floats).  
  **Exception:** Raises an exception if the divisor is 0.  
  **Example:** `10 / 2`

- **Modulo (%)**  
  Computes the remainder of an integer division, with necessary type promotion if required.  
  **Accepted Types:** Numeric values (primarily integers).  
  **Exception:** Raises an exception if the divisor is 0.  
  **Example:** `10 % 3`

- **Exponentiation (^)**  
  Raises a number to the power of another.  
  **Accepted Types:** Two numeric values (integers or floats); if both inputs are integers, the result remains an integer.  
  **Example:** `2 ^ 3`

## Comparison Operators
- **Equality (==)**  
  Compares two values for equality after proper type promotion (e.g., between integers and floats).  
  **Accepted Types:** Numeric values and other comparable types.  
  **Example:** `3 == 3` or `3 == 3.0`

- **Inequality (!=)**  
  Returns the negation of an equality check.  
  **Accepted Types:** Numeric values and other comparable types.  
  **Example:** `3 != 4`

- **Less Than (<)**  
  Checks if the left operand is less than the right operand.  
  **Accepted Types:** Numeric values.  
  **Example:** `3 < 5`

- **Less Than or Equal (<=)**  
  Checks if the left operand is less than or equal to the right operand.  
  **Accepted Types:** Numeric values.  
  **Example:** `3 <= 3`

- **Greater Than (>)**  
  Checks if the left operand is greater than the right operand.  
  **Accepted Types:** Numeric values.  
  **Example:** `5 > 3`

- **Greater Than or Equal (>=)**  
  Checks if the left operand is greater than or equal to the right operand.  
  **Accepted Types:** Numeric values.  
  **Example:** `5 >= 5`

## Logical Operators
- **not (!)**
  Performs logical negation.  
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
Sequences are lazily evaluated collections that extend vector functionality. Many functions that operate on vectors now also support sequences.

- **map**  
  Applies a function to each element of a vector or sequence, returning a new lazy sequence.  
  **Accepted Types:** A vector or sequence and a function that takes a value as input and returns a transformed value.  
  **Example:**  
  ```bm
  map([1, 2, 3], x -> x * 2)
  ```

- **filter**  
  Filters a vector or sequence using a predicate function, returning a new lazy sequence containing only the elements that satisfy the predicate.  
  **Accepted Types:** A vector or sequence and a function that takes a value and returns a boolean.  
  **Example:**  
  ```bm
  filter([1, 2, 3, 4], x -> x mod 2 == 0)
  ```

- **reduce**  
  Reduces a vector by applying a binary function to combine its elements into a single result.  
  **Accepted Types:** A non-empty vector and a binary function that takes two numbers and returns a number.  
  **Example:**  
  ```bm
  reduce([1, 2, 3, 4], 0, (acc, x) -> acc + x)
  ```

- **sum**  
  Computes the total sum of elements in a vector or sequence.  
  **Accepted Types:** A vector or a sequence of numeric values.  
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
- Functions are first-class citizens implemented as inline lambda expressions; parameters are local, and closures capture references to variables rather than static copies.  
- Operators follow promotion rules, ensuring that when operating on numbers of different types (e.g., integers and floats), the integer is promoted to a float. These rules ensure consistent results across arithmetic and comparison operations.  
- Vector operations perform element-wise computations with proper dimension checking.  
- Sequences offer a lazy evaluation model, allowing for efficient processing and transformation without immediate evaluation.  
- **Division (/) and Modulo (%) operations raise an exception if the divisor is 0.**