# Iteration Utilities

This section covers functions for iterating, transforming, and processing collections.

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
