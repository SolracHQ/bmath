# Documentation for Math CLI Language Standard Library

## General Functions
- **exit**  
  Terminates the program immediately.  
  **Accepted Types:** No parameters.  
  **Example:** 
  ```bm
  exit()
  ```

## Arithmetic Functions
- **Addition (+)**  
  Adds numbers or performs element-wise addition for vectors. When operating on numbers with different types (integer, float, complex), promotion rules apply (int → float → complex).  
  **Accepted Types:** Numeric values (or vectors of numeric types).  
  **Example:** 
  ```bm
  3 + 4
  ```
  or
  ```bm
  [1, 2, 3] + [4, 5, 6]
  ```

- **Subtraction (-)**  
  **Binary:** Subtracts one numeric value from another or performs element-wise subtraction for vectors.  
  **Unary:** Negates a numeric value.  
  **Accepted Types:** Numeric values (or vectors for binary operations).  
  **Example:** 
  ```bm
  7 - 2
  ```
  or
  ```bm
  -5
  ```

- **Multiplication (*)**  
  Multiplies numbers or performs scalar multiplication with vectors. Supports automatic promotion among numeric types including complex numbers.  
  **Accepted Types:** Numeric values and combinations of a vector and a scalar.  
  **Example:** 
  ```bm
  3 * 4
  ```
  or
  ```bm
  2 * [1, 2, 3]
  ```

- **Division (/)**  
  Divides one number by another. Always performs floating-point division for numbers; when operating on complex numbers, standard complex division is applied.  
  **Accepted Types:** Two numeric values (integer, float, or complex).  
  **Exception:** Raises an exception if the divisor is 0.  
  **Example:** 
  ```bm
  10 / 2
  ```

- **Modulo (%)**  
  Computes the remainder of an integer division. If one or both operands are floats, they are promoted appropriately before the operation.  
  **Accepted Types:** Numeric values (primarily integers, with promotion as needed).  
  **Exception:** Raises an exception if the divisor is 0.  
  **Example:** 
  ```bm
  10 % 3
  ```

- **Exponentiation (^)**  
  Raises a number to the power of another. For negative exponents on integers, the result is promoted to a float. When complex numbers are involved, complex exponentiation is performed.  
  **Accepted Types:** Two numeric values (integer, float, or complex).  
  **Example:** 
  ```bm
  2 ^ 3
  ```

- **pow**  
  Raises a number to the power of another. Supports integers, floats, and complex numbers.  
  **Accepted Types:** Two numeric values (integer, float, or complex).  
  **Example:**  
  ```bm
  pow(3.2, 5)
  ```

- **sqrt**  
  Calculates the square root of a number. For non-negative real numbers, returns the real square root. For negative real numbers, returns a complex number. When provided a complex number, returns the complex square root.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  sqrt(16)    # Returns 4
  sqrt(-4)    # Returns 2i
  ```

- **abs**  
  Returns the absolute value of a number.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  abs(-4.2)
  ```

- **floor**  
  Returns the greatest integer less than or equal to a given number.  
  **Accepted Types:** A single numeric value (integer or float). Not supported for complex numbers.  
  **Example:** 
  ```bm
  floor(3.7)  # Returns 3
  ```

- **ceil**  
  Returns the smallest integer greater than or equal to a given number.  
  **Accepted Types:** A single numeric value (integer or float). Not supported for complex numbers.  
  **Example:** 
  ```bm
  ceil(3.2)   # Returns 4
  ```

- **round**  
  Rounds a number to the nearest whole number.  
  **Accepted Types:** A single numeric value (integer or float). Not supported for complex numbers.  
  **Example:** 
  ```bm
  round(3.5)  # Returns 4
  ```

## Comparison Operators
- **Equality (==)**  
  Compares two values for equality with type promotion (e.g., between integers and floats) and supports numeric types.  
  **Accepted Types:** Numeric values and other comparable types.  
  **Example:** 
  ```bm
  3 == 3
  ```
  or
  ```bm
  3 == 3.0
  ```

- **Inequality (!=)**  
  Returns the negation of an equality check.  
  **Accepted Types:** Numeric values and other comparable types.  
  **Example:** 
  ```bm
  3 != 4
  ```

- **Less Than (<)**  
  Checks if the left operand is less than the right operand. Note: comparisons involving complex numbers raise an exception.  
  **Accepted Types:** Numeric values (excluding complex).  
  **Example:** 
  ```bm
  3 < 5
  ```

- **Less Than or Equal (<=)**  
  Checks if the left operand is less than or equal to the right operand.  
  **Accepted Types:** Numeric values (excluding complex).  
  **Example:** 
  ```bm
  3 <= 3
  ```

- **Greater Than (>)**  
  Checks if the left operand is greater than the right operand.  
  **Accepted Types:** Numeric values (excluding complex).  
  **Example:** 
  ```bm
  5 > 3
  ```

- **Greater Than or Equal (>=)**  
  Checks if the left operand is greater than or equal to the right operand.  
  **Accepted Types:** Numeric values (excluding complex).  
  **Example:** 
  ```bm
  5 >= 5
  ```

## Logical Operators
- **not (!)**  
  Performs logical negation on boolean values.  
  **Accepted Types:** Boolean values.  
  **Example:** 
  ```bm
  !true
  ```

- **and (&)**  
  Evaluates the logical conjunction of two boolean values.  
  **Accepted Types:** Boolean values.  
  **Example:** 
  ```bm
  true & false
  ```

- **or (|)**  
  Evaluates the logical disjunction of two boolean values.  
  **Accepted Types:** Boolean values.  
  **Example:** 
  ```bm
  true | false
  ```

## Trigonometric Functions
- **sin**  
  Computes the sine of a given number (angle in radians). Supports complex numbers as well.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  sin(pi/2) # output: 1
  ```

- **cos**  
  Computes the cosine of a given number (angle in radians). Supports complex numbers.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  cos(0) # output: 1
  ```

- **tan**  
  Computes the tangent of a given number (angle in radians). Supports complex numbers.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  tan(pi/4) # output: 1
  ```

- **cot**  
  Computes the cotangent of a given number (angle in radians). Supports complex numbers.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  cot(pi/4) # output: 1
  ```

- **sec**  
  Computes the secant of a given number (angle in radians). Supports complex numbers.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  sec(0) # output: 1
  ```

- **csc**  
  Computes the cosecant of a given number (angle in radians). Supports complex numbers.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  csc(pi/2) # output: 1
  ```

- **log**  
  Computes the logarithm of a number with respect to a given base. Supports complex numbers if either argument is complex.  
  **Accepted Types:** Two numeric values (integer, float, or complex).  
  **Example:** 
  ```bm
  log(e, e) # output: 1
  
  log(100, 10) # output: 2
  ```

- **exp**  
  Computes the exponential (e^x) of a given number. Supports complex numbers.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  exp(1) # output: 2.718281828459045
  ```

## Vector Operations
- **vec**  
  Constructs a new vector with specified elements.  
  **Accepted Types:** 
  - An integer size and a function that transforms the index into a value
  - An integer size and a constant value to repeat
  
  **Examples:** 
  ```bm
  # Using a function that doubles the index
  vec(5, |x| x * 2) # output: [0, 2, 4, 6, 8]
  
  # Using a constant value to create a vector of repeated values
  vec(3, 42) # output: [42, 42, 42]
  ```

- **dot**  
  Computes the dot product of two vectors of numbers.  
  **Accepted Types:** Two vectors of numeric values (each vector can contain integers, floats, or complex numbers, but they must be of the same length).  
  **Example:** 
  ```bm
  dot([1, 2, 3], [4, 5, 6])
  ```

- **nth**  
  Retrieves the element at the specified index from a vector.  
  **Accepted Types:** A vector and an integer index value.  
  **Example:** 
  ```bm
  nth([10, 20, 30], 1)
  ```

- **first**  
  Retrieves the first element of a vector.  
  **Accepted Types:** A single vector.  
  **Example:** 
  ```bm
  first([10, 20, 30])
  ```

- **last**  
  Retrieves the last element of a vector.  
  **Accepted Types:** A single vector.  
  **Example:** 
  ```bm
  last([10, 20, 30])
  ```

- **len**  
  Returns the length of a vector.  
  **Accepted Types:** A single vector.  
  **Example:** 
  ```bm
  len([10, 20, 30])
  ```

- **merge**  
  Concatenates two vectors into a single new vector.  
  **Accepted Types:** Two vectors.  
  **Example:** 
  ```bm
  merge([1, 2], [3, 4])  # output: [1, 2, 3, 4]
  ```

- **slice**  
  Creates a new vector containing a subset of elements from an existing vector.  
  **Accepted Types:** 
  - A vector and an end index (for 0 to end-1 slice)
  - A vector with start and end indices (for start to end-1 slice)
  
  **Example:** 
  ```bm
  slice([10, 20, 30, 40, 50], 3)  # output: [10, 20, 30]
  slice([10, 20, 30, 40, 50], 1, 4)  # output: [20, 30, 40]
  ```

## Sequence Operations
- **sequence**  
  Constructs a lazy-evaluated sequence of values.  
  **Accepted Types:**
  - A single value to create an infinite sequence of that value
  - A single function to create an infinite sequence calling that function with indices 0, 1, 2...
  - An integer size and a function to create a finite sequence
  - A vector to create a sequence from the vector's elements
  
  **Examples:** 
  ```bm
  # Create a finite sequence of 5 elements using a function
  sequence(5, |x| x * x) # output: lazy sequence of [0, 1, 4, 9, 16]
  
  # Create an infinite sequence using a function
  sequence(|x| x + 1) # output: lazy infinite sequence starting with [1, 2, 3, ...]
  
  # Create an infinite sequence of a constant value
  sequence(42) # output: lazy infinite sequence of [42, 42, 42, ...]
  
  # Create a sequence from a vector
  sequence([10, 20, 30]) # output: lazy sequence of [10, 20, 30]
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

- **collect**  
  Forces evaluation of a lazy sequence and collects its elements into a concrete vector.  
  **Accepted Types:** A sequence.  
  **Example:**  
  ```bm
  collect(someLazySeq)
  ```

- **take**  
  Creates a new sequence containing only the first n elements of the input sequence.  
  **Accepted Types:** A sequence and a non-negative integer specifying how many elements to take.  
  **Example:**  
  ```bm
  take(sequence(|x| x * x), 5)  # lazy sequence of [0, 1, 4, 9, 16]
  ```

- **zip**  
  Creates a sequence by pairing elements from two sequences.  
  **Accepted Types:** Two sequences.  
  **Example:**  
  ```bm
  zip(sequence([1, 2, 3]), sequence([10, 20, 30]))  # lazy sequence of [[1, 10], [2, 20], [3, 30]]
  ```

## Iteration Utilities
- **map**  
  Applies a function to each element of a vector or sequence, returning a new lazy sequence.  
  **Accepted Types:** A vector or sequence and a function that takes a value as input and returns a transformed value.  
  **Example:**  
  ```bm
  map([1, 2, 3], |x| x * 2)
  ```
  or using ->
  ```bm
  [1, 2, 3] -> map(|x| x * 2)
  ```

- **filter**  
  Filters a vector or sequence using a predicate function, returning a new lazy sequence containing only the elements that satisfy the predicate.  
  **Accepted Types:** A vector or sequence and a function that takes a value and returns a boolean.  
  **Example:**  
  ```bm
  filter([1, 2, 3, 4], |x| x % 2 == 0)
  ```
  or using ->
  ```bm
  [1, 2, 3, 4] -> filter(|x| x % 2 == 0)
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

## General Notes
- All built-in functions are registered in the global environment and are protected from being overwritten.
- Functions are first-class citizens, implemented as inline lambda expressions. Parameters are local, and closures capture references to variables.
- Operators follow promotion rules: when operating on numbers of different types (e.g., integer, float, complex), the system promotes the operand to the higher type (int → float → complex) to ensure consistent results.
- Vector operations perform element-wise computations with proper dimensionality checks.
- Sequences provide lazy evaluation, enabling efficient processing and transformation without immediate materialization.
- **Division (/) and Modulo (%) operations raise an exception if the divisor is zero.**
- Comparison operators do not support complex numbers; attempting such comparisons raises an exception.
- **The square root of negative real numbers returns a complex number rather than raising an error.**
- Several functions have distinct behaviors depending on whether they operate on a concrete vector or a lazy sequence (e.g., `map`, `filter`, `collect`).
