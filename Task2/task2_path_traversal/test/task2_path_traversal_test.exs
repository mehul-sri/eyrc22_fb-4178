defmodule Task2PathTraversalTest do
  use ExUnit.Case
  @expected_cell_traversal_lists %{
  {1, 1} => [1],
  {1, 2} => [1, 4, 7, 8, 5, 2],
  {1, 3} => [1, 4, 7, 8, 5, 2, 3],
  {1, 4} => [1, 4],
  {1, 5} => [1, 4, 7, 8, 5],
  {1, 6} => [1, 4, 7, 8, 5, 6],
  {1, 7} => [1, 4, 7],
  {1, 8} => [1, 4, 7, 8],
  {1, 9} => [1, 4, 7, 8, 5, 6, 9],
  {2, 1} => [2, 5, 8, 7, 4, 1],
  {2, 2} => [2],
  {2, 3} => [2, 3],
  {2, 4} => [2, 5, 8, 7, 4],
  {2, 5} => [2, 5],
  {2, 6} => [2, 5, 6],
  {2, 7} => [2, 5, 8, 7],
  {2, 8} => [2, 5, 8],
  {2, 9} => [2, 5, 6, 9],
  {3, 1} => [3, 2, 5, 8, 7, 4, 1],
  {3, 2} => [3, 2],
  {3, 3} => [3],
  {3, 4} => [3, 2, 5, 8, 7, 4],
  {3, 5} => [3, 2, 5],
  {3, 6} => [3, 2, 5, 6],
  {3, 7} => [3, 2, 5, 8, 7],
  {3, 8} => [3, 2, 5, 8],
  {3, 9} => [3, 2, 5, 6, 9],
  {4, 1} => [4, 1],
  {4, 2} => [4, 7, 8, 5, 2],
  {4, 3} => [4, 7, 8, 5, 2, 3],
  {4, 4} => [4],
  {4, 5} => [4, 7, 8, 5],
  {4, 6} => [4, 7, 8, 5, 6],
  {4, 7} => [4, 7],
  {4, 8} => [4, 7, 8],
  {4, 9} => [4, 7, 8, 5, 6, 9],
  {5, 1} => [5, 8, 7, 4, 1],
  {5, 2} => [5, 2],
  {5, 3} => [5, 2, 3],
  {5, 4} => [5, 8, 7, 4],
  {5, 5} => [5],
  {5, 6} => [5, 6],
  {5, 7} => [5, 8, 7],
  {5, 8} => [5, 8],
  {5, 9} => [5, 6, 9],
  {6, 1} => [6, 5, 8, 7, 4, 1],
  {6, 2} => [6, 5, 2],
  {6, 3} => [6, 5, 2, 3],
  {6, 4} => [6, 5, 8, 7, 4],
  {6, 5} => [6, 5],
  {6, 6} => [6],
  {6, 7} => [6, 5, 8, 7],
  {6, 8} => [6, 5, 8],
  {6, 9} => [6, 5, 9],
  {7, 1} => [7, 4, 1],
  {7, 2} => [7, 8, 5, 2],
  {7, 3} => [7, 8, 5, 2, 3],
  {7, 4} => [7, 4],
  {7, 5} => [7, 8, 5],
  {7, 6} => [7, 8, 5, 6],
  {7, 7} => [7],
  {7, 8} => [7, 8],
  {7, 9} => [7, 8, 5, 6, 9],
  {8, 1} => [8, 5, 7, 4, 1],
  {8, 2} => [8, 5, 2],
  {8, 3} => [8, 5, 2, 3],
  {8, 4} => [8, 5, 7, 4],
  {8, 5} => [8, 5],
  {8, 6} => [8, 5, 6],
  {8, 7} => [8, 5, 7],
  {8, 8} => [8],
  {8, 9} => [8, 5, 6, 9],
  {9, 1} => [9, 6, 5, 8, 7, 4, 1],
  {9, 2} => [9, 6, 5, 2],
  {9, 3} => [9, 6, 5, 2, 3],
  {9, 4} => [9, 6, 5, 8, 7, 4],
  {9, 5} => [9, 6, 5],
  {9, 6} => [9, 6],
  {9, 7} => [9, 6, 5, 8, 7],
  {9, 8} => [9, 6, 5, 8],
  {9, 9} => [9]}

  @cell_map %{ 1 => [4],
  2 => [3, 5],
  3 => [2],
  4 => [1, 7],
  5 => [2, 6, 8],
  6 => [5, 9],
  7 => [4, 8],
  8 => [5, 7],
  9 => [6]
  }

  @matrix_of_sum [
  ["na","na", 15],
  ["na", "na", 12],
  ["na", 10, "na"]
  ]

  test "check locations of valid sum for the given matrix" do
    matrix_of_sum = [
      [21 ,"na", "na"],
      ["na", "na", 12],
      ["na", "na", "na"]
    ]
    expected_list_of_locations = [1, 6]
    assert Task2PathTraversal.get_locations(matrix_of_sum) == expected_list_of_locations
  end

  test "check to the return format of get_locatons function" do
    return_value = Task2PathTraversal.get_locations(@matrix_of_sum)
    assert is_list(return_value), "Expected return format of get_locations function is list"
  end

  test "check for locations of valid sum for the given matrix" do
    return_value = Task2PathTraversal.get_locations(@matrix_of_sum)
    expected_list_of_locations = [3, 6, 8]
    assert return_value == expected_list_of_locations
  end

  test "check for cell traversal function" do
    Enum.each(Enum.to_list(1..9), fn i -> Enum.each(Enum.to_list(1..9),
    fn j ->
            return_value = Task2PathTraversal.cell_traversal(@cell_map,i,j)
            assert return_value == @expected_cell_traversal_lists[{i, j}], "Test failed for start node as #{i} and Goal node as #{j}"
          end  )
        end )
  end

  test "check for grid_traversal function" do
    return_value = Task2PathTraversal.grid_traversal(@cell_map, @matrix_of_sum) |> Enum.map(fn [{key, value}] -> [{Enum.at(value,0),key |> Atom.to_string |> String.to_integer}, value] end)
    Enum.each(return_value, fn [{start, goal},path] ->
      assert path == @expected_cell_traversal_lists[{start,goal}], "Path is incorrect for start = #{start} and goal = #{goal}"
    end)
    visited_locations = Task2PathTraversal.grid_traversal(@cell_map, @matrix_of_sum) |> Enum.map(fn [{key, _value}] -> key |> Atom.to_string |> String.to_integer end) |> Enum.sort
    expected_locations = [3, 6, 8]
    assert expected_locations == visited_locations, "locations visited are incorrect"
  end
end
