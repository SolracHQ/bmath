# Documentation for Math CLI Language Standard Library

## Core Functions
- **exit**  
  Terminates the program immediately.  
  **Accepted Types:** No parameters.

- **pow**  
  Computes the value of a number raised to the power of another.  
  **Accepted Types:** Two numeric values (integers or floats).

- **sqrt**  
  Calculates the square root of a given number.  
  **Accepted Types:** A single numeric value (integer or float).

- **floor**  
  Returns the greatest integer less than or equal to a given number.  
  **Accepted Types:** A single numeric value (integer or float).

- **ceil**  
  Returns the smallest integer greater than or equal to a given number.  
  **Accepted Types:** A single numeric value (integer or float).

- **round**  
  Rounds a number to the nearest whole number.  
  **Accepted Types:** A single numeric value (integer or float).

- **dot**  
  Computes the dot product of two vectors.  
  **Accepted Types:** Two vectors of numbers (both vectors must have the same length).

- **nth**  
  Retrieves the element at the specified index from a vector.  
  **Accepted Types:** A vector and an integer index value.

- **first**  
  Retrieves the first element of a vector.  
  **Accepted Types:** A single vector.

- **last**  
  Retrieves the last element of a vector.  
  **Accepted Types:** A single vector.

- **vec**  
  Constructs a new vector by specifying a size and a function or value to generate its elements.  
  **Accepted Types:** An integer size and either a function (returning a number) or a constant value.

- **sin**  
  Computes the sine of a given number (angle in radians).  
  **Accepted Types:** A single numeric value (integer or float).

- **cos**  
  Computes the cosine of a given number (angle in radians).  
  **Accepted Types:** A single numeric value (integer or float).

- **tan**  
  Computes the tangent of a given number (angle in radians).  
  **Accepted Types:** A single numeric value (integer or float).

- **log**  
  Computes the logarithm of a number with respect to a given base.  
  **Accepted Types:** Two numeric values (integers or floats).

- **exp**  
  Computes the exponential (e^x) of a given number.  
  **Accepted Types:** A single numeric value (integer or float).

- **map**  
  Applies a function to each element of a vector, returning a new vector with the transformed elements.  
  **Accepted Types:** A vector and a function that takes a number and returns a number.

- **filter**  
  Filters a vector using a predicate function, returning a new vector containing only the elements that satisfy the predicate.  
  **Accepted Types:** A vector and a function that takes a number and returns a boolean.

- **reduce**  
  Reduces a vector by applying a binary function to combine its elements into a single result.  
  **Accepted Types:** A non-empty vector and a binary function that takes two numbers and returns a number.

- **sum**  
  Computes the total sum of elements in a vector of numbers.  
  **Accepted Types:** A single vector of numeric values.

- **any**  
  Returns true if at least one element in a vector of booleans is true.  
  **Accepted Types:** A single vector of boolean values.

- **all**  
  Returns true only if every element in a vector of booleans is true.  
  **Accepted Types:** A single vector of boolean values.

## Arithmetic Operators
- **Addition (+)**  
  Performs addition for numbers or element-wise addition for vectors.  
  **Accepted Types:** Numeric values (integers, floats) and vectors (of numeric types).

- **Subtraction (-)**  
  **Binary:** Subtracts one numeric value from another or performs element-wise subtraction for vectors.  
  **Unary:** Negates a numeric value.  
  **Accepted Types:** Numeric values (integers, floats) and vectors for binary operations.

- **Multiplication (*)**  
  Multiplies numbers or performs scalar multiplication with vectors.  
  **Accepted Types:** Numeric values (integers, floats) and a combination of a vector and a scalar.

- **Division (/)**  
  Divides one number by another, always returning a float.  
  **Accepted Types:** Two numeric values (integers or floats).  
  **Exception:** Raises an exception if the divisor is 0.

- **Modulo (%)**  
  Computes the remainder of an integer division.  
  **Accepted Types:** Numeric values (primarily integers, with promotion to integers as necessary).  
  **Exception:** Raises an exception if the divisor is 0.

- **Exponentiation (^)**  
  Raises a number to the power of another.  
  **Accepted Types:** Two numeric values (integers or floats); if both inputs are integers, the result remains an integer.

## Comparison Operators
- **Equality (==)**  
  Compares two values for equality after proper type promotion (e.g., between integers and floats).  
  **Accepted Types:** Numeric values (and other comparable types where applicable).

- **Inequality (!=)**  
  Returns the negation of an equality check.  
  **Accepted Types:** Numeric values (and other comparable types).

- **Less Than (<)**  
  Checks if the left operand is less than the right operand.  
  **Accepted Types:** Numeric values (integers or floats).

- **Less Than or Equal (<=)**  
  Checks if the left operand is less than or equal to the right operand.  
  **Accepted Types:** Numeric values.

- **Greater Than (>)**  
  Checks if the left operand is greater than the right operand.  
  **Accepted Types:** Numeric values.

- **Greater Than or Equal (>=)**  
  Checks if the left operand is greater than or equal to the right operand.  
  **Accepted Types:** Numeric values.

## Logical Operators
- **not (!)**  
  Performs logical negation.  
  **Accepted Types:** Boolean values.

- **and (&)**  
  Evaluates the logical conjunction of two boolean values.  
  **Accepted Types:** Boolean values.

- **or (|)**  
  Evaluates the logical disjunction of two boolean values.  
  **Accepted Types:** Boolean values.

## General Notes
- All built-in functions are registered in the global environment and are protected from being overwritten.
- Functions are first-class citizens implemented as inline lambda expressions; parameters are local, and closures capture references to variables rather than static copies.
- Operators follow promotion rules, ensuring that when operating on numbers of different types (e.g., integers and floats), the integer is promoted to a float. These rules ensure consistent results across arithmetic and comparison operations.
- Vector operations perform element-wise computations with proper dimension checking.
- **Division (/) and Modulo (%) operations raise an exception if the divisor is 0.**