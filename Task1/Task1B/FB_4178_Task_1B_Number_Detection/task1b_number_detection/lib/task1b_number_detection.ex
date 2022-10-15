defmodule Task1bNumberDetection do
@moduledoc """
  A module that implements functions for detecting numbers present in a grid in provided image
  """
  alias Evision, as: OpenCV


  @doc """
  #Function name:
         identifyCellNumbers
  #Inputs:
         image  : Image path with name for which numbers are to be detected
  #Output:
         Matrix containing the numbers detected
  #Details:
         Function that takes single image as an argument and provides the matrix of detected numbers
  #Example call:

      iex(1)> Task1bNumberDetection.identifyCellNumbers("images/grid_1.png")
      [["22", "na", "na"], ["na", "na", "16"], ["na", "25", "na"]]
  """


  def identifyCellNumbers(image) do
       img = OpenCV.imread!(image)
       img_gray = OpenCV.cvtColor!(img, OpenCV.cv_COLOR_BGR2GRAY)
       {_, thresh} = OpenCV.threshold!(img_gray, 127, 255, OpenCV.cv_THRESH_BINARY)

       grid = getGrid(thresh)
       {contours, hierarchy} = OpenCV.findContours!(grid, OpenCV.cv_RETR_TREE, OpenCV.cv_CHAIN_APPROX_SIMPLE)
       hierarchyNx = OpenCV.Nx.to_nx!(hierarchy)[0]
       cells = getCellIndices(hierarchyNx, 0)
       # IO.inspect(cells)
       # Enum.each(cells, fn cell ->
       #        img_cell = OpenCV.drawContours!(grid, contours, cell, [5], thickness: 5)
       #        OpenCV.HighGui.imshow!("Cell", img_cell)
       #        OpenCV.HighGui.waitkey!(0)
       # end)
       cellMatrix = getCellIndicesMatrix(contours, cells)
       # IO.inspect(cellMatrix)
       getNumberMatrix(grid, contours, hierarchyNx, cellMatrix)
  end

  defp crop(img_gray, x, y, w, h) do
       mat = OpenCV.Nx.to_nx!(img_gray)
       tensor = Nx.slice(mat, [y, x], [h, w])
       OpenCV.Nx.to_mat!(tensor)
  end

  defp cropContourRect(img_gray, contour) do
    {x, y, w, h} = OpenCV.boundingRect!(contour)
    crop(img_gray, x, y, w, h)
  end

  defp getGrid(img_gray) do
       img_canny = OpenCV.canny!(img_gray, 127, 255)

       # Find largest contour by area in canny image (Assumed to be the grid)
       {contours, _} = OpenCV.findContours!(img_canny, OpenCV.cv_RETR_TREE, OpenCV.cv_CHAIN_APPROX_SIMPLE)

       [grid_contour_i, _, _] = Enum.reduce(contours, [0, 0, 0], fn contour, acc ->
              a = OpenCV.contourArea!(contour)
              if a > Enum.at(acc, 1) do
                     [Enum.at(acc, 2), a, Enum.at(acc, 2)+1]
              else
                     [Enum.at(acc, 0), Enum.at(acc, 1), Enum.at(acc, 2)+1]
              end
       end)

       grid_contour = Enum.at(contours, grid_contour_i)

       {x, y, w, h} = OpenCV.boundingRect!(grid_contour)
       crop(img_gray, round(x+0.01*w), round(y+0.01*h), round(w*0.98), round(h*0.98))
  end

  defp getCellIndices(hierarchy, index) do
       next = Nx.to_number(hierarchy[index][0])
       if index != -1 do
              [index] ++ getCellIndices(hierarchy, next)
       else
              []
       end
  end

  defp getCellIndicesMatrix(contours, cellIndices) do
       # get the rows
       rows = Enum.reduce(cellIndices, [], fn cellIndex, acc ->
              cell = Enum.at(contours, cellIndex)
              {x, y, w, h} = OpenCV.boundingRect!(cell)
              cy = y + div(h, 2)
              cx = x + div(w, 2)
              rows2 = Enum.reduce(acc, [false], fn row, acc2 ->
                     if (0.9*cy < Enum.at(row, 0) and 1.1*cy > Enum.at(row, 0)) do
                            [true] ++ Enum.slice(acc2, Range.new(1, Enum.count(acc2)-1)) ++ [[Enum.at(row, 0), [[cx, cellIndex]]++Enum.at(row, 1)]]
                     else
                            acc2 ++ [row]
                     end
              end)
              if (Enum.at(rows2, 0))do
                     Enum.slice(rows2, Range.new(1, Enum.count(rows2)-1))
              else
                     Enum.slice(rows2, Range.new(1, Enum.count(rows2)-1)) ++ [[cy, [[cx, cellIndex]]]]
              end
       end)

       # Sort the rows
       rows = Enum.sort(rows, fn row1, row2 ->
              Enum.at(row1, 0) < Enum.at(row2, 0)
       end)

       # IO.inspect(["rows", rows])

       rows = Enum.map(rows, fn row -> Enum.at(row, 1) end)

       # Sort the cells in each row
       rows = Enum.reduce(rows, [], fn row, acc ->
              row = Enum.map(Enum.sort(row, fn c1, c2 -> Enum.at(c1, 0) < Enum.at(c2, 0) end), fn cell -> Enum.at(cell, 1) end)
              acc ++ [row]
       end)
       # IO.inspect(["rows2", rows])
       rows
  end

  defp identifyDigit(digitGrayImage, digits) do

       matches = Enum.map(0..9, fn index ->
              digit = Enum.at(digits, index)
              dgiShape = Nx.shape(OpenCV.Nx.to_nx!(digitGrayImage))
              dShape = Nx.shape(OpenCV.Nx.to_nx!(digit))
              digitGrayImage = if (dgiShape != dShape) do
                     {h, w} = dShape
                     OpenCV.resize!(digitGrayImage, [w, h])
              else
                     digitGrayImage
              end
              xored = OpenCV.bitwise_xor!(digitGrayImage, digit)
              xoredNx = OpenCV.Nx.to_nx!(xored)
              val = Nx.to_number(Nx.sum(xoredNx))/Nx.to_number(Nx.size(xoredNx))
              [val, index]
       end)
       Enum.at(Enum.min(matches), 1)
  end

  defp getSiblings(hierarchy, cell) do
       if cell == -1 do
              []
       else
              [cell] ++ getSiblings(hierarchy, Nx.to_number(hierarchy[cell][0]))
       end
  end

  defp identifyNumber(img_gray, contours, hierarchy, cell, digits) do
       nums = getSiblings(hierarchy, Nx.to_number(hierarchy[cell][2]))
       # IO.inspect(["nums", nums])
       if Enum.empty?(nums) do
              "na"
       else
              nums = Enum.map(nums, fn num ->
                     {x, _, w, _} = OpenCV.boundingRect!(Enum.at(contours, num))
                     cx = x + div(w, 2)
                     [cx, num]
              end)
              nums = Enum.sort(nums, fn num1, num2 ->
                     Enum.at(num1, 0) < Enum.at(num2, 0)
              end)
              # IO.inspect(["nums0", nums])
              nums = Enum.map(nums, fn num ->
                     Enum.at(num, 1)
              end)
              # IO.inspect(["nums", nums])
              digs = Enum.map(nums, fn num ->
                     cropped_num = cropContourRect(img_gray, Enum.at(contours, num))
                     identifyDigit(cropped_num, digits)
              end)
              # IO.inspect(["digs", digs])
              Integer.to_string(Enum.at(Enum.reduce(digs, [0, 0], fn dig, acc->
                     [dig + 10**Enum.at(acc, 1)*Enum.at(acc, 0), Enum.at(acc, 1)+1]
              end), 0))
       end
  end

  defp getNumberMatrix(img_gray, contours, hierarchyNx, cellMatrix) do
       digits = Enum.map(0..9, fn i ->
          OpenCV.imread!("digits/" <> Integer.to_string(i) <> ".png", flags: OpenCV.cv_IMREAD_GRAYSCALE)
       end)
       # IO.inspect(digits)
       Enum.map(cellMatrix, fn row ->
              Enum.map(row, fn cell ->
                     # IO.inspect(cell)
                     identifyNumber(img_gray, contours, hierarchyNx, cell, digits)
              end)
       end)
  end



  @doc """
  #Function name:
         identifyCellNumbersWithLocations
  #Inputs:
         matrix  : matrix containing the detected numbers
  #Output:
         List containing tuple of detected number and it's location in the grid
  #Details:
         Function that takes matrix generated as an argument and provides list of tuple
  #Example call:

        iex(1)> matrix = Task1bNumberDetection.identifyCellNumbers("images/grid_1.png")
        [["22", "na", "na"], ["na", "na", "16"], ["na", "25", "na"]]
        iex(2)> Task1bNumberDetection.identifyCellNumbersWithLocations(matrix)
        [{"22", 1}, {"16", 6}, {"25", 8}]
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
  end


  @doc """
  #Function name:
         driver
  #Inputs:
         path  : The path where all the provided images are present
  #Output:
         A final output with image name as well as the detected number and it's location in gird
  #Details:
         Driver functional which detects numbers from mutiple images provided
  #Note:
         DO NOT EDIT THIS FUNCTION
  #Example call:

      iex(1)> Task1bNumberDetection.driver("images/")
      [
        {"grid_1.png", [{"22", 1}, {"16", 6}, {"25", 8}]},
        {"grid_2.png", [{"13", 3}, {"27", 5}, {"20", 7}]},
        {"grid_3.png", [{"17", 3}, {"20", 4}, {"11", 5}, {"15", 9}]},
        {"grid_4.png", []},
        {"grid_5.png", [{"13", 1}, {"19", 2}, {"17", 3}, {"20", 4}, {"16", 5}, {"11", 6}, {"24", 7}, {"15", 8}, {"28", 9}]},
        {"grid_6.png", [{"20", 2}, {"17", 6}, {"23", 9}, {"15", 13}, {"10", 19}, {"19", 22}]},
        {"grid_7.png", [{"19", 2}, {"21", 4}, {"10", 5}, {"23", 11}, {"15", 13}]}
      ]
  """
  def driver(path \\ "images/") do

       # Getting the path of images
       image_path = path <> "*.png"
       # Creating a list of all images paths with extension .png
       image_list = Path.wildcard(image_path)
       # Parsing through all the images to get final output using the two funtions which teams need to complete
       Enum.map(image_list, fn(x) ->
              {String.trim_leading(x,path), identifyCellNumbers(x) |> identifyCellNumbersWithLocations}
       end)
  end

end
