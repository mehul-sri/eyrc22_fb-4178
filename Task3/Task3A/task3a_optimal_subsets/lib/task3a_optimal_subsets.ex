defmodule Task3aOptimalSubsets do

  # Function that generates the list for array_of_digits randomly
  def random_list_generator do
    for _n <- 1..Enum.random(6..9), do: Enum.random(1..9)
  end

  # Function that generates the 2d matrix for matrix_of_sum randomly
  def random_matrix_generator do
    list_of_na = for _n <- 1..9, do: "na"
    recurse(list_of_na, Enum.random(3..5)) |>
    Enum.chunk_every(3)
  end

  # Helper function for `random_matrix_generator()`
  def recurse(list_of_na, 0), do: list_of_na
  def recurse(list_of_na, num_of_sum) do
    recurse(List.replace_at(list_of_na, Enum.random(0..8), Enum.random(11..20)), num_of_sum-1)
  end

  @doc """
  #Function name:
        valid_sum
  #Inputs:
        matrix_of_sum   : A 2d matrix containing two digit numbers for which subsebts are to be created
  #Output:
        List of all vallid sums from the given 2d matrix
  #Details:
        Finds the valid sum values from the given 2d matrix
  """
  def valid_sum(matrix_of_sum \\ random_matrix_generator()) do
    IO.inspect matrix_of_sum, label:  "matrix_of_sum"
    ### Write your code here ###

  end


  @doc """
  #Function name:
        sum_of_one
  #Inputs:
        array_of_digits : Array containing single digit numbers to satisty sum
        sum_val         : Any 2 digit value for which subsets are to be created
  #Output:
        List of list of all possible subsets
  #Details:
        Finds the all possible subsets from given array of digits for a 2 digit value
  """

  def sum_of_one(array_of_digits \\ random_list_generator(), sum_val \\ Enum.random(11..20)) do
    IO.inspect array_of_digits, label:  "array_of_digits"
    IO.inspect sum_val, label:  "sum_val"
    ### Write your code here ###

  end

  @doc """
  #Function name:
        sum_of_all
  #Inputs:
        array_of_digits : Array containing single digit numbers to satisty sum
        matrix_of_sum   : A 2d matrix containing two digit numbers for which subsebts are to be created
  #Output:
        Map of each sum value and it's respective subsets
  #Details:
        Finds the all possible subsets from given array of digits for all valid sums elements of given 2d matrix
  """
  def sum_of_all(array_of_digits \\ random_list_generator(), matrix_of_sum \\ random_matrix_generator()) do
    IO.inspect array_of_digits, label:  "array_of_digits"
    IO.inspect matrix_of_sum, label:  "matrix_of_sum"
    ### Write your code here ###

  end

  @doc """
  #Function name:
        get_optimal_subsets
  #Inputs:
        array_of_digits : Array containing single digit numbers to satisty sum
        matrix_of_sum   : A 2d matrix containing two digit numbers for which subsebts are to be created
  #Output:
        Map containing the sums and corresponding subset as keys & values respectively
  #Details:
        Function that takes matrix_of_sum and array_of_digits as argument and select single subset for each sum optimally to satisfy maximum sums
  #Example call:
      Check Task 3A Document
  """
  def get_optimal_subsets(array_of_digits \\ random_list_generator(), matrix_of_sum \\ random_matrix_generator()) do
    IO.inspect array_of_digits, label:  "array_of_digits"
    IO.inspect matrix_of_sum, label:  "matrix_of_sum"
    ### Write your code here ###

  end

end
