# General Functions

This section covers basic utility functions in the Math CLI Language.

- **exit**  
  Terminates the program immediately with an optional exit code.  
  **Accepted Types:** No parameters, or a single Int exit code.  
  **Example:**

  ```bm
  exit()      # Exit with default code 0
  exit(1)     # Exit with code 1
  ```

- **try_or**  
  Executes a lambda function and returns a default value if an error occurs.  
  **Accepted Types:** A lambda function and a default value.  
  **Example:**

  ```bm
  result = try_or(|| risky_operation(), default_value)
  ```

- **try_catch**  
  Executes a lambda function and catches any errors, passing the error type to another lambda.  
  **Accepted Types:** A lambda function and a lambda that receives the error type.  
  **Example:**

  ```bm
  result = try_catch(|| risky_operation(), |error_type| handle_error(error_type))
  ```

- **print**  
  Prints a value to the console inside a block and returns the value.
  **Accepted Types:** Any value (including Int, Real, Complex, Bool, Vec, Seq, Function, Type).
  **Example:**

  ```bm
  a = {
      print(42) # Print 42
  } # prints a = 42
  ```
