# Vector Operations

This section covers operations specific to vectors.

- **vec**  
  Constructs a new Vec with specified elements.  
  **Accepted Types:**
  - An Int size and a function that transforms the index into a value
  - An Int size and a constant value to repeat
  
  **Examples:**

  ```bm
  # Using a function that doubles the index
  vec(5, |x| x * 2) # output: [0, 2, 4, 6, 8]
  
  # Using a constant value to create a vector of repeated values
  vec(3, 42) # output: [42, 42, 42]
  ```

- **dot**  
  Computes the dot product of two Vec of numbers.  
  **Accepted Types:** Two Vec of numeric values (each Vec can contain Int, Real, or Complex, but they must be of the same length).  
  **Example:**

  ```bm
  dot([1, 2, 3], [4, 5, 6])
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

- **set**  
  Sets the value at a specific index in a vector and returns the previous value.  
  **Accepted Types:** A vector, an integer index, and a value to set.  
  **Example:**

  ```bm
  set([10, 20, 30], 1, 99)  # modifies the vector to [10, 99, 30] and returns 20
  ```
