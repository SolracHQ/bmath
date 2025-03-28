# Mathematical Constants

This section covers built-in mathematical constants available in the language.

- **pi**  
  The mathematical constant π (pi), representing the ratio of a circle's circumference to its diameter.  
  **Value:** Approximately 3.14159265358979323846  
  **Example:** 
  ```bm
  circumference = 2 * pi * radius
  sin(pi/2)  # Returns 1
  ```

- **e**  
  The mathematical constant e (Euler's number), which is the base of natural logarithms.  
  **Value:** Approximately 2.71828182845904523536  
  **Example:** 
  ```bm
  compound_interest = principal * e^(rate * time)
  log(e, e)  # Returns 1
  ```

- **i**  
  The imaginary unit, defined as the square root of -1.  
  **Value:** Complex number with real part 0 and imaginary part 1  
  **Example:** 
  ```bm
  z = 3 + i  # A complex number
  i^2  # Returns -1
  ```

## Using Constants in Expressions

Constants can be used in any expression just like regular variables:

```bm
# Area of a circle
area = pi * r^2

# Complex number operations
z1 = 3 + 4i
z2 = 2 - 3i
result = z1 * z2  # Complex multiplication

# Using e in natural growth/decay formulas
population = initial * e^(growth_rate * time)
```
