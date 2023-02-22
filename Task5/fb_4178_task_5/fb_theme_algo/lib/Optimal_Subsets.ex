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
      def valid_sum(matrix_of_sum \\ random_matrix_generator())
      def valid_sum([first | rest]) when is_integer(first), do: [first | rest]
      def valid_sum(matrix_of_sum) do
    #     IO.inspect matrix_of_sum, label:  "matrix_of_sum"
        ### Write your code here ###
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
      """

      def sum_of_one(array_of_digits \\ random_list_generator(), sum_val \\ Enum.random(11..20)) do
    #     IO.inspect array_of_digits, label:  "array_of_digits"
    #     IO.inspect sum_val, label:  "sum_val"
        ### Write your code here ###
        array_dig(0, array_of_digits, sum_val, [], [])
      end

      defp array_dig(_sumi, _array, 0, _final_array, _sum_array), do: []
      defp array_dig(_sumi, [], _sumn, final_array, _sum_array), do: final_array
      defp array_dig(sumi, array, sumn, final_array, sum_array) do
          Enum.reduce(Enum.with_index(array), final_array, fn {i, ind}, acc ->
                cond do
                      sumi + i == sumn ->  [Enum.sort([i] ++ sum_array, :desc)] ++ acc
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
      """
      def sum_of_all(array_of_digits \\ random_list_generator(), matrix_of_sum \\ random_matrix_generator()) do
          # IO.inspect array_of_digits, label:  "array_of_digits"
          # IO.inspect matrix_of_sum, label:  "matrix_of_sum"
          ### Write your code here ###
          Enum.uniq(valid_sum(matrix_of_sum))
          |> Enum.reduce(%{}, fn i, acc ->
                Map.merge(acc, %{i => sum_of_one(array_of_digits, i)})
          end)
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
      #     IO.inspect array_of_digits, label:  "array_of_digits"
      #     IO.inspect matrix_of_sum, label:  "matrix_of_sum"
          ### Write your code here ###
          # sum_of_all(array_of_digits, matrix_of_sum)
          # |> create_satisfied_sums(array_of_digits, valid_sum(matrix_of_sum))
          # |> get_max_satisfied()

          pre_get_optimal_subsets(valid_sum(matrix_of_sum), array_of_digits)
          |> Enum.at(0)
      end

      def pre_get_optimal_subsets([], _), do: []
      def pre_get_optimal_subsets(vsum, []) do
          Enum.reduce(vsum, %{}, fn num, acc ->
                if (Map.has_key?(acc, num)) do
                      Map.put(acc, num, Map.get(acc, num) ++ [[]])
                else
                      Map.merge(acc, %{num => [[]]})
                end
          end)
      end
      def pre_get_optimal_subsets(vsum, array_of_digits) do
          # IO.inspect(vsum, label: "vsum")
          # IO.inspect(array_of_digits, label: "array_of_digits")
          # IO.gets("in?\n")
          sum_of_all(array_of_digits, vsum)
          |> create_satisfied_sums(array_of_digits, vsum)
          |> get_max_satisfied()
          |> Enum.map(fn map_of_lists ->
                # IO.inspect(map_of_lists, label: "map_of_lists")
                remaining_vsum = (Enum.reduce(map_of_lists, [], fn {k, lists}, acc ->
                      acc ++ Enum.reduce(lists, [], fn list, acc1 ->
                            cond do
                                  Enum.empty?(list) -> acc1 ++ [k]
                                  true -> acc1
                            end
                      end)
                end) |> Enum.reverse())
            #     IO.inspect(remaining_vsum, label: "remaining_vsum")
                used_digits = Enum.flat_map(map_of_lists, fn {_, lists} ->
                      Enum.flat_map(lists, fn list -> list end)
                end)
                remaining_digits = array_of_digits -- used_digits
                # |> IO.inspect(label: "remaining_digits")
                possible_vsum = Enum.map(remaining_vsum, fn sum ->
                      get_max_sum_possible(sum, remaining_digits)
                end)
                # |> IO.inspect(label: "possible_sum")
                vsum_psum_map = Map.new(Enum.with_index(remaining_vsum), fn {sum, ind} ->
                      {sum, Enum.at(possible_vsum, ind)}
                end)
                if (Enum.all?(possible_vsum, fn x -> x == 0 end)) do
                      map_of_lists
                else
                      # IO.puts("1")
                      partial_subsets = Enum.at(pre_get_optimal_subsets(possible_vsum, remaining_digits), 0)
                      partial_subsets = Map.new(partial_subsets, fn {k, lists} -> {k, Enum.reverse(lists)} end)

                  #     IO.inspect(partial_subsets, label: "partial_subsets")
                      # IO.inspect(map_of_lists, label: "map_of_lists")
                      Enum.reduce(map_of_lists, [%{}, partial_subsets], fn {k, lists}, acc ->
                            empty_count = count(lists, [])
                            empty_lists = for _ <- 0..(empty_count-1) do [] end
                            # IO.puts("2")
                        #     IO.inspect(acc, label: "acc")
                        #     IO.inspect({k, lists}, label: "lists")
                        #     IO.gets("in?\n")
                            if (empty_count == 0) do
                                  [Map.merge(Enum.at(acc, 0), %{k=>lists}), Enum.at(acc, 1)]
                            else
                                  [
                                        Map.merge(
                                              Enum.at(acc, 0),
                                              %{
                                                    k => (lists -- empty_lists) ++
                                                    Enum.slice(Enum.at(acc, 1)[vsum_psum_map[k]],
                                                          0..(empty_count-1))
                                              }
                                        ),
                                        Map.put(
                                              Enum.at(acc, 1), vsum_psum_map[k],
                                              Enum.slice(Enum.at(acc, 1)[vsum_psum_map[k]], empty_count..-1)
                                        )
                                  ]
                            end
                        #     |> IO.inspect(label: "final")
                      end) |> Enum.at(0)
                end
          end)
          |> Enum.reduce([%{}, :infinity], fn map_of_lists, acc ->
                d = total_diff(map_of_lists)
                if (d < Enum.at(acc, 1)) do
                      [map_of_lists, d]
                else
                      acc
                end
          end)
      end

      def total_diff(map_of_lists) do
          Enum.reduce(map_of_lists, 0, fn {k, lists}, acc ->
                acc + Enum.reduce(lists, 0, fn list, acc1 -> acc1 + k - Enum.sum(list) end)
          end)
      end

      def get_max_sum_possible(num, array_of_digits) do
          Enum.at(subsetSumOptimization(array_of_digits, num), 0)
      end

      def addPower2(arr_of_digit,sum,i) do

          #   p = pow(2,i)
            p = round(:math.pow(2,i))
            if (p <= sum) do
                  addPower2([p|arr_of_digit] ,sum, i+1)
            else
                  [i-1,arr_of_digit]
            end
      end

      def partialSumOptimization([],_sum,_i), do: [0, []]

      def partialSumOptimization([head|tail],sum,i) do
            if (i>=0) do
                  possible_subsets = sum_of_one(tail,sum)
                  if (Enum.count(possible_subsets) == 0) do
                        partialSumOptimization(tail,sum-head,i-1)
                  else
                        partialSumOptimization(tail,sum,i-1)
                  end
            else
                  [sum,sum_of_one([head|tail],sum)]
            end
      end

      def subsetSumOptimization(arr_of_digit,sum) do
            [log,arr_of_digit] = addPower2(arr_of_digit,sum,0)
            if (log >= 0) do
                  partialSumOptimization(arr_of_digit,sum,log)
            else
                  [sum,[]]
            end
      end

      def get_max_satisfied(list_of_maps) do
          max_count = Enum.reduce(list_of_maps, 0, fn map_of_lists, acc ->
                Enum.reduce(map_of_lists, 0, fn {_k, lists}, acc2 ->
                      acc2 + (
                            Enum.filter(lists, fn lst -> Enum.count(lst) != 0 end)
                            |> Enum.count()
                      )
                end)
                |> max(acc)
          end)

          Enum.filter(list_of_maps, fn map_of_lists ->
                Enum.reduce(map_of_lists, 0, fn {_k, lists}, acc2 ->
                      acc2 + (
                            Enum.filter(lists, fn lst -> Enum.count(lst) != 0 end)
                            |> Enum.count()
                      )
                end) == max_count
          end)
      end

      def create_satisfied_sums(map_of_lists, array_of_digits, vsum) do
          map_of_lists
          |> make_lists_in_map_unique()
          # |> reduce_all_lists(array_of_digits)
          # |> IO.inspect(limit: :infinity)
          |> Enum.reduce(%{}, fn {k, v}, acc -> Map.merge(acc, %{k => v ++ [[]]}) end)
          |> satisfy_sums(Enum.sort(vsum), array_of_digits)
          |> Enum.uniq()
          |> remove_subsets()
          |> reduce_list_of_maps_to_minimal()
          |> Enum.reverse()
          |> reduce_list_of_maps_to_minimal()
          |> Enum.reverse()
      end

      def reduce_list_of_maps_to_minimal(list_of_maps_of_lists) do
          Enum.reduce(list_of_maps_of_lists, [], fn map_of_lists, acc ->
                if (Enum.any?(acc, fn mp_lst ->
                      Enum.all?(mp_lst, fn {k, list_of_lists}->
                            lst_lst = map_of_lists[k]
                            # [lst_lst, list_of_lists] = [lst_lst -- list_of_lists, list_of_lists -- lst_lst]
                            Enum.all?(Enum.with_index(list_of_lists), fn {lst, ind} ->
                                  diff = lst -- Enum.at(lst_lst, ind)
                                  diff == [] or (Enum.at(lst_lst, ind) -- lst
                                  |> make_all_possible_groups()
                                  |> Enum.filter(fn x-> Enum.count(x) > 1 end)
                                  |> Enum.sort()
                                  |> Enum.any?(fn group -> Enum.member?(diff, Enum.sum(group)) end))
                            end)
                      end)
                end)) do
                      acc
                else
                      acc ++ [map_of_lists]
                end
          end)
      end

      def make_all_possible_groups([]), do: [[]]
      def make_all_possible_groups(list_of_ints) do
          first = Enum.at(list_of_ints, 0)
          rest = Enum.slice(list_of_ints, 1, length(list_of_ints)-1)
          rest_groups = make_all_possible_groups(rest)
          rest_groups ++ Enum.map(rest_groups, fn lst -> [first] ++ lst end)
      end

      def make_lists_in_map_unique(map_of_lists) do
          Enum.reduce(map_of_lists, %{}, fn {k, v}, acc ->
                Map.merge(acc, %{k => Enum.sort(Enum.uniq(v), :desc)})
          end)
      end

      def remove_subsets(list_of_map_of_lists) do
          Enum.reduce(list_of_map_of_lists, [], fn map_of_lists, acc->
                if (Enum.any?(acc, fn mp_lst -> map_is_subset(map_of_lists, mp_lst) end)) do
                      acc
                else
                      acc ++ [map_of_lists]
                end
          end)
      end

      def map_is_subset(map1, map2) do
          Enum.all?(map1, fn {k, v} ->
                lst2 = map2[k]
                Enum.all?(Enum.with_index(v), fn {lst, ind} ->
                      lst -- Enum.at(lst2, ind) == []
                end)
          end)
      end

      def satisfy_sums(_reduced_map, [], _array_of_digits), do: [%{}]
      def satisfy_sums(reduced_map, keys, array_of_digits) do
          key = Enum.at(keys, 0)
          value = reduced_map[key]
          Enum.reduce(value, [], fn lst, acc ->
                new_array_of_digits = array_of_digits -- lst
                if (Enum.count(array_of_digits) == Enum.count(new_array_of_digits) + Enum.count(lst)) do

                      acc ++
                      (satisfy_sums(reduced_map, keys -- [key], new_array_of_digits)
                      |> Enum.map(fn x ->
                            if (Map.has_key?(x, key))do
                                  Map.put(x, key, Enum.sort(x[key] ++ [lst]))
                            else
                                  Map.put(x, key, [lst])
                            end
                      end))
                else
                      acc
                end
          end)
      end

      def reduce_all_lists(map_of_lists, array_of_digits) do
          map_of_lists
          |> Enum.reduce(%{}, fn {k, v}, acc ->
                Map.merge(acc, %{k => reduce_lists_to_minimal(v, array_of_digits)})
          end)
      end

      @doc """
          removes redundant lists from `list_of_lists`
          reduntant means: if we have lists l1 ans l2
          then if all the sums that can be formed using
          elements of l1 can also be formed using elements
          of l2 then l1 is redundant. (i.e. span(l1) is
          subset of span(l2) => l1 is redundant)
      """
      def reduce_lists_to_minimal(list_of_lists, array_of_digits) do
          # if sum of any two ints in a list is present in array_of_digits and
          # count of that sum in the list is less than that in array_of_digits, remove the list
          list_of_lists
          |> Enum.filter(fn list ->
                list
                |> make_pairs_of_two
                |> Enum.all?(fn pair ->
                      count(list, Enum.sum(pair)) >= count(array_of_digits, Enum.sum(pair))
                end)
          end)
          |> filter_redundant()
          # end)
      end

      @doc """
          creates all possible pairs of two from `list`
      """
      def make_pairs_of_two(list) do
          Enum.map(list, fn x ->
                Enum.map(list--[x], fn y ->
                      [x,y]
                end)
          end) |> Enum.reduce([], fn x, acc -> acc ++ x end)
          |> Enum.filter(fn l -> not Enum.empty?(l) end)
      end

      @doc """
          counts the number of times `element` occurs in `list`
      """
      def count(list, element) do
            Enum.reduce(list, 0, fn x, acc -> if x == element, do: acc+1, else: acc end)
      end

      @doc """
          removes a list if another list with same elements is present in `list_of_lists`
      """
      def filter_redundant(list_of_lists) do
          Enum.map(list_of_lists, fn x -> Enum.sort(x) end)
          |> Enum.reduce([], fn x, acc -> if Enum.member?(acc, x), do: acc, else: [x] ++ acc end)
          |> Enum.sort(fn x, y -> length(x) < length(y) end)
      end

    end


# array_of_digits = [1, 2, 3, 2, 1, 5, 5, 3, 9]
# array_of_digits = [1,9, 9, 9, 9,6,7,8,9,5,6]
# array_of_digits = [6, 1, 4, 5, 5, 7]
# matrix_of_sum = [
#       [21 ,"na", "na", "na", 12],
#       ["na", 16, "na", 12, "na"],
#       [23, "na", 11, "na", 21],
#       [17, "na", "na", 25, "na"],
#       ["na", 22, "na", "na", 10]
#       ]
# matrix_of_sum = [["na", "na", 12], ["na", "na", "na"], ["na", 24, 12]]
# Task3aOptimalSubsets.sum_of_all(array_of_digits, matrix_of_sum)
# |> Task3aOptimalSubsets.create_satisfied_sums(array_of_digits, matrix_of_sum)
# |> IO.inspect()

# Task3aOptimalSubsets.get_optimal_subsets(array_of_digits, matrix_of_sum)
# Task3aOptimalSubsets.get_optimal_subsets()
# |> IO.inspect(limit: :infinity)
# |> Enum.count()
# |> IO.inspect()

# Task3aOptimalSubsets.sum_of_all(array_of_digits, matrix_of_sum)
# |> Task3aOptimalSubsets.reduce_all(array_of_digits)
# |> IO.inspect(limit: :infinity)
