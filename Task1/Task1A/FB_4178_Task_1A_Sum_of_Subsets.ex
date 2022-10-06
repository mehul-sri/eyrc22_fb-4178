defmodule Task1aSumOfSubsets do
       @moduledoc """
         A module that implements functions for getting
         sum of subsets from a given 2d matrix and array of digits
         """



         @doc """
         #Function name:
                valid_sum
         #Inputs:
                matrix_of_sum   : A 2d matrix containing two digit numbers for which subsebts are to be created
         #Output:
                List of all vallid sums from the given 2d matrix
         #Details:
                Finds the valid sum values from the given 2d matrix
         #Example call:
           if given 2d matrix is as follows:
             matrix_of_sum = [
                               [21 ,"na", "na", "na", 12],
                               ["na", "na", 12, "na", "na"],
                               ["na", "na", "na", "na", "na"],
                               [17, "na", "na", "na", "na"],
                               ["na", 22, "na", "na", "na"]
                             ]

             iex(1)> matrix_of_sum = [
             ...(1)>       [21 ,"na", "na", "na", 12],
             ...(1)>       ["na", "na", 12, "na", "na"],
             ...(1)>       ["na", "na", "na", "na", "na"],
             ...(1)>       [17, "na", "na", "na", "na"],
             ...(1)>       ["na", 22, "na", "na", "na"]
             ...(1)>     ]
             iex(2)> Task1aSumOfSubsets.valid_sum(matrix_of_sum)
             [21, 12, 12, 17, 22]
         """
         def valid_sum(matrix_of_sum) do
              matrix_of_sum |> Enum.reduce([], fn x, acc -> acc ++ x end) |> Enum.filter(&(is_integer(&1)))
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
         #Example call:
           if given array of digits is as follows:
             array_of_digits = [3, 5, 2, 7, 4, 2, 3]
             and sum_val = 10

             iex(1)> array_of_digits = [3, 5, 2, 7, 4, 2, 3]
             iex(2)> Task1aSumOfSubsets.sum_of_one(array_of_digits, 10)
             [[3, 7],[3, 2, 5],[3, 2, 5],[3, 4, 3],[7, 3],[3, 2, 2, 3],[2, 5, 3],[2, 5, 3]]
         """

         def sum_of_one(array_of_digits, sum_val) do
              array_dig(0, array_of_digits, sum_val, [], [])
         end

         defp array_dig(_sumi, _array, sumn, _final_array, _sum_array) when sumn == 0, do: []
         defp array_dig(_sumi, array, _sumn, final_array, _sum_array) when array == [], do: final_array
         defp array_dig(sumi, array, sumn, final_array, sum_array) do
              Enum.reduce(Enum.with_index(array), final_array, fn {i, ind}, acc ->
                     cond do
                            sumi + i == sumn ->  [[i] ++ sum_array] ++ acc
                            sumi + i > sumn -> acc
                            true -> array_dig(sumi+i, Enum.slice(array, ind+1, length(array)-ind), sumn, final_array, [i] ++ sum_array) ++ acc
                     end
              end
              )
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
         #Example call:
           if given array of digits is as follows:
             array_of_digits = [3, 5, 2, 7, 4, 2, 3]
           and if given 2d matrix is as follows:
             matrix_of_sum = [
                               [21 ,"na", "na", "na", 12],
                               ["na", "na", 12, "na", "na"],
                               ["na", "na", "na", "na", "na"],
                               [17, "na", "na", "na", "na"],
                               ["na", 22, "na", "na", "na"]
                             ]

             iex(1)> array_of_digits = [3, 5, 2, 7, 4, 2, 3]
             iex(2)> matrix_of_sum = [
             ...(2)>                   [21 ,"na", "na", "na", 12],
             ...(2)>                   ["na", "na", 12, "na", "na"],
             ...(2)>                   ["na", "na", "na", "na", "na"],
             ...(2)>                   [17, "na", "na", "na", "na"],
             ...(2)>                   ["na", 22, "na", "na", "na"]
             ...(2)>                 ]
             iex(3)> Task1aSumOfSubsets.sum_of_all(array_of_digits, matrix_of_sum)
             %{
               12 => [[3, 2, 7],[3, 7, 2],[3, 4, 5],[7, 5],[3, 2, 2, 5],[3, 2, 4, 3],[2, 7, 3],[3, 4, 2, 3],[7, 2, 3],[4, 5, 3],[2, 2, 5, 3]],
               17 => [[3, 2, 7, 5],[3, 7, 2, 5],[3, 4, 7, 3],[3, 2, 7, 2, 3],[3, 2, 4, 5, 3],[2, 7, 5, 3],[3, 4, 2, 5, 3],[7, 2, 5, 3]],
               21 => [[3, 2, 4, 7, 5],[3, 4, 7, 2, 5],[3, 2, 4, 7, 2, 3],[2, 4, 7, 5, 3],[4, 7, 2, 5, 3]],
               22 => [[3, 4, 7, 5, 3], [3, 2, 7, 2, 5, 3]]
             }
         """
         def sum_of_all(array_of_digits,matrix_of_sum) do
              Enum.reduce(Enum.uniq(valid_sum(matrix_of_sum)), %{}, fn i, acc -> Map.merge(acc, %{i => sum_of_one(array_of_digits, i)}) end)
         end
end
