# Arithmetic Functions

This section covers arithmetic operations and basic mathematical functions.

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
  Divides one number by another or divides each element of a vector by a scalar. Always performs floating-point division for numbers; when operating on complex numbers, standard complex division is applied.  
  **Accepted Types:** Two numeric values (integer, float, or complex), or a vector and a scalar.  
  **Exception:** Raises an exception if the divisor is 0.  
  **Example:** 
  ```bm
  10 / 2
  ```
  or
  ```bm
  [10, 20, 30] / 2
  ```

- **Modulo (%)**  
  Computes the remainder of an integer division. If one or both operands are floats, they are promoted appropriately before the operation. For vectors, computes the modulo of each element with the scalar.  
  **Accepted Types:** Numeric values (primarily integers, with promotion as needed), or a vector and a scalar.  
  **Exception:** Raises an exception if the divisor is 0.  
  **Example:** 
  ```bm
  10 % 3
  ```
  or
  ```bm
  [10, 11, 12] % 3
  ```

- **Exponentiation (^)**  
  Raises a number to the power of another or raises each element of a vector to the power of a scalar. For negative exponents on integers, the result is promoted to a float. When complex numbers are involved, complex exponentiation is performed.  
  **Accepted Types:** Two numeric values (integer, float, or complex), or a vector and a scalar.  
  **Example:** 
  ```bm
  2 ^ 3
  ```
  or
  ```bm
  [2, 3, 4] ^ 2  # Returns [4, 9, 16]
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

- **re**  
  Returns the real part of a complex number. If the input is not complex, it returns the input unchanged.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  re(3 + 4i)   # Returns 3
  ```
  or
  ```bm
  re(3)        # Returns 3
  ```
- **im**
  Returns the imaginary part of a complex number. If the input is not complex, it returns 0.  
  **Accepted Types:** A single numeric value (integer, float, or complex).  
  **Example:** 
  ```bm
  im(3 + 4i)   # Returns 4
  ```
  or
  ```bm
  im(3)        # Returns 0
  ```