# Comparison and Logical Operators

This section covers comparison operators and logical operations.

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

## Comparison Functions

- **min**  
  Returns the minimum value based on several input forms.  
  **Accepted Forms:**  
  1. Single vector of values:
     ```bm
     min([1, 5, 2, 4, 3])  # Returns 1
     ```
  2. Single sequence of values:
     ```bm
     min(seq(5, |x| x + 1))  # Returns 1 - for a sequence from 1 to 5
     ```
  3. Multiple values:
     ```bm
     min(4, 2, 7, 1, 9)  # Returns 1
     ```
  4. Vector with custom comparison function:
     ```bm
     # Custom function to compare absolute values
     min([-5, 3, -2, 1, 4], |a, b| abs(a) < abs(b))  # Returns 1 (smallest absolute value)
     ```
  5. Sequence with custom comparison function:
     ```bm
     # Custom function to compare by second element of pairs
     min(seq(5, |x| [x, x*x]), |a, b| a->nth(1) < b->nth(1))  # Returns [0, 0] (smallest second element)
     ```
  6. Multiple values with custom comparison function:
     ```bm
     # Compare by distance from origin in coordinate system
     min([3, 4], [1, 1], [5, 12], |a, b| (a->nth(0)^2 + a->nth(1)^2) < (b->nth(0)^2 + b->nth(1)^2))  # Returns [1, 1]
     ```

- **max**  
  Returns the maximum value based on several input forms.  
  **Accepted Forms:**  
  1. Single vector of values:
     ```bm
     max([1, 5, 2, 4, 3])  # Returns 5
     ```
  2. Single sequence of values:
     ```bm
     max(seq(5, |x| x + 1))  # Returns 5 - for a sequence from 1 to 5
     ```
  3. Multiple values:
     ```bm
     max(4, 2, 7, 1, 9)  # Returns 9
     ```
  4. Vector with custom comparison function:
     ```bm
     # Custom function to compare absolute values
     max([-5, 3, -2, 1, 4], |a, b| abs(a) > abs(b))  # Returns -5 (largest absolute value)
     ```
  5. Sequence with custom comparison function:
     ```bm
     # Custom function to compare by second element of pairs
     max(seq(5, |x| [x, x*x]), |a, b| a->nth(1) > b->nth(1))  # Returns [4, 16] (largest second element)
     ```
  6. Multiple values with custom comparison function:
     ```bm
     # Compare by distance from origin in coordinate system
     max([3, 4], [1, 1], [5, 12], |a, b| (a->nth(0)^2 + a->nth(1)^2) > (b->nth(0)^2 + b->nth(1)^2))  # Returns [5, 12]
     ```
