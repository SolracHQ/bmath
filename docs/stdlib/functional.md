# Functional Programming Utilities

This section covers functions for transforming and processing collections using functional programming patterns.

- **map**  
  Applies a function to each element of a vector or sequence, returning a new lazy sequence.  
  **Accepted Types:** A vector or sequence and a function that takes a value as input and returns a transformed value.  
  **Example:**  
  ```bm
  [1, 2, 3] -> map(|x| x * 2)
  ```
  Alternative syntax:
  ```bm
  map([1, 2, 3], |x| x * 2)
  ```

- **filter**  
  Filters a vector or sequence using a predicate function, returning a new lazy sequence containing only the elements that satisfy the predicate.  
  **Accepted Types:** A vector or sequence and a function that takes a value and returns a boolean.  
  **Example:**  
  ```bm
  [1, 2, 3, 4] -> filter(|x| x % 2 == 0)
  ```
  Alternative syntax:
  ```bm
  filter([1, 2, 3, 4], |x| x % 2 == 0)
  ```

- **reduce**  
  Reduces a vector by applying a binary function to combine its elements into a single result, starting from an initial accumulator value.  
  **Accepted Types:** A non-empty vector or sequence and a binary function that takes two values and returns a value.  
  **Example:**  
  ```bm
  [1, 2, 3, 4] -> reduce(0, |acc, x| acc + x)
  ```
  Alternative syntax:
  ```bm
  reduce([1, 2, 3, 4], 0, |acc, x| acc + x)
  ```

- **sum**  
  Computes the total sum of all elements in a vector or sequence.  
  **Accepted Types:** A vector or sequence of numeric values.  
  **Example:**  
  ```bm
  [1, 2, 3, 4] -> sum()
  ```

- **any**  
  Returns true if at least one element in a vector or sequence of boolean values is true.  
  **Accepted Types:** A vector or sequence of boolean values.  
  **Example:**  
  ```bm
  [false, false, true] -> any()
  ```

- **all**  
  Returns true only if every element in a vector or sequence of boolean values is true.  
  **Accepted Types:** A vector or sequence of boolean values.  
  **Example:**  
  ```bm
  [true, true, true] -> all()
  ```

- **nth**  
  Retrieves the element at the specified index from a vector or sequence. Also available as **at**.  
  **Accepted Types:** A vector or sequence and an integer index value.  
  **Example:** 
  ```bm
  [10, 20, 30] -> nth(1)  // Returns 20 from vector
  ```
  ```bm
  [10, 20, 30] -> at(1)   // Same function, different name
  ```
  ```bm
  seq(100, |i| i) -> nth(5)   // Returns the 6th value from sequence
  ```

  Note: When used with sequences, this will consume elements up to the requested index.