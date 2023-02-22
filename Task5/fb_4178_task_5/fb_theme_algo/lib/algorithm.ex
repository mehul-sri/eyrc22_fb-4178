defmodule Algorithm do
  @moduledoc """
  Documentation for `Main`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Main.hello()
      :world

  """


  def identifyCellNumbersWithLocations(matrix) do
    cols = Enum.count(Enum.at(matrix, 0))
    temp = Enum.reduce(matrix, [[], 0], fn row, [acc, i] ->
           temp = Enum.reduce(row, [acc, 0], fn cell, [acc2, j] ->
                  if (cell != "na") do
                         [acc2 ++ [{cell, cols*i+j+1}], j+1]
                  else
                         [acc2, j+1]
                  end
           end)
           [Enum.at(temp, 0), i+1]
    end)
    Enum.at(temp, 0)
    |> Map.new(fn {v, k} -> {k, v} end)
  end


  def algo_run(cell_map, matrix_of_sum, rcm_set) do
       """
        INPUT :
        cell_map : contains all paths as well as the start and goal locations
       """
    matrix_and_position = identifyCellNumbersWithLocations(matrix_of_sum)
    optimal_rcm_distribution = Task3aOptimalSubsets.get_optimal_subsets(rcm_set,matrix_of_sum)
    optimal_path = Task2PathTraversal.grid_traversal(cell_map,matrix_of_sum)
    [optimal_rcm_distribution,optimal_path,matrix_and_position]
  end


end
