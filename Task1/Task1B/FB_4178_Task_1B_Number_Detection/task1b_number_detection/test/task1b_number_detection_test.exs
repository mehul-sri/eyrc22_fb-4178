defmodule Task1bNumberDetectionTest do
  use ExUnit.Case
  doctest Task1bNumberDetection

  test "TC$:check matrix for image with grid of 3x3 size" do
    image = "images/grid_1.png"
    expected_matrix = [["22", "na", "na"], ["na", "na", "16"], ["na", "25", "na"]]
    assert Task1bNumberDetection.identifyCellNumbers(image) == expected_matrix
  end

  test "TC$:check matrix for image with grid of 4x4 size" do
    image = "images/grid_7.png"
    expected_matrix = [
      ["na", "19", "na", "21"],
      ["10", "na", "na", "na"],
      ["na", "na", "23", "na"],
      ["15", "na", "na", "na"]
    ]
    assert Task1bNumberDetection.identifyCellNumbers(image) == expected_matrix
  end

  test "TC$:check matrix for image with an empty grid" do
    image = "images/grid_4.png"
    expected_matrix = [["na", "na", "na"], ["na", "na", "na"], ["na", "na", "na"]]
    assert Task1bNumberDetection.identifyCellNumbers(image) == expected_matrix
  end


  test "TC$:check list of tuple for a matrix of size 3x3" do
    matrix = [["22", "na", "na"], ["na", "na", "16"], ["na", "25", "na"]]
    expected_list = [{"22", 1}, {"16", 6}, {"25", 8}]
    assert Task1bNumberDetection.identifyCellNumbersWithLocations(matrix) == expected_list
  end

  test "TC$:check list of tuple for a matrix of size 4x4" do
    matrix = [
      ["na", "19", "na", "21"],
      ["10", "na", "na", "na"],
      ["na", "na", "23", "na"],
      ["15", "na", "na", "na"]
    ]
    expected_list = [{"19", 2}, {"21", 4}, {"10", 5}, {"23", 11}, {"15", 13}]
    assert Task1bNumberDetection.identifyCellNumbersWithLocations(matrix) == expected_list
  end

  test "TC$:check list of tuple for a null matrix" do
    matrix = [["na", "na", "na"], ["na", "na", "na"], ["na", "na", "na"]]
    expected_list = []
    assert Task1bNumberDetection.identifyCellNumbersWithLocations(matrix) == expected_list
  end


  test "TC$:check final output for the set of given images" do
    expected_final_list = [
      {"grid_1.png", [{"22", 1}, {"16", 6}, {"25", 8}]},
      {"grid_2.png", [{"13", 3}, {"27", 5}, {"20", 7}]},
      {"grid_3.png", [{"17", 3}, {"20", 4}, {"11", 5}, {"15", 9}]},
      {"grid_4.png", []},
      {"grid_5.png", [{"13", 1}, {"19", 2}, {"17", 3}, {"20", 4}, {"16", 5}, {"11", 6}, {"24", 7}, {"15", 8}, {"28", 9}]},
      {"grid_6.png", [{"20", 2}, {"17", 6}, {"23", 9}, {"15", 13}, {"10", 19}, {"19", 22}]},
      {"grid_7.png", [{"19", 2}, {"21", 4}, {"10", 5}, {"23", 11}, {"15", 13}]}
    ]
    assert Task1bNumberDetection.driver("images/") == expected_final_list
  end

end
