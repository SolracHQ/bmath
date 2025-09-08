# Sequence Operations

This section covers operations related to sequences and lazy evaluation.

- **sequence**  
  Constructs a lazy-evaluated Seq of values.  
  **Accepted Types:**
  - A single value to create an infinite Seq of that value
  - A single function to create an infinite Seq calling that function with indices 0, 1, 2...
  - An Int size and a function to create a finite Seq
  - A Vec to create a Seq from the Vec's elements
  
  **Examples:**

  ```bm
  # Create a finite sequence of 5 elements using a function
  seq(5, |x| x * x) # output: lazy sequence of [0, 1, 4, 9, 16]
  
  # Create an infinite sequence using a function
  seq(|x| x + 1) # output: lazy infinite sequence starting with [1, 2, 3, ...]
  
  # Create an infinite sequence of a constant value
  seq(42) # output: lazy infinite sequence of [42, 42, 42, ...]
  
  # Create a sequence from a vector
  seq([10, 20, 30]) # output: lazy sequence of [10, 20, 30]
  ```

- **skip**  
  Skips the first n elements of a Seq and returns the subsequent element.  
  **Accepted Types:** A Seq and an Int specifying how many elements to skip.  
  **Example:**  

  ```bm
  skip(someSeq, 2)
  ```

- **hasNext**  
  Checks if a Seq has a next element available.  
  **Accepted Types:** A Seq.  
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
  Forces evaluation of a lazy Seq and collects its elements into a concrete Vec.  
  **Accepted Types:** A Seq.  
  **Example:**  

  ```bm
  collect(someLazySeq)
  ```

- **take**  
  Creates a new Seq containing only the first n elements of the input Seq.  
  **Accepted Types:** A Seq and a non-negative Int specifying how many elements to take.  
  **Example:**  

  ```bm
  take(seq(|x| x * x), 5)  # lazy sequence of [0, 1, 4, 9, 16]
  ```

- **zip**  
  Creates a sequence by pairing elements from two sequences.  
  **Accepted Types:** Two sequences.  
  **Example:**  

  ```bm
  zip(seq([1, 2, 3]), seq([10, 20, 30]))  # lazy sequence of [[1, 10], [2, 20], [3, 30]]
  ```
