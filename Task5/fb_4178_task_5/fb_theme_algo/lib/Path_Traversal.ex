defmodule Task2PathTraversal do
@moduledoc """
  A module that implements functions for
  path planning algorithm and travels the path
  """

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

  @doc """
  #Function name:
          get_locations
  #Inputs:
          A 2d matrix namely matrix_of_sum containing two digit numbers
  #Output:
          List of locations of the valid_sum which should be in ascending order
  #Details:
          To find the cell locations containing valid_sum in the matrix
  #Example call:
          Check Task 2 Document
  """
  def add_element(arr,_count,[]), do: arr
  def add_element(arr,count,[head|tail]) do
    arr = if head != "na" do
            arr ++ [count]
          else
            arr
          end
    add_element(arr,count+1,tail)
  end
  def my_get_location([row1|[row2|[row3]]]) do
    add_element([],1,row1)
    |> add_element(4,row2)
    |> add_element(7,row3)
  end

  def get_locations(matrix_of_sum \\ @matrix_of_sum) do
        my_get_location(matrix_of_sum)
  end

  @doc """
  #Function name:
          cell_traversal
  #Inputs:
          cell_map which contains all paths as well as the start and goal locations
  #Output:
          List containing the path from start to goal location
  #Details:
          To find the path from start to goal location
  #Example call:
          Check Task 2 Document
  """
  def iterate_list(_cell_map,[],_start,_level,short_map,level_list) ,do: [level_list,short_map]
  def iterate_list(cell_map,[head|tail],start,level,short_map,level_list) do
        if Enum.at(level_list,head) <= (level+1) do
                iterate_list(cell_map,tail,start,level,short_map,level_list)
        else
                # map term
                temp_list = short_map[start] ++ [head]
                # short_map = Map.delete(short_map,head)
                short_map = Map.merge(short_map,%{head => temp_list})
                [level_list,short_map] = my_cell_traversal(cell_map,head,level_list,level+1,short_map)
                iterate_list(cell_map,tail,start,level,short_map,level_list)
        end
  end

  def my_cell_traversal(cell_map,start,level_list,level,short_map) do
      l = cell_map[start]
      level_list = List.replace_at(level_list,start,level)
      iterate_list(cell_map,l,start,level,short_map,level_list)
  end

  def cell_traversal(cell_map \\ @cell_map, start, goal) do
        level_list = [10,10,10,10,10,10,10,10,10,10,10]
        short_map = %{1 => [], 2=> [], 3=> [], 4=> [], 5=> [], 6=> [], 7 => [], 8=> [],9 => []}
        # short_map = Map.delete(short_map,start)
        short_map = Map.merge(short_map,%{start => [start]})

        [_level_list, short_map] = my_cell_traversal(cell_map,start,level_list,0,short_map)
        short_map[goal]
  end

  @doc """
  #Function name:
          traverse
  #Inputs:
          a list (this will be generated in grid_traversal function) and the cell_map
  #Output:
          List of lists containing paths starting from the 1st cell and visiting every cell containing valid_sum
  #Details:
          To find shortest path from first cell to all valid_sum’s locations
  #Example call:
          Check Task 2 Document
  """
  def get_minimum(_map,[],_min_count,min_element), do: min_element
  def get_minimum(map,[head|tail],min_count,min_element) do
        l = map[head]
        count = Enum.count(l)
        [min_count,min_element] = if count <min_count do
          [count,head]
        else
                [min_count,min_element]
        end

        get_minimum(map,tail,min_count,min_element)
  end
  def get_traversal_path(_cell_map,_start,[],list) , do: list
  def get_traversal_path(cell_map,start,points,list) do
        level_list = [10,10,10,10,10,10,10,10,10,10,10]
        short_map = %{1 => [], 2=> [], 3=> [], 4=> [], 5=> [], 6=> [], 7 => [], 8=> [],9 => []}
        # short_map = Map.delete(short_map,start)
        short_map = Map.merge(short_map,%{start => [start]})

        [_level_list, short_map] = my_cell_traversal(cell_map,start,level_list,0,short_map)

        min = get_minimum(short_map,points,10,10)

        #delete min from points
        points = List.delete(points,min)
        get_traversal_path(cell_map,min,points,list ++ [short_map[min]])
  end

  def traverse(list, cell_map \\ @cell_map) do
        #delete 1 from the list
        list = List.delete(list,1)
        get_traversal_path(cell_map,1,list,[])
  end

  @doc """
  #Function name:
          grid_traversal
  #Inputs:
          cell_map and matrix_of_sum
  #Output:
          List of keyword lists containing valid_sum locations along with paths obtained from traverse function
  #Details:
          Driver function which calls the get_locations and traverse function and returns the output in required format
  #Example call:
          Check Task 2 Document
  """
  def grid_traversal(cell_map \\ @cell_map,matrix_of_sum \\ @matrix_of_sum) do
    [1] ++ get_locations(matrix_of_sum)
    |> traverse(cell_map)
    |> Enum.map(fn path_list ->
        { Enum.at(path_list, -1), path_list}
        end)
  end

end
