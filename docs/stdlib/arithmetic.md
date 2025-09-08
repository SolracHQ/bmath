# Arithmetic Functions

This section covers arithmetic operations and basic mathematical functions.

- **Addition (+)**  
  Adds numbers or performs element-wise addition for vectors. When operating on numbers with different types (Int, Real, Complex), promotion rules apply (Int → Real → Complex).  
  **Accepted Types:** Numeric values (or Vec of numeric types).  
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
  **Accepted Types:** Numeric values (or Vec for binary operations).  
  **Example:**

  ```bm
  7 - 2
  ```

  or

  ```bm
  -5
  ```

- **Multiplication (*)**  
  Multiplies numbers or performs scalar multiplication with vectors. Supports automatic promotion among numeric types including Complex.  
  **Accepted Types:** Numeric values and combinations of a Vec and a scalar.  
  **Example:**

  ```bm
  3 * 4
  ```

  or

  ```bm
  2 * [1, 2, 3]
  ```

- **Division (/)**  
  Divides one number by another or divides each element of a Vec by a scalar. Always performs floating-point division for numbers; when operating on Complex values, standard complex division is applied.  
  **Accepted Types:** Two numeric values (Int, Real, or Complex), or a Vec and a scalar.  
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
  Computes the remainder of an Int division. If one or both operands are Real, they are promoted appropriately before the operation. For Vec, computes the modulo of each element with the scalar.  
  **Accepted Types:** Numeric values (primarily Ints, with promotion as needed), or a Vec and a scalar.  
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
  Raises a number to the power of another or raises each element of a Vec to the power of a scalar. For negative exponents on Ints, the result is promoted to a Real. When Complex values are involved, Complex exponentiation is performed.  
  **Accepted Types:** Two numeric values (Int, Real, or Complex), or a Vec and a scalar.  
  **Example:**

  ```bm
  2 ^ 3
  ```

  or

  ```bm
  [2, 3, 4] ^ 2  # Returns [4, 9, 16]
  ```

- **pow**  
  Raises a number to the power of another. Supports Int, Real, and Complex values.  
  **Accepted Types:** Two numeric values (Int, Real, or Complex).  
  **Example:**  

  ```bm
  pow(3.2, 5)
  ```

- **sqrt**  
  Calculates the square root of a number. For non-negative Real numbers, returns the Real square root. For negative Real numbers, returns a Complex number. When provided a Complex value, returns the Complex square root.  
  **Accepted Types:** A single numeric value (Int, Real, or Complex).  
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
  Returns the greatest Int less than or equal to a given Real number.  
  **Accepted Types:** A single numeric value (Int or Real). Not supported for Complex numbers.  
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
  **Accepted Types:** A single numeric value (Int or Real). Not supported for Complex numbers.  
  **Example:**

  ```bm
  round(3.5)  # Returns 4
  ```

- **re**  
  Returns the real part of a Complex value. If the input is not Complex, it returns the input unchanged.  
  **Accepted Types:** A single numeric value (Int, Real, or Complex).  
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
